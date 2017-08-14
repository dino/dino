extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino.Plugins.HttpFiles {

public class Plugin : RootInterface, Object {

    public Dino.Application app;
    public ConversationsTitlebarEntry conversations_titlebar_entry;

    public void registered(Dino.Application app) {
        try {
            this.app = app;
            this.conversations_titlebar_entry = new ConversationsTitlebarEntry(app.stream_interaction);

            this.app.plugin_registry.register_contact_titlebar_entry(conversations_titlebar_entry);
            this.app.stream_interaction.module_manager.initialize_account_modules.connect((account, list) => {
                list.add(new UploadStreamModule());
            });
            Manager.start(this.app.stream_interaction);
        } catch (Error e) {
            print(@"Error initializing http-files: $(e.message)\n");
        }
    }

    public void shutdown() {
        // Nothing to do
    }
}

}
