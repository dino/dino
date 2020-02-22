using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_view.ui")]
public class ConversationView : Gtk.Box {

    [GtkChild] public Revealer goto_end_revealer;
    [GtkChild] public Button goto_end_button;
    [GtkChild] public ChatInput.View chat_input;
    [GtkChild] public ConversationSummary.ConversationView conversation_frame;

}

}
