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

    public abstract bool can_encrypt(Conversation conversation);
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
}

public abstract interface ConversationItemPopulator : Object {
    public abstract string id { get; }
    public abstract void init(Conversation conversation, ConversationItemCollection summary, WidgetType type);
    public virtual void populate_timespan(Conversation conversation, DateTime from, DateTime to) { }
    public virtual void populate_between_widgets(Conversation conversation, DateTime from, DateTime to) { }
    public abstract void close(Conversation conversation);
}

public abstract class MetaConversationItem : Object {
    public virtual Jid? jid { get; set; default=null; }
    public virtual string color { get; set; default=null; }
    public virtual string display_name { get; set; default=null; }
    public virtual bool dim { get; set; default=false; }
    public virtual DateTime? sort_time { get; set; default=null; }
    public virtual double seccondary_sort_indicator { get; set; }
    public virtual DateTime? display_time { get; set; default=null; }
    public virtual Encryption? encryption { get; set; default=null; }
    public virtual Entities.Message.Marked? mark { get; set; default=null; }

    public abstract bool can_merge { get; set; }
    public abstract bool requires_avatar { get; set; }
    public abstract bool requires_header { get; set; }

    public abstract Object? get_widget(WidgetType type);
}

public interface ConversationItemCollection : Object {
    public signal void insert_item(MetaConversationItem item);
    public signal void remove_item(MetaConversationItem item);
}

public interface MessageDisplayProvider : Object {
    public abstract string id { get; set; }
    public abstract double priority { get; set; }
    public abstract bool can_display(Entities.Message? message);
    public abstract MetaConversationItem? get_item(Entities.Message message, Entities.Conversation conversation);
}

public interface FileWidget : Object {
    public abstract Object? get_widget(WidgetType type);
}

public interface FileDisplayProvider : Object {
    public abstract double priority { get; }
    public abstract bool can_display(Entities.Message? message);
    public abstract FileWidget? get_item(Entities.Message? message);
}

}
