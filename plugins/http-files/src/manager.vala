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
    private HashMap<Account, long> max_file_sizes = new HashMap<Account, long>(Account.hash_func, Account.equals_func);
    private Manager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(FileManager.IDENTITY).add_sender(this);
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    public void send_file(Conversation conversation, FileTransfer file_transfer) {
        Xmpp.Core.XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        if (stream != null) {
            file_transfer.provider = 0;
            uploading(file_transfer);
            stream_interactor.module_manager.get_module(file_transfer.account, UploadStreamModule.IDENTITY).upload(stream, Path.build_filename(FileManager.get_storage_dir(), file_transfer.path),
                (stream, url_down) => {
                    uploaded(file_transfer, url_down);
                    stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(url_down, conversation);
                },
                () => {
                    file_transfer.state = FileTransfer.State.FAILED;
                }
            );
        }
    }

    public bool can_send(Conversation conversation, FileTransfer file_transfer) {
        return true;
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

    private void on_stream_negotiated(Account account, Core.XmppStream stream) {
        stream_interactor.module_manager.get_module(account, UploadStreamModule.IDENTITY).feature_available.connect((stream, max_file_size) => {
            lock (max_file_sizes) {
                max_file_sizes[account] = max_file_size;
            }
            upload_available(account);
        });
    }

    public static void start(StreamInteractor stream_interactor) {
        Manager m = new Manager(stream_interactor);
        stream_interactor.add_module(m);
    }
}

public class FileMessageFilterDisplay : Plugins.MessageDisplayProvider, Object {
    public string id { get; set; default="file_message_filter"; }
    public double priority { get; set; default=10; }

    public Database db;

    public FileMessageFilterDisplay(Dino.Database db) {
        this.db = db;
    }

    public bool can_display(Entities.Message? message) {
        return message_is_file(message);
    }

    public Plugins.MetaConversationItem? get_item(Entities.Message message, Conversation conversation) {
        return null;
    }

    private bool message_is_file(Entities.Message message) {
        Qlite.QueryBuilder builder = db.file_transfer.select()
                .with(db.file_transfer.info, "=", message.body)
                .with(db.file_transfer.account_id, "=", message.account.id)
                .with(db.file_transfer.counterpart_id, "=", db.get_jid_id(message.counterpart));
        return builder.count() > 0;
    }
}

}
