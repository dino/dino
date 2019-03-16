using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class SearchMenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "search"; } }

    public GlobalSearchButton search_button = new GlobalSearchButton() { tooltip_text=_("Search messages"), visible = true };

    public SearchMenuEntry() {
        search_button.set_image(new Gtk.Image.from_icon_name("system-search-symbolic", Gtk.IconSize.MENU) { visible = true });
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
    public new void set_conversation(Conversation conversation) { }
}

}
