using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/add_account_dialog.ui")]
public class AddAccountDialog : Gtk.Dialog {

    public signal void added(Account account);

    [GtkChild] private Button cancel_button;
    [GtkChild] private Button ok_button;
    [GtkChild] private Entry alias_entry;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Entry password_entry;

    public AddAccountDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.title = _("Add Account");

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(on_ok_button_clicked);
        jid_entry.changed.connect(on_jid_entry_changed);
        jid_entry.focus_out_event.connect(on_jid_entry_focus_out_event);
    }

    private void on_jid_entry_changed() {
        Jid? jid = Jid.parse(jid_entry.text);
        if (jid != null && jid.localpart != null && jid.resourcepart == null) {
            ok_button.set_sensitive(true);
            jid_entry.secondary_icon_name = null;
        } else {
            ok_button.set_sensitive(false);
        }
    }

    private bool on_jid_entry_focus_out_event() {
        Jid? jid = Jid.parse(jid_entry.text);
        if (jid == null || jid.localpart == null || jid.resourcepart != null) {
            jid_entry.secondary_icon_name = "dialog-warning-symbolic";
            // TODO why doesn't the tooltip work
            jid_entry.set_icon_tooltip_text(EntryIconPosition.SECONDARY, "JID should be of the form \"user@example.com\"");
        } else {
            jid_entry.secondary_icon_name = null;
        }
        return false;
    }

    private void on_ok_button_clicked() {
        Jid jid = new Jid(jid_entry.get_text());
        string password = password_entry.get_text();
        string alias = alias_entry.get_text();
        Account account = new Account(jid, null, password, alias);
        added(account);
        close();
    }
}

}
