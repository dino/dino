extern const string GETTEXT_PACKAGE;
extern const string LOCALE_INSTALL_DIR;

namespace Dino.Plugins.HttpFiles {

public class Plugin : RootInterface, Object {

    public Dino.Application app;
    public FileProvider file_provider;

    public void registered(Dino.Application app) {
        this.app = app;
        Manager.start(this.app.stream_interactor, app.db);

        file_provider = new FileProvider(app.stream_interactor, app.db);

        app.stream_interactor.get_module(FileManager.IDENTITY).add_provider(file_provider);
        app.stream_interactor.get_module(ContentItemStore.IDENTITY).add_filter(new FileMessageFilter(app.db));
    }

    public void shutdown() {
        // Nothing to do
    }
}

}
