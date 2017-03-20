using Gee;
using Gtk;
using Gdk;

using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

[GtkTemplate (ui = "/org/dino-im/conversation_selector/view.ui")]
public class View : Box {
    public List conversation_list;

    [GtkChild] public SearchEntry search_entry;
    [GtkChild] public SearchBar search_bar;
    [GtkChild] private ScrolledWindow scrolled;

    public View(StreamInteractor stream_interactor) {
        conversation_list = new List(stream_interactor) { visible=true };
        scrolled.add(conversation_list);
        search_entry.key_release_event.connect(search_key_release_event);
        search_entry.search_changed.connect(search_changed);
    }

    public void conversation_selected(Conversation? conversation) {
        search_entry.set_text("");
    }

    private void refilter() {
        string[]? values = null;
        string str = search_entry.get_text ();
        if (str != "") values = str.split(" ");
        conversation_list.set_filter_values(values);
    }

    private void search_changed(Editable editable) {
        refilter();
    }

    private bool search_key_release_event(EventKey event) {
        conversation_list.select_row(conversation_list.get_row_at_y(0));
        if (event.keyval == Key.Down) {
            ConversationRow? row = (ConversationRow) conversation_list.get_row_at_index(0);
            if (row != null) {
                conversation_list.select_row(row);
                row.grab_focus();
            }
        }
        return false;
    }
}

}