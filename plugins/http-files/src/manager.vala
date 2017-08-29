using Dino.Entities;
using Xmpp;
using Gee;

namespace Dino.Plugins.HttpFiles {

public class Manager : StreamInteractionModule, Object {
    public static ModuleIdentity<Manager> IDENTITY = new ModuleIdentity<Manager>("http_files");
    public string id { get { return IDENTITY.id; } }

    public signal void upload_available(Account account);
    public signal void uploading(FileTransfer file_transfer);
    public signal void uploaded(FileTransfer file_transfer, string url);

    private StreamInteractor stream_interactor;
    private HashMap<Account, int?> max_file_sizes = new HashMap<Account, int?>(Account.hash_func, Account.equals_func);

    private Manager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    public void send(Conversation conversation, string file_uri) {
        Xmpp.Core.XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream != null) {
            File file = File.new_for_path(file_uri);
            FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);

            FileTransfer file_transfer = new FileTransfer();
            file_transfer.account = conversation.account;
            file_transfer.counterpart = conversation.counterpart;
            file_transfer.ourpart = conversation.account.bare_jid;
            file_transfer.direction = FileTransfer.DIRECTION_SENT;
            file_transfer.time = new DateTime.now_utc();
            file_transfer.local_time = new DateTime.now_utc();
            file_transfer.encryption = Encryption.NONE;
            file_transfer.file_name = file_info.get_display_name();
            file_transfer.input_stream = file.read();
            file_transfer.mime_type = file_info.get_content_type();
            file_transfer.size = (int)file_info.get_size();
            uploading(file_transfer);

            stream_interactor.module_manager.get_module(conversation.account, UploadStreamModule.IDENTITY).upload(stream, file_uri,
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

    public bool is_upload_available(Account account) {
        lock (max_file_sizes) {
            return max_file_sizes.has_key(account);
        }
    }

    public int? get_max_file_size(Account account) {
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

}
