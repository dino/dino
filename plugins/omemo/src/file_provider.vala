using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;
using Signal;

namespace Dino.Plugins.Omemo {

public class FileProvider : Dino.FileProvider, Object {
    public string id { get { return "aesgcm"; } }

    private StreamInteractor stream_interactor;
    private Dino.Database dino_db;
    private Regex url_regex;

    public FileProvider(StreamInteractor stream_interactor, Dino.Database dino_db) {
        this.stream_interactor = stream_interactor;
        this.dino_db = dino_db;
        this.url_regex = new Regex("""^aesgcm://(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$""");

        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new ReceivedMessageListener(this));
    }

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return ""; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private FileProvider outer;
        private StreamInteractor stream_interactor;

        public ReceivedMessageListener(FileProvider outer) {
            this.outer = outer;
            this.stream_interactor = outer.stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (message.body.has_prefix("aesgcm://") && outer.url_regex.match(message.body)) {
                yield outer.on_file_message(message, conversation);
            }
            return false;
        }
    }

    private async void on_file_message(Entities.Message message, Conversation conversation) {
        MatchInfo match_info;
        this.url_regex.match(message.body, 0, out match_info);
        string url_without_hash = match_info.fetch(1);

        FileTransfer file_transfer = new FileTransfer();
        file_transfer.account = conversation.account;
        file_transfer.counterpart = message.counterpart;
        file_transfer.ourpart = message.ourpart;
        file_transfer.encryption = Encryption.NONE;
        file_transfer.time = message.time;
        file_transfer.local_time = message.local_time;
        file_transfer.direction = message.direction;
        file_transfer.file_name = url_without_hash.substring(url_without_hash.last_index_of("/") + 1);
        file_transfer.mime_type = null;
        file_transfer.size = -1;
        file_transfer.state = FileTransfer.State.NOT_STARTED;
        file_transfer.provider = 0;
        file_transfer.info = message.id.to_string();

        if (stream_interactor.get_module(FileManager.IDENTITY).is_sender_trustworthy(file_transfer, conversation)) {
            yield get_meta_info(file_transfer);
            if (file_transfer.size >= 0 && file_transfer.size < 5000000) {
                ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message.id);
                if (content_item != null) {
                    stream_interactor.get_module(ContentItemStore.IDENTITY).set_item_hide(content_item, true);
                }
            }
            file_incoming(file_transfer, conversation);
        }
    }

    public async void get_meta_info(FileTransfer file_transfer) {
        string url_body = dino_db.message.select({dino_db.message.body}).with(dino_db.message.id, "=", int.parse(file_transfer.info))[dino_db.message.body];
        string url = this.aesgcm_to_https_link(url_body);
        var session = new Soup.Session();
        var head_message = new Soup.Message("HEAD", url);
        if (head_message != null) {
            yield session.send_async(head_message, null);

            if (head_message.status_code >= 200 && head_message.status_code < 300) {
                string? content_type = null, content_length = null;
                head_message.response_headers.foreach((name, val) => {
                    if (name == "Content-Type") content_type = val;
                    if (name == "Content-Length") content_length = val;
                });
                file_transfer.mime_type = content_type;
                file_transfer.size = int.parse(content_length);
            } else {
                warning("HTTP HEAD download status code " + head_message.status_code.to_string());
            }
        }
    }

    public async void download(FileTransfer file_transfer, File file) {
        try {
            string url_body = dino_db.message.select({dino_db.message.body}).with(dino_db.message.id, "=", int.parse(file_transfer.info))[dino_db.message.body];
            string url = this.aesgcm_to_https_link(url_body);
            var session = new Soup.Session();
            Soup.Request request = session.request(url);

            file_transfer.input_stream = decrypt_file(yield request.send_async(null), url_body);
            file_transfer.encryption = Encryption.OMEMO;

            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            os.splice(file_transfer.input_stream, 0);
            os.close();
            file_transfer.path = file.get_basename();
            file_transfer.input_stream = file.read();

            file_transfer.state = FileTransfer.State.COMPLETE;
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

    public InputStream? decrypt_file(InputStream input_stream, string url) {
        // Decode IV and key
        MatchInfo match_info;
        this.url_regex.match(url, 0, out match_info);
        uint8[] iv_and_key = hex_to_bin(match_info.fetch(2).up());
        uint8[] iv, key;
        if (iv_and_key.length == 44) {
            iv = iv_and_key[0:12];
            key = iv_and_key[12:44];
        } else {
            iv = iv_and_key[0:16];
            key = iv_and_key[16:48];
        }

        // Read data
        uint8[] buf = new uint8[256];
        Array<uint8> data = new Array<uint8>(false, true, 0);
        size_t len = -1;
        do {
            len = input_stream.read(buf);
            data.append_vals(buf, (uint) len);
        } while(len > 0);

        // Decrypt
        uint8[] cleartext = Signal.aes_decrypt(Cipher.AES_GCM_NOPADDING, key, iv, data.data);
        return new MemoryInputStream.from_data(cleartext);
    }

    private uint8[] hex_to_bin(string hex) {
        uint8[] bin = new uint8[hex.length / 2];
        const string HEX = "0123456789ABCDEF";
        for (int i = 0; i < hex.length / 2; i++) {
            bin[i] = (uint8) (HEX.index_of_char(hex[i*2]) << 4) | HEX.index_of_char(hex[i*2+1]);
        }
        return bin;
    }

    private string aesgcm_to_https_link(string aesgcm_link) {
        MatchInfo match_info;
        this.url_regex.match(aesgcm_link, 0, out match_info);
        return "https://" + match_info.fetch(1);
    }
}

}
