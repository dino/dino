using Dino.Entities;

extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino.Plugins.Omemo {

public class Plugin : RootInterface, Object {
    public const bool DEBUG = false;
    private static Signal.Context? _context;
    public static Signal.Context get_context() {
        assert(_context != null);
        return (!)_context;
    }
    public static bool ensure_context() {
        lock(_context) {
            try {
                if (_context == null) {
                    _context = new Signal.Context(DEBUG);
                }
                return true;
            } catch (Error e) {
                return false;
            }
        }
    }

    public Dino.Application app;
    public Database db;
    public EncryptionListEntry list_entry;
    public AccountSettingsEntry settings_entry;
    public ContactDetailsProvider contact_details_provider;
    public DeviceNotificationPopulator device_notification_populator;
    public OwnNotifications own_notifications;
    public TrustManager trust_manager;

    public void registered(Dino.Application app) {
        ensure_context();
        this.app = app;
        this.db = new Database(Path.build_filename(Application.get_storage_dir(), "omemo.db"));
        this.list_entry = new EncryptionListEntry(this);
        this.settings_entry = new AccountSettingsEntry(this);
        this.contact_details_provider = new ContactDetailsProvider(this);
        this.device_notification_populator = new DeviceNotificationPopulator(this, this.app.stream_interactor);
        this.trust_manager = new TrustManager(this.app.stream_interactor, this.db);
        this.app.plugin_registry.register_encryption_list_entry(list_entry);
        this.app.plugin_registry.register_account_settings_entry(settings_entry);
        this.app.plugin_registry.register_contact_details_entry(contact_details_provider);
        this.app.plugin_registry.register_notification_populator(device_notification_populator);
        this.app.plugin_registry.register_conversation_addition_populator(new BadMessagesPopulator(this.app.stream_interactor, this));
        this.app.stream_interactor.module_manager.initialize_account_modules.connect((account, list) => {
            list.add(new StreamModule());
            list.add(new JetOmemo.Module(this));
            this.own_notifications = new OwnNotifications(this, this.app.stream_interactor, account);
        });

        app.stream_interactor.get_module(FileManager.IDENTITY).add_file_decryptor(new OmemoFileDecryptor());
        app.stream_interactor.get_module(FileManager.IDENTITY).add_file_encryptor(new OmemoFileEncryptor());
        JingleFileHelperRegistry.instance.add_encryption_helper(Encryption.OMEMO, new JetOmemo.EncryptionHelper(app.stream_interactor));

        Manager.start(this.app.stream_interactor, db, trust_manager);

        SimpleAction own_keys_action = new SimpleAction("own-keys", VariantType.INT32);
        own_keys_action.activate.connect((variant) => {
            foreach(Dino.Entities.Account account in this.app.stream_interactor.get_accounts()) {
                if(account.id == variant.get_int32()) {
                    ContactDetailsDialog dialog = new ContactDetailsDialog(this, account, account.bare_jid);
                    dialog.set_transient_for(((Gtk.Application) this.app).get_active_window());
                    dialog.present();
                }
            }
        });
        this.app.add_action(own_keys_action);

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
