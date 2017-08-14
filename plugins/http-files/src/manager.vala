using Dino.Entities;
using Xmpp;
using Gee;

namespace Dino.Plugins.HttpFiles {

public class Manager : StreamInteractionModule, Object {
    public static ModuleIdentity<Manager> IDENTITY = new ModuleIdentity<Manager>("http_files");
    public string id { get { return IDENTITY.id; } }

    public signal void upload_available(Account account);

    private StreamInteractor stream_interactor;
    private HashMap<Account, int?> max_file_sizes = new HashMap<Account, int?>(Account.hash_func, Account.equals_func);

    private Manager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    public void send(Conversation conversation, string file_uri) {
        Xmpp.Core.XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream != null) {
            stream_interactor.module_manager.get_module(conversation.account, UploadStreamModule.IDENTITY).upload(stream, file_uri,
                (stream, url_down) => {
                    stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(url_down, conversation);
                },
                () => {}
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
