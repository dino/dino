using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_view.ui")]
public class ConversationView : Gtk.Overlay {

    [GtkChild] public Revealer goto_end_revealer;
    [GtkChild] public Button goto_end_button;
    [GtkChild] public ChatInput.View chat_input;
    [GtkChild] public ConversationSummary.ConversationView conversation_frame;
    [GtkChild] public Revealer white_revealer;

    construct {
        white_revealer.notify["child-revealed"].connect_after(on_child_revealed_changed);
    }

    public void add_overlay_dialog(Widget widget) {
        Revealer revealer = new Revealer() { transition_type=RevealerTransitionType.CROSSFADE , transition_duration= 100, visible=true };
        revealer.add(widget);

        this.add_overlay(revealer);

        revealer.reveal_child = true;
        white_revealer.visible = true;
        white_revealer.reveal_child = true;
        widget.destroy.connect(() => {
            revealer.destroy(); // GTK4: this.remove_overlay(revealer);
            white_revealer.reveal_child = false;
            chat_input.do_focus();
        });
    }

    private void on_child_revealed_changed() {
        if (!white_revealer.child_revealed) {
            white_revealer.visible = false;
        }
    }

    public override void dispose() {
        // To prevent a warning when closing Dino
        // "Can't set a target list on a widget until you've called gtk_drag_dest_set() to make the widget into a drag destination"
        Gtk.drag_dest_unset(this);
    }
}

}
