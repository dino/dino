using Gee;

using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

    public class Plugin : Plugins.RootInterface, Object {
        public Dino.Application app;
        public Database db;
        public HashMap<Account, Module> modules = new HashMap<Account, Module>(Account.hash_func, Account.equals_func);

        private EncryptionListEntry list_entry;
        private AccountSettingsEntry settings_entry;

        public void registered(Dino.Application app) {
            this.app = app;
            this.db = new Database(Path.build_filename(Application.get_storage_dir(), "pgp.db"));
            this.list_entry = new EncryptionListEntry(app.stream_interaction);
            this.settings_entry = new AccountSettingsEntry(this);

            app.plugin_registry.register_encryption_list_entry(list_entry);
            app.plugin_registry.register_account_settings_entry(settings_entry);
            app.stream_interaction.module_manager.initialize_account_modules.connect(on_initialize_account_modules);

            Manager.start(app.stream_interaction, db);
        }

        public void shutdown() { }

        private void on_initialize_account_modules(Account account, ArrayList<Xmpp.Core.XmppStreamModule> modules) {
            Module module = new Module(db.get_account_key(account));
            this.modules[account] = module;
            modules.add(module);
        }
    }

}
