using Dino.Entities;
using Xmpp;
using Gee;

namespace Dino.Plugins.HttpFiles {

public class Manager : StreamInteractionModule, FileSender, Object {
    public static ModuleIdentity<Manager> IDENTITY = new ModuleIdentity<Manager>("http_files");
    public string id { get { return IDENTITY.id; } }

    public signal void uploading(FileTransfer file_transfer);
    public signal void uploaded(FileTransfer file_transfer, string url);

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Account, long> max_file_sizes = new HashMap<Account, long>(Account.hash_func, Account.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        Manager m = new Manager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private Manager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.get_module(FileManager.IDENTITY).add_sender(this);
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.get_module(MessageProcessor.IDENTITY).build_message_stanza.connect(check_add_oob);
    }

    public delegate void OnUploadOk(XmppStream stream, string url_down);
    public delegate void OnError(XmppStream stream, string error);
    public void upload(XmppStream stream, FileTransfer file_transfer, owned OnUploadOk listener, owned OnError error_listener) {
        uint8[] buf = new uint8[256];
        Array<uint8> data = new Array<uint8>(false, true, 0);
        size_t len = -1;
        do {
            try {
                len = file_transfer.input_stream.read(buf);
            } catch (IOError error) {
                error_listener(stream, @"HTTP upload: IOError reading stream: $(error.message)");
            }
            data.append_vals(buf, (uint) len);
        } while(len > 0);

        stream_interactor.module_manager.get_module(file_transfer.account, Xmpp.Xep.HttpFileUpload.Module.IDENTITY).request_slot(stream, file_transfer.server_file_name, (int) data.length, file_transfer.mime_type,
            (stream, url_down, url_up) => {
                Soup.Message message = new Soup.Message("PUT", url_up);
                message.set_request(file_transfer.mime_type, Soup.MemoryUse.COPY, data.data);
                Soup.Session session = new Soup.Session();
                session.send_async.begin(message, null, (obj, res) => {
                    try {
                        session.send_async.end(res);
                        if (message.status_code >= 200 && message.status_code < 300) {
                            listener(stream, url_down);
                        } else {
                            error_listener(stream, "HTTP status code " + message.status_code.to_string());
                        }
                    } catch (Error e) {
                        error_listener(stream, e.message);
                    }
                });
            },
            (stream, error) => error_listener(stream, error));
    }

    public void send_file(Conversation conversation, FileTransfer file_transfer) {
        Xmpp.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        if (stream != null) {
            upload(stream, file_transfer,
                (stream, url_down) => {
                    uploaded(file_transfer, url_down);
                    file_transfer.info = url_down; // store the message content temporarily so the message gets filtered out
                    Entities.Message message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(url_down, conversation);
                    message.encryption = Encryption.NONE;
                    stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(message, conversation);
                    file_transfer.info = message.id.to_string();

                    ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message.id);
                    if (content_item != null) {
                        stream_interactor.get_module(ContentItemStore.IDENTITY).set_item_hide(content_item, true);
                    }
                },
                (stream, error_str) => {
                    warning("Failed getting upload url: %s", error_str);
                    file_transfer.state = FileTransfer.State.FAILED;
                }
            );
        }
    }

    public bool can_send(Conversation conversation, FileTransfer file_transfer) {
        return file_transfer.encryption != Encryption.OMEMO;
    }

    public bool is_upload_available(Conversation conversation) {
        lock (max_file_sizes) {
            return max_file_sizes.has_key(conversation.account);
        }
    }

    public long get_max_file_size(Account account) {
        lock (max_file_sizes) {
            return max_file_sizes[account];
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

    private void check_add_oob(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (message_is_file(db, message) && message.body.has_prefix("http")) {
            Xep.OutOfBandData.add_url_to_message(message_stanza, message_stanza.body);
        }
    }
}

public class FileMessageFilter : ContentFilter, Object {
    public Database db;

    public FileMessageFilter(Dino.Database db) {
        this.db = db;
    }

    public bool discard(ContentItem content_item) {
        if (content_item.type_ == MessageItem.TYPE) {
            MessageItem message_item = content_item as MessageItem;
            return message_is_file(db, message_item.message);
        }
        return false;
    }
}

private bool message_is_file(Database db, Entities.Message message) {
    Qlite.QueryBuilder builder = db.file_transfer.select({db.file_transfer.id}).with(db.file_transfer.info, "=", message.id.to_string());
    Qlite.QueryBuilder builder2 = db.file_transfer.select({db.file_transfer.id}).with(db.file_transfer.info, "=", message.body);
    return builder.count() > 0 || builder2.count() > 0;
}

}
