using Gtk;
using Gee;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class ContactDetailsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "omemo_info"; } }
    public string tab { get { return "encryption"; } }

    private Plugin plugin;

    public ContactDetailsProvider(Plugin plugin) {
        this.plugin = plugin;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, WidgetType type) { }

    public Object? get_widget(Conversation conversation) {
        if (conversation.type_ != Conversation.Type.CHAT) return null;

        var widget  = new OmemoPreferencesWidget(plugin);
        widget.set_jid(conversation.account, conversation.counterpart);
        return widget;
    }
}

}
