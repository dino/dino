using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/add_groupchat_dialog.ui")]
protected class AddGroupchatDialog : Gtk.Dialog {

    [GtkChild] private Stack accounts_stack;
    [GtkChild] private AccountComboBox account_combobox;
    [GtkChild] private Button ok_button;
    [GtkChild] private Button cancel_button;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Entry alias_entry;
    [GtkChild] private Entry nick_entry;

    private StreamInteractor stream_interactor;
    private bool alias_entry_changed = false;

    public AddGroupchatDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.stream_interactor = stream_interactor;
        ok_button.label = _("Add");
        ok_button.get_style_context().add_class("suggested-action"); // TODO why doesn't it work in XML
        accounts_stack.set_visible_child_name("combobox");
        account_combobox.initialize(stream_interactor);

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(on_ok_button_clicked);
        jid_entry.key_release_event.connect(on_jid_key_release);
        nick_entry.key_release_event.connect(check_ok);
    }

    private bool on_jid_key_release() {
        check_ok();
        if (!alias_entry_changed) {
            try {
                Jid parsed_jid = new Jid(jid_entry.text);
                alias_entry.text = parsed_jid != null && parsed_jid.localpart != null ? parsed_jid.localpart : jid_entry.text;
            } catch (InvalidJidError e) {
                alias_entry.text = jid_entry.text;
            }
        }
        return false;
    }

    private bool check_ok() {
        try {
            Jid parsed_jid = new Jid(jid_entry.text);
            ok_button.sensitive = parsed_jid != null && parsed_jid.localpart != null && parsed_jid.resourcepart == null;
        } catch (InvalidJidError e) {
            ok_button.sensitive = false;
        }
        return false;
    }

    private void on_ok_button_clicked() {
        try {
            Conference conference = new Conference();
            conference.jid = new Jid(jid_entry.text);
            conference.nick = nick_entry.text != "" ? nick_entry.text : null;
            conference.name = alias_entry.text;
            stream_interactor.get_module(MucManager.IDENTITY).add_bookmark(account_combobox.selected, conference);
            close();
        } catch (InvalidJidError e) {
            warning("Ignoring invalid conference Jid: %s", e.message);
        }
    }
}

}
