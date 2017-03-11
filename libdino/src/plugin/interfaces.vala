using Gtk;

namespace Dino.Plugins {

public enum Priority {
    LOWEST,
    LOWER,
    DEFAULT,
    HIGHER,
    HIGHEST
}

public interface RootInterface : Object {
    public abstract void registered(Dino.Application app);

    public abstract void shutdown();
}

public interface EncryptionListEntry : Object {
    public abstract Entities.Encryption encryption { get; }
    public abstract string name { get; }

    public abstract bool can_encrypt(Entities.Conversation conversation);
}

public abstract class AccountSettingsEntry : Object {
    public abstract string id { get; }
    public virtual Priority priority { get { return Priority.DEFAULT; } }
    public abstract string name { get; }
    public virtual int16 label_top_padding { get { return -1; } }

    public abstract AccountSettingsWidget get_widget();
}

public interface AccountSettingsWidget : Gtk.Widget {
    public abstract void set_account(Entities.Account account);

    public abstract signal void activated();

    public abstract void deactivate();
}

}