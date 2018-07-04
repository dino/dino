using Gee;
using Gtk;
using Gdk;

using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

[GtkTemplate (ui = "/im/dino/Dino/conversation_selector/view.ui")]
public class View : Box {
    public List conversation_list;

    [GtkChild] private ScrolledWindow scrolled;

    public View init(StreamInteractor stream_interactor) {
        conversation_list = new List(stream_interactor) { visible=true };
        scrolled.add(conversation_list);
        return this;
    }

}

}
