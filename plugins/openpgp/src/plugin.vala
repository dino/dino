namespace Dino.Plugins.OpenPgp {

    public class Plugin : Plugins.RootInterface, Object {
        public Dino.Application app;
        public Database db;

        private Module module;
        private EncryptionListEntry list_entry;
        private AccountSettingsEntry settings_entry;

        public void registered(Dino.Application app) {
            this.app = app;
            this.module = new Module();
            this.list_entry = new EncryptionListEntry(app.stream_interaction);
            this.settings_entry = new AccountSettingsEntry();
            app.plugin_registry.register_encryption_list_entry(list_entry);
            app.plugin_registry.register_account_settings_entry(settings_entry);
            app.stream_interaction.module_manager.initialize_account_modules.connect((account, list) => {
                list.add(new Module());
            });
            Manager.start(app.stream_interaction, app.db);
        }

        public void shutdown() {
            // Nothing to do
        }
    }

}
