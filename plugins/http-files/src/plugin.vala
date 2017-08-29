extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino.Plugins.HttpFiles {

public class Plugin : RootInterface, Object {

    public Dino.Application app;
    public ConversationsTitlebarEntry conversations_titlebar_entry;
    public FileProvider file_provider;

    public void registered(Dino.Application app) {
        try {
            this.app = app;
            Manager.start(this.app.stream_interactor);

            conversations_titlebar_entry = new ConversationsTitlebarEntry(app.stream_interactor);
            file_provider = new FileProvider(app.stream_interactor, app.db);

            app.plugin_registry.register_contact_titlebar_entry(conversations_titlebar_entry);
            app.stream_interactor.module_manager.initialize_account_modules.connect((account, list) => {
                list.add(new UploadStreamModule());
            });

            app.stream_interactor.get_module(FileManager.IDENTITY).add_provider(file_provider);
        } catch (Error e) {
            print(@"Error initializing http-files: $(e.message)\n");
        }
    }

    public void shutdown() {
        // Nothing to do
    }
}

}
