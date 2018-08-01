using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/add_groupchat_dialog.ui")]
protected class AddGroupchatDialog : Gtk.Dialog {

    [GtkChild] private Stack accounts_stack;
    [GtkChild] private AccountComboBox account_combobox;
    [GtkChild] private Label account_label;
    [GtkChild] private Button ok_button;
    [GtkChild] private Button cancel_button;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Entry alias_entry;
    [GtkChild] private Entry nick_entry;

    private StreamInteractor stream_interactor;
    private Xmpp.Xep.Bookmarks.Conference? edit_conference = null;
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

    public AddGroupchatDialog.for_conference(StreamInteractor stream_interactor, Account account, Xmpp.Xep.Bookmarks.Conference conference) {
        this(stream_interactor);
        edit_conference = conference;
        ok_button.label = _("Save");
        ok_button.sensitive = true;
        accounts_stack.set_visible_child_name("label");
        account_label.label = account.bare_jid.to_string();
        account_combobox.selected = account;
        jid_entry.text = conference.jid.to_string();
        nick_entry.text = conference.nick ?? "";
        alias_entry.text = conference.name;
    }

    private bool on_jid_key_release() {
        check_ok();
        if (!alias_entry_changed) {
            Jid? parsed_jid = Jid.parse(jid_entry.text);
            alias_entry.text = parsed_jid != null && parsed_jid.localpart != null ? parsed_jid.localpart : jid_entry.text;
        }
        return false;
    }

    private bool check_ok() {
        Jid? parsed_jid = Jid.parse(jid_entry.text);
        ok_button.sensitive = parsed_jid != null && parsed_jid.localpart != null && parsed_jid.resourcepart == null;
        return false;
    }

    private void on_ok_button_clicked() {
        Xmpp.Xep.Bookmarks.Conference conference = new Xmpp.Xep.Bookmarks.Conference(Jid.parse(jid_entry.text));
        conference.nick = nick_entry.text != "" ? nick_entry.text : null;
        conference.name = alias_entry.text;
        if (edit_conference == null) {
            stream_interactor.get_module(MucManager.IDENTITY).add_bookmark(account_combobox.selected, conference);
        } else {
            stream_interactor.get_module(MucManager.IDENTITY).replace_bookmark(account_combobox.selected, edit_conference, conference);
        }
        close();
    }
}

}
