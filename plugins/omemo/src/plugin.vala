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

    public void registered(Dino.Application app) {
        ensure_context();
        this.app = app;
        this.db = new Database(Path.build_filename(Application.get_storage_dir(), "omemo.db"));
        this.list_entry = new EncryptionListEntry(this);
        this.settings_entry = new AccountSettingsEntry(this);
        this.contact_details_provider = new ContactDetailsProvider(this);
        this.app.plugin_registry.register_encryption_list_entry(list_entry);
        this.app.plugin_registry.register_account_settings_entry(settings_entry);
        this.app.plugin_registry.register_contact_details_entry(contact_details_provider);
        this.app.stream_interactor.module_manager.initialize_account_modules.connect((account, list) => {
            list.add(new StreamModule());
        });
        Manager.start(this.app.stream_interactor, db);
        app.stream_interactor.get_module(FileManager.IDENTITY).add_incomming_processor(new InFileProcessor());
        app.stream_interactor.get_module(FileManager.IDENTITY).add_incoming_url_rewriter(new InURLRewriter());

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
}

}
