using Dino.Entities;

namespace Dino {

[DBus (name = "com.canonical.Unity.LauncherEntry")]
public interface DBusLauncherEntry : Object {
    public signal void update(string app_uri, HashTable<string, Variant> properties);
}

public class Ui.LauncherEntry : DBusLauncherEntry, Object {

    private const string OBJECT_PATH  = "/im/dino/Dino";
    private const string LAUNCHER_URI = "application://im.dino.Dino.desktop";

    private int64 last_count = -1;
    private uint update_pending = 0;

    private ChatInteraction chat_interaction;
    private ConversationManager conversation_manager;

    public LauncherEntry(StreamInteractor stream_interactor) {
        DBusConnection? conn = GLib.Application.get_default().get_dbus_connection();
        if (conn == null) return;

        try {
            conn.register_object(OBJECT_PATH, (DBusLauncherEntry) this);
        } catch (IOError e) {
            warning("LauncherEntry: could not register D-Bus object: %s", e.message);
            return;
        }

        conversation_manager = stream_interactor.get_module(ConversationManager.IDENTITY);
        chat_interaction = stream_interactor.get_module(ChatInteraction.IDENTITY);

        foreach (Conversation conversation in conversation_manager.get_active_conversations()) {
            conversation.notify["read-up-to-item"].connect(schedule_count_update);
        }

        conversation_manager.conversation_activated.connect((conversation) => {
            conversation.notify["read-up-to-item"].connect(schedule_count_update);
            schedule_count_update();
        });

        conversation_manager.conversation_deactivated.connect((conversation) => {
            conversation.notify["read-up-to-item"].disconnect(schedule_count_update);
            schedule_count_update();
        });

        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(schedule_count_update);

        schedule_count_update();
    }

    private void schedule_count_update() {
        if (update_pending != 0) return;

        update_pending = Idle.add_once(() => {
            update_pending = 0;
            do_count_update();
        });
    }

    private void do_count_update() {
        int64 total = 0;

        foreach (Conversation conversation in conversation_manager.get_active_conversations()) {
            total += chat_interaction.get_num_unread(conversation);
        }

        if (total == last_count) return;
        if (total == 0) this.urgency_hint = false;
        this.count = last_count = total;
    }

    public int64 count {
        set {
            HashTable<string, Variant> props = new HashTable<string, Variant>(null, null);
            props["count"] = new Variant.int64(value);
            props["count-visible"] = new Variant.boolean(value > 0);
            update(LAUNCHER_URI, props);
        }
    }

    public bool urgency_hint {
        set {
            HashTable<string, Variant> props = new HashTable<string, Variant>(null, null);
            props["urgent"] = new Variant.boolean(value);
            update(LAUNCHER_URI, props);
        }
    }

}

}
