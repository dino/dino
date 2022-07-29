using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class SearchMenuEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "search"; } }
    public double order { get { return 1; } }

    public ToggleButton button = new ToggleButton() { tooltip_text=Util.string_if_tooltips_active(_("Search messages")) };

    public SearchMenuEntry() {
        button.set_icon_name("system-search-symbolic");
    }

    public new void set_conversation(Conversation conversation) { }
    public new void unset_conversation() { }

    public Object? get_widget(Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return null;
        return button;
    }
}

}
