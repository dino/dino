using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/add_groupchat_dialog.ui")]
protected class AddGroupchatDialog : Gtk.Dialog {

    [GtkChild] private unowned Stack accounts_stack;
    [GtkChild] private unowned AccountComboBox account_combobox;
    [GtkChild] private unowned Button ok_button;
    [GtkChild] private unowned Button cancel_button;
    [GtkChild] private unowned Entry jid_entry;
    [GtkChild] private unowned Entry alias_entry;
    [GtkChild] private unowned Entry nick_entry;

    private StreamInteractor stream_interactor;
    private bool alias_entry_changed = false;

    public AddGroupchatDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.stream_interactor = stream_interactor;
        ok_button.label = _("Add");
        ok_button.add_css_class("suggested-action"); // TODO why doesn't it work in XML
        accounts_stack.set_visible_child_name("combobox");
        account_combobox.initialize(stream_interactor);

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(on_ok_button_clicked);

        jid_entry.changed.connect(on_jid_key_release);
        nick_entry.changed.connect(check_ok);
    }

    private void on_jid_key_release() {
        check_ok();
        if (!alias_entry_changed) {
            try {
                Jid parsed_jid = new Jid(jid_entry.text);
                alias_entry.text = parsed_jid != null && parsed_jid.localpart != null ? parsed_jid.localpart : jid_entry.text;
            } catch (InvalidJidError e) {
                alias_entry.text = jid_entry.text;
            }
        }
    }

    private void check_ok() {
        try {
            Jid parsed_jid = new Jid(jid_entry.text);
            ok_button.sensitive = parsed_jid != null && parsed_jid.localpart != null && parsed_jid.resourcepart == null;
        } catch (InvalidJidError e) {
            ok_button.sensitive = false;
        }
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
