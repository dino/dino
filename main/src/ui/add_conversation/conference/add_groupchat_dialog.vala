using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.AddConversation.Conference {

[GtkTemplate (ui = "/org/dino-im/add_conversation/add_groupchat_dialog.ui")]
protected class AddGroupchatDialog : Gtk.Dialog {

    [GtkChild] private Stack accounts_stack;
    [GtkChild] private ComboBoxText accounts_comboboxtext;
    [GtkChild] private Label account_label;
    [GtkChild] private Button ok_button;
    [GtkChild] private Button cancel_button;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Entry alias_entry;
    [GtkChild] private Entry nick_entry;
    [GtkChild] private CheckButton autojoin_checkbutton;

    private StreamInteractor stream_interactor;
    private Xmpp.Xep.Bookmarks.Conference? edit_confrence = null;
    private bool alias_entry_changed = false;

    public AddGroupchatDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.stream_interactor = stream_interactor;
        ok_button.label = "Add";
        ok_button.get_style_context().add_class("suggested-action"); // TODO why doesn't it work in XML
        accounts_stack.set_visible_child_name("combobox");
        foreach (Account account in stream_interactor.get_accounts()) {
            accounts_comboboxtext.append_text(account.bare_jid.to_string());
        }
        accounts_comboboxtext.set_active(0);

        cancel_button.clicked.connect(() => { close(); });
        ok_button.clicked.connect(on_ok_button_clicked);
        jid_entry.key_release_event.connect(on_jid_key_release);
        nick_entry.key_release_event.connect(check_ok);
    }

    public AddGroupchatDialog.for_conference(StreamInteractor stream_interactor, Account account, Xmpp.Xep.Bookmarks.Conference conference) {
        this(stream_interactor);
        edit_confrence = conference;
        ok_button.label = "Save";
        ok_button.sensitive = true;
        accounts_stack.set_visible_child_name("label");
        account_label.label = account.bare_jid.to_string();
        jid_entry.text = conference.jid;
        nick_entry.text = conference.nick;
        autojoin_checkbutton.active = conference.autojoin;
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
        ok_button.sensitive = parsed_jid != null && parsed_jid.localpart != null && parsed_jid.resourcepart == null &&
            nick_entry.text != "" && alias_entry.text != null;
        return false;
    }

    private void on_ok_button_clicked() {
        Account? account = null;
        foreach (Account account2 in stream_interactor.get_accounts()) {
            if (accounts_comboboxtext.get_active_text() == account2.bare_jid.to_string()) {
                account = account2;
            }
        }
        Xmpp.Xep.Bookmarks.Conference conference = new Xmpp.Xep.Bookmarks.Conference(jid_entry.text);
        conference.nick = nick_entry.text;
        conference.name = alias_entry.text;
        conference.autojoin = autojoin_checkbutton.active;
        if (edit_confrence == null) {
            MucManager.get_instance(stream_interactor).add_bookmark(account, conference);
        } else {
            MucManager.get_instance(stream_interactor).replace_bookmark(account, edit_confrence, conference);
        }
        close();
    }
}

}