using Gtk;

using Dino.Entities;

public class Dino.Application : Gtk.Application {

    public Database db;
    public StreamInteractor stream_interaction;
    public Plugins.Registry plugin_registry = new Plugins.Registry();

    public Application() {
        this.db = new Database("store.sqlite3");
        this.stream_interaction = new StreamInteractor(db);

        AvatarManager.start(stream_interaction, db);
        MessageManager.start(stream_interaction, db);
        CounterpartInteractionManager.start(stream_interaction);
        PresenceManager.start(stream_interaction);
        MucManager.start(stream_interaction);
        RosterManager.start(stream_interaction);
        ConversationManager.start(stream_interaction, db);
        ChatInteraction.start(stream_interaction);
    }
}

