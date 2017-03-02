using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.AddConversation.Chat {

[GtkTemplate (ui = "/org/dino-im/add_conversation/add_contact_dialog.ui")]
protected class AddContactDialog : Gtk.Dialog {

    [GtkChild]
    private ComboBoxText accounts_comboboxtext;

    [GtkChild]
    private Button ok_button;

    [GtkChild]
    private Button cancel_button;

    [GtkChild]
    private Entry jid_entry;

    [GtkChild]
    private Entry alias_entry;

    [GtkChild]
    private CheckButton subscribe_checkbutton;

    private StreamInteractor stream_interactor;

    public AddContactDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.stream_interactor = stream_interactor;

        foreach (Account account in stream_interactor.get_accounts()) {
            accounts_comboboxtext.append_text(account.bare_jid.to_string());
        }
        accounts_comboboxtext.set_active(0);

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(on_ok_button_clicked);
        jid_entry.changed.connect(on_jid_entry_changed);
    }

    private void on_ok_button_clicked() {
        string? alias = alias_entry.text == "" ? null : alias_entry.text;
        Account? account = null;
        Jid jid = new Jid(jid_entry.text);
        foreach (Account account2 in stream_interactor.get_accounts()) {
            print(account2.bare_jid.to_string() + "\n");
            if (accounts_comboboxtext.get_active_text() == account2.bare_jid.to_string()) {
                account = account2;
            }
        }
        RosterManager.get_instance(stream_interactor).add_jid(account, jid, alias);
        if (subscribe_checkbutton.active) {
            PresenceManager.get_instance(stream_interactor).request_subscription(account, jid);
        }
        close();
    }

    private void on_jid_entry_changed() {
        Jid parsed_jid = Jid.parse(jid_entry.text);
        ok_button.set_sensitive(parsed_jid != null && parsed_jid.resourcepart == null);
    }
}
}