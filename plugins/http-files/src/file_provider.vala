using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.HttpFiles {

public class FileProvider : Dino.FileProvider, Object {
    public string id { get { return "http"; } }

    private StreamInteractor stream_interactor;
    private Dino.Database dino_db;
    private Regex url_regex;

    public FileProvider(StreamInteractor stream_interactor, Dino.Database dino_db) {
        this.stream_interactor = stream_interactor;
        this.dino_db = dino_db;
        this.url_regex = new Regex("""^(?i)\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))$""");

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
            if (outer.url_regex.match(message.body)) {
                string? oob_url = Xmpp.Xep.OutOfBandData.get_url_from_message(message.stanza);
                if (oob_url != null && oob_url == message.body) {
                    yield outer.on_file_message(message, conversation);
                }
            }
            return false;
        }
    }

    private async void on_file_message(Entities.Message message, Conversation conversation) {
        FileTransfer file_transfer = new FileTransfer();
        file_transfer.account = conversation.account;
        file_transfer.counterpart = message.counterpart;
        file_transfer.ourpart = message.ourpart;
        file_transfer.encryption = Encryption.NONE;
        file_transfer.time = message.time;
        file_transfer.local_time = message.local_time;
        file_transfer.direction = message.direction;
        file_transfer.file_name = message.body.substring(message.body.last_index_of("/") + 1);
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
        var session = new Soup.Session();
        var head_message = new Soup.Message("HEAD", url_body);
        if (head_message != null) {
            yield session.send_async(head_message, null);

            string? content_type = null, content_length = null;
            print(url_body + ":\n");
            head_message.response_headers.foreach((name, val) => {
                print(name + " " + val + "\n");
                if (name == "Content-Type") content_type = val;
                if (name == "Content-Length") content_length = val;
            });
            file_transfer.mime_type = content_type;
            if (content_length != null) {
                file_transfer.size = int.parse(content_length);
            }
        }
    }

    public async void download(FileTransfer file_transfer, File file_) {
        try {
            File file = file_;
            string url_body = dino_db.message.select({dino_db.message.body}).with(dino_db.message.id, "=", int.parse(file_transfer.info))[dino_db.message.body];
            var session = new Soup.Session();
            Soup.Request request = session.request(url_body);

            file_transfer.input_stream = yield request.send_async(null);

            foreach (IncommingFileProcessor processor in stream_interactor.get_module(FileManager.IDENTITY).incomming_processors) {
                if (processor.can_process(file_transfer)) {
                    processor.process(file_transfer);
                }
            }

            if (file_transfer.encryption == Encryption.PGP || file.get_path().has_suffix(".pgp")) {
                file = File.new_for_path(file.get_path().substring(0, file.get_path().length - 4));
            }

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
}

}
