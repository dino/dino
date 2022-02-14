using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino;
using Dino.Entities;
using Xmpp;

[GtkTemplate (ui = "/im/dino/Dino/conversation_row.ui")]
public class Dino.Ui.ConversationListRow : ListBoxRow {

    [GtkChild] public unowned AvatarImage image;
    [GtkChild] public unowned Label name_label;
    [GtkChild] public unowned Label time_label;
    [GtkChild] public unowned Label nick_label;
    [GtkChild] public unowned Label message_label;
    [GtkChild] public unowned Label unread_count_label;
    [GtkChild] public unowned Button x_button;
    [GtkChild] public unowned Revealer time_revealer;
    [GtkChild] public unowned Revealer xbutton_revealer;
    [GtkChild] public unowned Revealer unread_count_revealer;
    [GtkChild] public unowned Revealer main_revealer;

    construct {
        name_label.attributes = new AttrList();
    }

    public override void state_flags_changed(StateFlags flags) {
        StateFlags curr_flags = get_state_flags();
        if ((curr_flags & StateFlags.PRELIGHT) != 0) {
            time_revealer.set_reveal_child(false);
            unread_count_revealer.set_reveal_child(false);
            xbutton_revealer.set_reveal_child(true);
        } else {
            time_revealer.set_reveal_child(true);
            unread_count_revealer.set_reveal_child(true);
            xbutton_revealer.set_reveal_child(false);
        }
    }
}