using Dino.Entities;
using Gee;
using Signal;
using Xmpp;

namespace Dino.Plugins.Omemo {

public class AesGcmFileSender : StreamInteractionModule, FileSender, Object {
    public static ModuleIdentity<Manager> IDENTITY = new ModuleIdentity<Manager>("http_files");
    public string id { get { return IDENTITY.id; } }


    private StreamInteractor stream_interactor;
    private HashMap<Account, long> max_file_sizes = new HashMap<Account, long>(Account.hash_func, Account.equals_func);

    public AesGcmFileSender(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    public void send_file(Conversation conversation, FileTransfer file_transfer) {
        Xmpp.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        uint8[] buf = new uint8[256];
        Array<uint8> data = new Array<uint8>(false, true, 0);
        size_t len = -1;
        do {
            try {
                len = file_transfer.input_stream.read(buf);
            } catch (IOError error) {
                warning(@"HTTP upload: IOError reading stream: $(error.message)");
                file_transfer.state = FileTransfer.State.FAILED;
            }
            data.append_vals(buf, (uint) len);
        } while(len > 0);

        //Create a key and use it to encrypt the file
        uint8[] iv = new uint8[16];
        Plugin.get_context().randomize(iv);
        uint8[] key = new uint8[32];
        Plugin.get_context().randomize(key);
        uint8[] ciphertext = aes_encrypt(Cipher.AES_GCM_NOPADDING, key, iv, data.data);

        // Convert iv and key to hex
        string iv_and_key = "";
        foreach (uint8 byte in iv) iv_and_key += byte.to_string("%02x");
        foreach (uint8 byte in key) iv_and_key += byte.to_string("%02x");

        stream_interactor.module_manager.get_module(file_transfer.account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).request_slot(stream, file_transfer.server_file_name, (int) data.length, file_transfer.mime_type,
            (stream, url_down, url_up) => {
                Soup.Message message = new Soup.Message("PUT", url_up);
                message.set_request(file_transfer.mime_type, Soup.MemoryUse.COPY, ciphertext);
                Soup.Session session = new Soup.Session();
                session.send_async.begin(message, null, (obj, res) => {
                    try {
                        session.send_async.end(res);
                        if (message.status_code >= 200 && message.status_code < 300) {
                            string aesgcm_link = url_down + "#" + iv_and_key;
                            aesgcm_link = "aesgcm://" + aesgcm_link.substring(8); // replace https:// by aesgcm://

                            file_transfer.info = aesgcm_link; // store the message content temporarily so the message gets filtered out
                            Entities.Message xmpp_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(aesgcm_link, conversation);
                            xmpp_message.encryption = Encryption.OMEMO;
                            stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(xmpp_message, conversation);
                            file_transfer.info = xmpp_message.id.to_string();

                            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, xmpp_message.id);
                            if (content_item != null) {
                                stream_interactor.get_module(ContentItemStore.IDENTITY).set_item_hide(content_item, true);
                            }
                        } else {
                            warning("HTTP status code " + message.status_code.to_string());
                            file_transfer.state = FileTransfer.State.FAILED;
                        }
                    } catch (Error e) {
                        warning("HTTP upload error: " + e.message);
                        file_transfer.state = FileTransfer.State.FAILED;
                    }
                });
            },
            (stream, error) => {
                warning("HTTP upload error: " + error);
                file_transfer.state = FileTransfer.State.FAILED;
            }
        );
    }

    public bool can_send(Conversation conversation, FileTransfer file_transfer) {
        return file_transfer.encryption == Encryption.OMEMO;
    }

    public bool is_upload_available(Conversation conversation) {
        lock (max_file_sizes) {
            return max_file_sizes.has_key(conversation.account);
        }
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).feature_available.connect((stream, max_file_size) => {
            lock (max_file_sizes) {
                max_file_sizes[account] = max_file_size;
            }
            upload_available(account);
        });
    }
}

}
