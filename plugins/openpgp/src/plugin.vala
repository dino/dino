using Gee;

using Dino.Entities;

extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino.Plugins.OpenPgp {

public class Plugin : Plugins.RootInterface, Object {
    public Dino.Application app;
    public Database db;
    public HashMap<Account, Module> modules = new HashMap<Account, Module>(Account.hash_func, Account.equals_func);

    private EncryptionListEntry list_entry;
    private AccountSettingsEntry settings_entry;
    private ContactDetailsProvider contact_details_provider;

    public void registered(Dino.Application app) {
        this.app = app;
        this.db = new Database(Path.build_filename(Application.get_storage_dir(), "pgp.db"));
        this.list_entry = new EncryptionListEntry(app.stream_interactor);
        this.settings_entry = new AccountSettingsEntry(this);
        this.contact_details_provider = new ContactDetailsProvider(app.stream_interactor);

        app.plugin_registry.register_encryption_list_entry(list_entry);
        app.plugin_registry.register_account_settings_entry(settings_entry);
        app.plugin_registry.register_contact_details_entry(contact_details_provider);
        app.stream_interactor.module_manager.initialize_account_modules.connect(on_initialize_account_modules);

        Manager.start(app.stream_interactor, db);
        app.stream_interactor.get_module(FileManager.IDENTITY).add_outgoing_processor(new OutFileProcessor(app.stream_interactor));
        app.stream_interactor.get_module(FileManager.IDENTITY).add_incomming_processor(new InFileProcessor());

        internationalize(GETTEXT_PACKAGE, app.search_path_generator.get_locale_path(GETTEXT_PACKAGE, LOCALE_INSTALL_DIR));
    }

    public void shutdown() { }

    private void on_initialize_account_modules(Account account, ArrayList<Xmpp.XmppStreamModule> modules) {
        Module module = new Module(db.get_account_key(account));
        this.modules[account] = module;
        modules.add(module);
    }
}

}
