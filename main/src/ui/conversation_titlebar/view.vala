using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class ConversationTitlebar : Gtk.HeaderBar {

    private StreamInteractor stream_interactor;
    private Window window;
    private Conversation? conversation;
    private Gee.List<Plugins.ConversationTitlebarWidget> widgets = new ArrayList<Plugins.ConversationTitlebarWidget>();

    public ConversationTitlebar(StreamInteractor stream_interactor, Window window) {
        this.stream_interactor = stream_interactor;
        this.window = window;

        this.get_style_context().add_class("dino-right");
        show_close_button = true;
        hexpand = true;

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_contact_titlebar_entry(new MenuEntry(stream_interactor));
        app.plugin_registry.register_contact_titlebar_entry(new OccupantsEntry(stream_interactor, window));

        foreach(var e in app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            if (widget != null) {
                widgets.add(widget);
                pack_end((Gtk.Widget)widget);
            }
        }


        stream_interactor.get_module(MucManager.IDENTITY).room_name_set.connect((account, jid, room_name) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_titlebar();
            }
        });

        stream_interactor.get_module(MucManager.IDENTITY).subject_set.connect((account, jid, subject) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_titlebar();
            }
        });
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;
        update_titlebar();

        foreach (Plugins.ConversationTitlebarWidget widget in widgets) {
            widget.set_conversation(conversation);
        }
    }

    private void update_titlebar() {
        string conversation_display_name = Util.get_conversation_display_name(stream_interactor, conversation);
        set_title(conversation_display_name);

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            string groupchat_subject = stream_interactor.get_module(MucManager.IDENTITY).get_groupchat_subject(conversation.counterpart, conversation.account);
            set_subtitle(groupchat_subject != conversation_display_name ? groupchat_subject : null);
        } else {
            // unset subtitle for non-groupchat conversations
            set_subtitle(null);
        }
    }
}

}
