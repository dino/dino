using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.AddConversation.Chat {

public class Dialog : Gtk.Dialog {

    public signal void selected(Account account, Jid jid);

    public Button ok_button;

    private RosterList roster_list;
    private SelectJidFragment select_jid_fragment;
    private StreamInteractor stream_interactor;
    private Gee.List<Account> accounts;

    public Dialog(StreamInteractor stream_interactor, Gee.List<Account> accounts) {
        Object(use_header_bar : 1);
        modal = true;

        this.stream_interactor = stream_interactor;
        this.accounts = accounts;

        setup_headerbar();
        setup_view();
    }

    private void setup_headerbar() {
        HeaderBar header_bar = get_header_bar() as HeaderBar;
        header_bar.show_close_button = false;

        Button cancel_button = new Button();
        cancel_button.set_label(_("Cancel"));
        cancel_button.visible = true;
        header_bar.pack_start(cancel_button);

        ok_button = new Button();
        ok_button.get_style_context().add_class("suggested-action");
        ok_button.sensitive = false;
        ok_button.visible = true;
        header_bar.pack_end(ok_button);

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
        select_jid_fragment.edit_jid.connect(() => {

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

}