using Dino.Entities;

namespace Dino {
extern const string VERSION;

public interface Application : GLib.Application {

    public abstract Database db { get; set; }
    public abstract Dino.Entities.Settings settings { get; set; }
    public abstract StreamInteractor stream_interactor { get; set; }
    public abstract Plugins.Registry plugin_registry { get; set; }
    public abstract SearchPathGenerator? search_path_generator { get; set; }

    internal static string print_xmpp;

    private const OptionEntry[] options = {
        { "print-xmpp", 0, 0, OptionArg.STRING, ref print_xmpp, "Print XMPP stanzas identified by DESC to stderr", "DESC" },
        { null }
    };

    public abstract void handle_uri(string jid, string query, Gee.Map<string, string> options);

    public void init() throws Error {
        if (DirUtils.create_with_parents(get_storage_dir(), 0700) == -1) {
            throw new Error(-1, 0, "Could not create storage dir \"%s\": %s", get_storage_dir(), FileUtils.error_from_errno(errno).to_string());
        }

        this.db = new Database(Path.build_filename(get_storage_dir(), "dino.db"));
        this.settings = new Dino.Entities.Settings.from_db(db);
        this.stream_interactor = new StreamInteractor(db);

        MessageProcessor.start(stream_interactor, db);
        MessageStorage.start(stream_interactor, db);
        PresenceManager.start(stream_interactor);
        CounterpartInteractionManager.start(stream_interactor);
        BlockingManager.start(stream_interactor);
        ConversationManager.start(stream_interactor, db);
        MucManager.start(stream_interactor);
        AvatarManager.start(stream_interactor, db);
        RosterManager.start(stream_interactor, db);
        FileManager.start(stream_interactor, db);
        ContentItemStore.start(stream_interactor, db);
        ChatInteraction.start(stream_interactor);
        NotificationEvents.start(stream_interactor);
        SearchProcessor.start(stream_interactor, db);
        Register.start(stream_interactor, db);
        EntityInfo.start(stream_interactor, db);
        MessageCorrection.start(stream_interactor, db);

        create_actions();

        startup.connect(() => {
            stream_interactor.connection_manager.log_options = print_xmpp;
            Idle.add(() => {
                restore();
                return false;
            });
        });
        shutdown.connect(() => {
            stream_interactor.connection_manager.make_offline_all();
        });
        open.connect((files, hint) => {
            if (files.length != 1) {
                warning("Can't handle more than one URI at once.");
                return;
            }
            File file = files[0];
            if (!file.has_uri_scheme("xmpp")) {
                warning("xmpp:-URI expected");
                return;
            }
            string uri = file.get_uri();
            if (!uri.contains(":")) {
                warning("Invalid URI");
                return;
            }
            string r = uri.split(":", 2)[1];
            string[] m = r.split("?", 2);
            string jid = m[0];
            while (jid[0] == '/') {
                jid = jid.substring(1);
            }
            jid = Uri.unescape_string(jid);
            try {
                jid = new Xmpp.Jid(jid).to_string();
            } catch (Xmpp.InvalidJidError e) {
                warning("Received invalid jid in xmpp:-URI: %s", e.message);
            }
            string query = "message";
            Gee.Map<string, string> options = new Gee.HashMap<string, string>();
            if (m.length == 2) {
                string[] cmds = m[1].split(";");
                query = cmds[0];
                for (int i = 1; i < cmds.length; ++i) {
                    string[] opt = cmds[i].split("=", 2);
                    options[Uri.unescape_string(opt[0])] = opt.length == 2 ? Uri.unescape_string(opt[1]) : "";
                }
            }
            activate();
            handle_uri(jid, query, options);
        });
        add_main_option_entries(options);
    }

    public static string get_storage_dir() {
        return Path.build_filename(Environment.get_user_data_dir(), "dino");
    }

    public static unowned Application get_default() {
        return (Dino.Application) GLib.Application.get_default();
    }

    public void create_actions() {
        SimpleAction accept_subscription_action = new SimpleAction("accept-subscription", VariantType.INT32);
        accept_subscription_action.activate.connect((variant) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(variant.get_int32());
            if (conversation == null) return;
            stream_interactor.get_module(PresenceManager.IDENTITY).approve_subscription(conversation.account, conversation.counterpart);
            stream_interactor.get_module(PresenceManager.IDENTITY).request_subscription(conversation.account, conversation.counterpart);
        });
        add_action(accept_subscription_action);
    }

    protected void add_connection(Account account) {
        if ((get_flags() & ApplicationFlags.IS_SERVICE) == ApplicationFlags.IS_SERVICE) hold();
        stream_interactor.connect_account(account);
    }

    protected void remove_connection(Account account) {
        if ((get_flags() & ApplicationFlags.IS_SERVICE) == ApplicationFlags.IS_SERVICE) release();
        stream_interactor.disconnect_account.begin(account);
    }

    private void restore() {
        foreach (Account account in db.get_accounts()) {
            if (account.enabled) add_connection(account);
        }
    }
}

}
