namespace Dino.Plugins.NotificationSound {

public class Plugin : RootInterface, Object {

    public Dino.Application app;
    private Canberra.Context sound_context;

    public void registered(Dino.Application app) {
        this.app = app;
        Canberra.Context.create(out sound_context);

        app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_message.connect((message, conversation) => {
            sound_context.play(0, Canberra.PROP_EVENT_ID, "message-new-instant", Canberra.PROP_EVENT_DESCRIPTION, "New Dino message");
        });
    }

    public void shutdown() { }
}

}
