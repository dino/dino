using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino;
using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_selector/conversation_account_separator.ui")]
public class ConversationSelectorAccountSep : ListBoxRow {

    public signal void closed();

    [GtkChild] protected Label name_label;
    [GtkChild] public Revealer main_revealer;

    public Account account { get; private set; }

    protected ContentItem? last_content_item;
    protected bool read = true;


    protected StreamInteractor stream_interactor;

    construct {
        name_label.attributes = new AttrList();
        name_label.attributes.insert(attr_weight_new(Weight.BOLD));
    }

    public ConversationSelectorAccountSep(StreamInteractor stream_interactor, Account account) {
        this.account = account;
        this.stream_interactor = stream_interactor;
        this.activatable = false;
        this.focus_on_click = false;
        this.selectable = false;

        update_name_label();
    }

    protected void update_name_label() {
        name_label.label = account.display_name;
    }
}

}

