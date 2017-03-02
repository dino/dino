using Gtk;

using Dino.Entities;

namespace Dino.Ui.AddConversation.Conference {

[GtkTemplate (ui = "/org/dino-im/add_conversation/conference_details_fragment.ui")]
protected class ConferenceDetailsFragment : Box {

    public bool done {
        get {
            Jid? parsed_jid = Jid.parse(jid);
            return parsed_jid != null && parsed_jid.localpart != null &&
                parsed_jid.resourcepart == null && nick != "";
        }
        private set {}
    }

    public Account account {
        owned get {
            foreach (Account account in stream_interactor.get_accounts()) {
                if (accounts_comboboxtext.get_active_text() == account.bare_jid.to_string()) {
                    return account;
                }
            }
            return null;
        }
        set {
            accounts_label.label = value.bare_jid.to_string();
            accounts_comboboxtext.set_active_id(value.bare_jid.to_string());
        }
    }
    public string jid {
        get { return jid_label.label; }
        set {
            jid_label.label = value;
            jid_entry.text = value;
        }
    }
    public string nick {
        get { return nick_label.label; }
        set {
            nick_label.label = value;
            nick_entry.text = value;
        }
    }
    public string password {
        get { return password_label.label; }
        set {
            password_label.label = value;
            password_entry.text = value;
        }
    }

    [GtkChild]
    private Stack accounts_stack;

    [GtkChild]
    private Stack jid_stack;

    [GtkChild]
    private Stack nick_stack;

    [GtkChild]
    private Stack password_stack;

    [GtkChild]
    private Button accounts_button;

    [GtkChild]
    private Button jid_button;

    [GtkChild]
    private Button nick_button;

    [GtkChild]
    private Button password_button;

    [GtkChild]
    private Label accounts_label;

    [GtkChild]
    private Label jid_label;

    [GtkChild]
    private Label nick_label;

    [GtkChild]
    private Label password_label;

    [GtkChild]
    private ComboBoxText accounts_comboboxtext;

    [GtkChild]
    private Entry jid_entry;

    [GtkChild]
    private Entry nick_entry;

    [GtkChild]
    private Entry password_entry;

    private StreamInteractor stream_interactor;

    public ConferenceDetailsFragment(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        accounts_stack.set_visible_child_name("label");
        jid_stack.set_visible_child_name("label");
        nick_stack.set_visible_child_name("label");
        password_stack.set_visible_child_name("label");

        accounts_button.clicked.connect(() => { set_active_stack(accounts_stack); });
        jid_button.clicked.connect(() => { set_active_stack(jid_stack); });
        nick_button.clicked.connect(() => { set_active_stack(nick_stack); });
        password_button.clicked.connect(() => { set_active_stack(password_stack); });

        accounts_comboboxtext.changed.connect(() => { accounts_label.label = accounts_comboboxtext.get_active_text(); });
        jid_entry.key_press_event.connect(() => { jid_label.label = jid_entry.text; return false; });
        nick_entry.key_press_event.connect(() => { nick_label.label = nick_entry.text; return false; });
        password_entry.key_press_event.connect(() => { password_label.label = password_entry.text; return false; });

        jid_entry.key_press_event.connect(() => { done = true; return false; }); // just for notifying
        nick_entry.key_press_event.connect(() => { done = true; return false; });

        foreach (Account account in stream_interactor.get_accounts()) {
            accounts_comboboxtext.append_text(account.bare_jid.to_string());
        }
        accounts_comboboxtext.set_active(0);
    }

    public void clear() {
        jid = "";
        nick = "";
        password = "";
    }

    private void set_active_stack(Stack stack) {
        stack.set_visible_child_name("entry");
        if (stack != accounts_stack) accounts_stack.set_visible_child_name("label");
        if (stack != jid_stack) jid_stack.set_visible_child_name("label");
        if (stack != nick_stack) nick_stack.set_visible_child_name("label");
        if (stack != password_stack) password_stack.set_visible_child_name("label");
    }

}

}