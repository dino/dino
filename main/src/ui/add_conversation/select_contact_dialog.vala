using Gee;
using Gdk;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class SelectContactDialog : Gtk.Dialog {

    public signal void selected(Account account, Jid jid);

    public Button ok_button;

    private RosterList roster_list;
    private SelectJidFragment select_jid_fragment;
    private StreamInteractor stream_interactor;
    private Gee.List<Account> accounts;

    public SelectContactDialog(StreamInteractor stream_interactor, Gee.List<Account> accounts) {
        Object(use_header_bar : Util.use_csd() ? 1 : 0);
        modal = true;

        this.stream_interactor = stream_interactor;
        this.accounts = accounts;

        setup_view();
        setup_headerbar();

        set_default_size(400, 520);
    }

    public void set_filter(string str) {
        select_jid_fragment.set_filter(str);
    }

    private void setup_headerbar() {
        Button cancel_button = new Button();
        cancel_button.set_label(_("Cancel"));
        cancel_button.visible = true;

        ok_button = new Button();
        ok_button.get_style_context().add_class("suggested-action");
        ok_button.sensitive = false;
        ok_button.visible = true;

        if (Util.use_csd()) {
            HeaderBar header_bar = get_header_bar() as HeaderBar;
            header_bar.show_close_button = false;

            header_bar.pack_start(cancel_button);
            header_bar.pack_end(ok_button);
        } else {
            Box box = new Box(Orientation.HORIZONTAL, 5) { halign=Align.END, margin_bottom=15, margin_start=80, margin_end=80, visible=true };

            cancel_button.halign = Align.START;
            ok_button.halign = Align.END;
            box.add(cancel_button);
            box.add(ok_button);

            get_content_area().add(box);
        }

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(() => {
            ListRow? selected_row = roster_list.get_selected_row() as ListRow;
            if (selected_row != null) selected(selected_row.account, selected_row.jid);
            close();
        });
    }

    private void setup_view() {
        roster_list = new RosterList(stream_interactor, accounts);
        roster_list.row_activated.connect(() => { ok_button.clicked(); });
        select_jid_fragment = new SelectJidFragment(stream_interactor, roster_list, accounts);
        select_jid_fragment.add_jid.connect((row) => {
            AddContactDialog add_contact_dialog = new AddContactDialog(stream_interactor);
            add_contact_dialog.set_transient_for(this);
            add_contact_dialog.present();
        });
        select_jid_fragment.remove_jid.connect((row) => {
            ListRow list_row = roster_list.get_selected_row() as ListRow;
            stream_interactor.get_module(RosterManager.IDENTITY).remove_jid(list_row.account, list_row.jid);
        });
        select_jid_fragment.notify["done"].connect(() => {
            ok_button.sensitive = select_jid_fragment.done;
        });
        get_content_area().add(select_jid_fragment);
    }
}

public class AddChatDialog : SelectContactDialog {

    public signal void added(Conversation conversation);

    public AddChatDialog(StreamInteractor stream_interactor, Gee.List<Account> accounts) {
        base(stream_interactor, accounts);
        title = _("Start Conversation");
        ok_button.label = _("Start");
        selected.connect((account, jid) => {
            Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.CHAT);
            stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation);
            added(conversation);
        });
    }
}

}
