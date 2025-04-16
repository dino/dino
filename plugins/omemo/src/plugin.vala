using Gee;
using Dino.Entities;
using Omemo;

extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino.Plugins.Omemo {

public class Plugin : RootInterface, Object {
    public const bool DEBUG = false;
    private static Context? _context;
    public static Context get_context() {
        assert(_context != null);
        return (!)_context;
    }
    public static bool ensure_context() {
        lock(_context) {
            try {
                if (_context == null) {
                    _context = new Context(DEBUG);
                }
                return true;
            } catch (Error e) {
                warning("Error initializing libomemo-c Context %s", e.message);
                return false;
            }
        }
    }

    public Dino.Application app;
    public Database db;
    public EncryptionListEntry list_entry;
    public ContactDetailsProvider contact_details_provider;
    public DeviceNotificationPopulator device_notification_populator;
    public OwnNotifications own_notifications;
    public TrustManager trust_manager;
    public HashMap<Account, OmemoDecryptor> decryptors = new HashMap<Account, OmemoDecryptor>(Account.hash_func, Account.equals_func);
    public HashMap<Account, OmemoEncryptor> encryptors = new HashMap<Account, OmemoEncryptor>(Account.hash_func, Account.equals_func);

    public void registered(Dino.Application app) {
        ensure_context();
        this.app = app;
        this.db = new Database(Path.build_filename(Application.get_storage_dir(), "omemo.db"));
        this.list_entry = new EncryptionListEntry(this);
        this.contact_details_provider = new ContactDetailsProvider(this);
        this.device_notification_populator = new DeviceNotificationPopulator(this, this.app.stream_interactor);
        this.trust_manager = new TrustManager(this.app.stream_interactor, this.db);

        this.app.plugin_registry.register_encryption_list_entry(list_entry);
        this.app.plugin_registry.register_encryption_preferences_entry(new OmemoPreferencesEntry(this));
        this.app.plugin_registry.register_contact_details_entry(contact_details_provider);
        this.app.plugin_registry.register_notification_populator(device_notification_populator);
        this.app.plugin_registry.register_conversation_addition_populator(new BadMessagesPopulator(this.app.stream_interactor, this));
        this.app.plugin_registry.register_call_entryption_entry(DtlsSrtpVerificationDraft.NS_URI, new CallEncryptionEntry(db));

        this.app.stream_interactor.module_manager.initialize_account_modules.connect((account, list) => {
            Store store = Plugin.get_context().create_store();
            list.add(new StreamModule(store));
            decryptors[account] = new OmemoDecryptor(account, app.stream_interactor, trust_manager, db, store);
            list.add(decryptors[account]);
            encryptors[account] = new OmemoEncryptor(account, trust_manager, store);
            list.add(encryptors[account]);
            list.add(new JetOmemo.Module());
            list.add(new DtlsSrtpVerificationDraft.StreamModule());
            this.own_notifications = new OwnNotifications(this, this.app.stream_interactor, account);
        });

        app.stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new DecryptMessageListener(decryptors));
        app.stream_interactor.get_module(FileManager.IDENTITY).add_file_decryptor(new OmemoFileDecryptor());
        app.stream_interactor.get_module(FileManager.IDENTITY).add_file_encryptor(new OmemoFileEncryptor());
        JingleFileHelperRegistry.instance.add_encryption_helper(Encryption.OMEMO, new JetOmemo.EncryptionHelper(app.stream_interactor));

        Manager.start(this.app.stream_interactor, db, trust_manager, encryptors);

        string locales_dir;
        if (app.search_path_generator != null) {
            locales_dir = ((!)app.search_path_generator).get_locale_path(GETTEXT_PACKAGE, LOCALE_INSTALL_DIR);
        } else {
            locales_dir = LOCALE_INSTALL_DIR;
        }
        internationalize(GETTEXT_PACKAGE, locales_dir);
    }

    public void shutdown() {
        // Nothing to do
    }

    public bool has_new_devices(Account account, Xmpp.Jid jid) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return false;

        return db.identity_meta.get_new_devices(identity_id, jid.bare_jid.to_string()).count() > 0;
    }
}

}
