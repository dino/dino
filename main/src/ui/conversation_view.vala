using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_view.ui")]
public class ConversationView : Widget {

//    [GtkChild] public unowned ScrolledWindow conversation_scrolled;
    [GtkChild] public unowned Overlay overlay;
    [GtkChild] public unowned Revealer goto_end_revealer;
    [GtkChild] public unowned Button goto_end_button;
    [GtkChild] public unowned ChatInput.View chat_input;
    [GtkChild] public unowned ConversationSummary.ConversationView conversation_frame;
    [GtkChild] public unowned Revealer white_revealer;
    [GtkChild] public unowned Revealer content_revealer;

    public ListView list_view = new ListView(null, null);

    public bool at_current_content = true;

    construct {
        this.layout_manager = new BinLayout();
        white_revealer.notify["child-revealed"].connect_after(on_child_revealed_changed);

//        conversation_scrolled.set_child(list_view);
//        list_view.set_factory(get_item_factory());

    }

    public void add_overlay_dialog(Widget widget) {
        content_revealer.set_child(widget);

        content_revealer.visible = true;
        content_revealer.reveal_child = true;
        white_revealer.visible = true;
        white_revealer.reveal_child = true;
    }

    public void remove_overlay_dialog() {
        white_revealer.reveal_child = false;
        content_revealer.reveal_child = false;
        chat_input.do_focus();
    }

    private void on_child_revealed_changed() {
        if (!white_revealer.child_revealed) {
            white_revealer.visible = false;
            content_revealer.visible = false;
            content_revealer.set_child(null);
        }
    }
}

}
