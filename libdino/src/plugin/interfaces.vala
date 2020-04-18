using Dino.Entities;
using Xmpp;

namespace Dino.Plugins {

public enum Priority {
    LOWEST,
    LOWER,
    DEFAULT,
    HIGHER,
    HIGHEST
}

public enum WidgetType {
    GTK
}

public interface RootInterface : Object {
    public abstract void registered(Dino.Application app);

    public abstract void shutdown();
}

public interface EncryptionListEntry : Object {
    public abstract Entities.Encryption encryption { get; }
    public abstract string name { get; }

    public abstract void encryption_activated(Entities.Conversation conversation, Plugins.SetInputFieldStatus callback);
    public abstract Object? get_encryption_icon(Entities.Conversation conversation, ContentItem content_item);
}

public abstract class AccountSettingsEntry : Object {
    public abstract string id { get; }
    public virtual Priority priority { get { return Priority.DEFAULT; } }
    public abstract string name { get; }
    public virtual int16 label_top_padding { get { return -1; } }

    public abstract AccountSettingsWidget? get_widget(WidgetType type);
}

public interface AccountSettingsWidget : Object {
    public abstract void set_account(Account account);

    public abstract signal void activated();

    public abstract void deactivate();
}

public interface ContactDetailsProvider : Object {
    public abstract string id { get; }

    public abstract void populate(Conversation conversation, ContactDetails contact_details, WidgetType type);
}

public class ContactDetails : Object {
    public signal void save();
    public signal void add(string category, string label, string? desc, Object widget);
}

public interface TextCommand : Object {
    public abstract string cmd { get; }

    public abstract string? handle_command(string? text, Entities.Conversation? conversation);
}

public interface ConversationTitlebarEntry : Object {
    public abstract string id { get; }
    public abstract double order { get; }
    public abstract ConversationTitlebarWidget? get_widget(WidgetType type);
}

public interface ConversationTitlebarWidget : Object {
    public abstract void set_conversation(Conversation conversation);
    public abstract void unset_conversation();
}

public abstract interface ConversationItemPopulator : Object {
    public abstract string id { get; }
    public abstract void init(Conversation conversation, ConversationItemCollection summary, WidgetType type);
    public abstract void close(Conversation conversation);
}

public abstract interface ConversationAdditionPopulator : ConversationItemPopulator {
    public virtual void populate_timespan(Conversation conversation, DateTime from, DateTime to) { }
}

public abstract interface NotificationPopulator : Object {
    public abstract string id { get; }
    public abstract void init(Conversation conversation, NotificationCollection summary, WidgetType type);
    public abstract void close(Conversation conversation);
}

public abstract class MetaConversationItem : Object {
    public virtual string populator_id { get; set; }
    public virtual Jid? jid { get; set; default=null; }
    public virtual DateTime sort_time { get; set; default = new DateTime.now_utc(); }
    public virtual long seccondary_sort_indicator { get; set; }
    public virtual long tertiary_sort_indicator { get; set; }
    public virtual DateTime? display_time { get; set; default = null; }
    public virtual Encryption encryption { get; set; default = Encryption.NONE; }
    public virtual Entities.Message.Marked mark { get; set; default = Entities.Message.Marked.NONE; }

    public bool can_merge { get; set; default=false; }
    public bool requires_avatar { get; set; default=false; }
    public bool requires_header { get; set; default=false; }
    public bool in_edit_mode { get; set; default=false; }

    public abstract Object? get_widget(WidgetType type);
    public abstract Gee.List<MessageAction>? get_item_actions(WidgetType type);
}

public delegate void MessageActionEvoked(Object button, Plugins.MetaConversationItem evoked_on, Object widget);
public class MessageAction : Object {
    public string icon_name;
    public MessageActionEvoked callback;
}

public abstract class MetaConversationNotification : Object {
    public abstract Object? get_widget(WidgetType type);
}

public interface ConversationItemCollection : Object {
    public signal void inserted_item(MetaConversationItem item);
    public signal void removed_item(MetaConversationItem item);

    public abstract void insert_item(MetaConversationItem item);
    public abstract void remove_item(MetaConversationItem item);
}

public interface NotificationCollection : Object {
    public signal void add_meta_notification(MetaConversationNotification item);
    public signal void remove_meta_notification(MetaConversationNotification item);
}

public delegate void SetInputFieldStatus(InputFieldStatus field_status);
public class InputFieldStatus : Object {
    public enum MessageType {
        NONE,
        INFO,
        WARNING,
        ERROR
    }
    public enum InputState {
        NORMAL,
        DISABLED,
        NO_SEND
    }

    public string? message;
    public MessageType message_type;
    public InputState input_state;
    public bool contains_markup;

    public InputFieldStatus(string? message, MessageType message_type, InputState input_state, bool contains_markup = false) {
        this.message = message;
        this.message_type = message_type;
        this.input_state = input_state;
        this.contains_markup = contains_markup;
    }
}

}
