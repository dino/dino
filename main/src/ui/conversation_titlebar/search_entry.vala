using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class SearchMenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "search"; } }

    Plugins.ConversationTitlebarWidget search_button;

    public SearchMenuEntry(Plugins.ConversationTitlebarWidget search_button) {
        this.search_button = search_button;
    }

    public double order { get { return 1; } }
    public Plugins.ConversationTitlebarWidget? get_widget(Plugins.WidgetType type) {
        if (type == Plugins.WidgetType.GTK) {
            return search_button;
        }
        return null;
    }
}

public class GlobalSearchButton : Plugins.ConversationTitlebarWidget, Gtk.ToggleButton {
    public new void set_conversation(Conversation conversation) {
        active = false;
    }
}

}
