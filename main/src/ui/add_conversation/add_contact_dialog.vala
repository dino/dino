using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/add_contact_dialog.ui")]
protected class AddContactDialog : Gtk.Dialog {

    public Account? account {
        get { return account_combobox.selected; }
        set { account_combobox.selected = value; }
    }

    public string jid {
        get { return jid_entry.text; }
        set { jid_entry.text = value; }
    }

    [GtkChild] private AccountComboBox account_combobox;
    [GtkChild] private Button ok_button;
    [GtkChild] private Button cancel_button;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Entry alias_entry;

    private StreamInteractor stream_interactor;

    public AddContactDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.stream_interactor = stream_interactor;
        account_combobox.initialize(stream_interactor);

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(on_ok_button_clicked);
        jid_entry.changed.connect(on_jid_entry_changed);
    }

    private void on_ok_button_clicked() {
        string? alias = alias_entry.text == "" ? null : alias_entry.text;
        try {
            Jid jid = new Jid(jid_entry.text);
            stream_interactor.get_module(RosterManager.IDENTITY).add_jid(account, jid, alias);
            stream_interactor.get_module(PresenceManager.IDENTITY).request_subscription(account, jid);
            close();
        } catch (InvalidJidError e) {
            warning("Tried to add contact with invalid Jid: %s", e.message);
        }
    }

    private void on_jid_entry_changed() {
        try {
            jid_entry.text = jid_entry.text.strip();
            Jid parsed_jid = new Jid(jid_entry.text);
            ok_button. sensitive = parsed_jid != null && parsed_jid.resourcepart == null &&
                    stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, parsed_jid) == null;
        } catch (InvalidJidError e) {
            ok_button.sensitive = false;
        }
    }
}

}
