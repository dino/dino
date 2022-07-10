using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_view.ui")]
public class ConversationView : Gtk.Overlay {

    [GtkChild] public unowned Revealer goto_end_revealer;
    [GtkChild] public unowned Button goto_end_button;
    [GtkChild] public unowned ChatInput.View chat_input;
    [GtkChild] public unowned ConversationSummary.ConversationView conversation_frame;
    [GtkChild] public unowned Revealer white_revealer;

    construct {
        white_revealer.notify["child-revealed"].connect_after(on_child_revealed_changed);
        conversation_frame.on_quote_text.connect((t, nick, text) => on_quote_text(nick, text));
    }

    public void on_quote_text(string nick, string text) {
        unowned TextBuffer buffer = chat_input.chat_text_view.text_view.buffer;
        string text_to_quote = text;

        Regex quotes = new Regex("((?<=\n)>.*(\n|$))|(^>.*(\n|$))");
        Regex whitespace = new Regex("(\n *){2,}");
        Regex first_column = new Regex("(^|\n)(.+)");
        Regex end = new Regex("\n*$");

        text_to_quote = quotes.replace(text_to_quote, -1, 0, "");
        text_to_quote = whitespace.replace(text_to_quote, -1, 0, "\n");
        text_to_quote = "%s: %s".printf(nick, text_to_quote);

        text_to_quote = first_column.replace(text_to_quote, -1, 0, "\\1> \\2");

        string to_replace = "\n";
        if(buffer.cursor_position > 0) {
            to_replace = "";
            text_to_quote = "\n" + text_to_quote;
        }

        text_to_quote = end.replace(text_to_quote, -1, 0, to_replace);

        buffer.insert_at_cursor(text_to_quote, -1);
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
