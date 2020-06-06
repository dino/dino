using Gdk;
using Gtk;

using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/add_conversation/conference_details_fragment.ui")]
protected class ConferenceDetailsFragment : Box {

    public signal void joined();

    public bool done {
        get {
            try {
                Jid parsed_jid = new Jid(jid);
                return parsed_jid.localpart != null && parsed_jid.resourcepart == null && nick != null;
            } catch (InvalidJidError e) {
                return false;
            }
        }
        private set {}
    }

    public Account account {
        owned get { return account_combobox.selected; }
        set {
            accounts_label.label = value.bare_jid.to_string();
            account_combobox.selected = value;
            if (nick == null && value.alias != null) {
                nick = value.alias;
            }
            accounts_stack.set_visible_child_name("label");
        }
    }
    public string jid {
        get { return jid_entry.text; }
        set {
            jid_label.label = value;
            jid_entry.text = value;
            jid_stack.set_visible_child_name("label");
        }
    }
    public string? nick {
        get { return nick_entry.text != "" ? nick_entry.text : null; }
        set {
            nick_label.label = value ?? "";
            nick_entry.text = value ?? "";
            nick_stack.set_visible_child_name("label");
        }
    }
    public string? password {
        get { return password_entry.text == "" ? null : password_entry.text; }
        set {
            password_label.label = value;
            password_entry.text = value;
            nick_stack.set_visible_child_name("label");
        }
    }

    public bool fragment_active { get; set; default=true; }

    [GtkChild] private Stack accounts_stack;
    [GtkChild] private Button accounts_button;
    [GtkChild] private Label accounts_label;
    [GtkChild] private AccountComboBox account_combobox;

    [GtkChild] private Stack jid_stack;
    [GtkChild] private Button jid_button;
    [GtkChild] private Label jid_label;
    [GtkChild] private Entry jid_entry;

    [GtkChild] private Stack nick_stack;
    [GtkChild] private Button nick_button;
    [GtkChild] private Label nick_label;
    [GtkChild] private Entry nick_entry;

    [GtkChild] private Stack password_stack;
    [GtkChild] private Button password_button;
    [GtkChild] private Label password_label;
    [GtkChild] private Label password_text_label;
    [GtkChild] private Entry password_entry;

    [GtkChild] private Revealer notification_revealer;
    [GtkChild] private Button notification_button;
    [GtkChild] private Label notification_label;

    private StreamInteractor stream_interactor;
    private Button ok_button_;
    public Button ok_button {
        get { return ok_button_; }
        set {
            if (value != null) {
                value.clicked.connect(() => {
                    on_ok_button_clicked.begin();
                });

                ok_button_ = value;
            }
        }
    }

    public ConferenceDetailsFragment(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        account_combobox.initialize(stream_interactor);

        accounts_button.clicked.connect(() => { set_active_stack(accounts_stack); });
        jid_button.clicked.connect(() => { set_active_stack(jid_stack); });
        nick_button.clicked.connect(() => { set_active_stack(nick_stack); });
        password_button.clicked.connect(() => { set_active_stack(password_stack); });

        account_combobox.changed.connect(() => { accounts_label.label = account_combobox.selected.bare_jid.to_string(); });
        accounts_label.label = account_combobox.selected.bare_jid.to_string();
        jid_entry.key_release_event.connect(on_jid_key_release_event);
        nick_entry.key_release_event.connect(on_nick_key_release_event);
        password_entry.key_release_event.connect(on_password_key_release_event);

        jid_entry.key_release_event.connect(() => { done = true; return false; }); // just for notifying
        nick_entry.key_release_event.connect(() => { done = true; return false; });

        notification_button.clicked.connect(() => { notification_revealer.set_reveal_child(false); });

        clear();
    }

    public void clear() {
        jid = "";
        nick = "";
        password = "";
        password_text_label.visible = false;
        password_stack.visible = false;
        notification_revealer.set_reveal_child(false);
        reset_editable();
    }

    public void reset_editable() {
        jid_stack.set_visible_child_name("entry");
        accounts_stack.set_visible_child_name("entry");
        nick_stack.set_visible_child_name("entry");
        password_stack.set_visible_child_name("entry");
    }

    private async void on_ok_button_clicked() {
        if (!fragment_active) return;

        ok_button.label = _("Joining…");
        ok_button.sensitive = false;

        string label_text = "";
        try {
            Jid parsed_jid = new Jid(jid);
            Muc.JoinResult? join_result = yield stream_interactor.get_module(MucManager.IDENTITY).join(account, parsed_jid, nick, password);

            ok_button.label = _("Join");
            ok_button.sensitive = true;
            if (join_result == null || join_result.nick != null) {
                Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(parsed_jid, account, Conversation.Type.GROUPCHAT);
                Application app = GLib.Application.get_default() as Application;
                app.controller.select_conversation(conversation);
                joined();
                return;
            }

            if (join_result.muc_error != null) {
                switch (join_result.muc_error) {
                    case Muc.MucEnterError.PASSWORD_REQUIRED:
                        label_text = _("Password required to enter room");
                        password_text_label.visible = true;
                        password_stack.visible = true;
                        break;
                    case Muc.MucEnterError.BANNED:
                        label_text = _("Banned from joining or creating conference"); break;
                    case Muc.MucEnterError.ROOM_DOESNT_EXIST:
                        label_text = _("Room does not exist"); break;
                    case Muc.MucEnterError.CREATION_RESTRICTED:
                        label_text = _("Not allowed to create room"); break;
                    case Muc.MucEnterError.NOT_IN_MEMBER_LIST:
                        label_text = _("Members-only room"); break;
                    case Muc.MucEnterError.USE_RESERVED_ROOMNICK:
                    case Muc.MucEnterError.NICK_CONFLICT:
                        label_text = _("Choose a different nick"); break;
                    case Muc.MucEnterError.OCCUPANT_LIMIT_REACHED:
                        label_text = _("Too many occupants in room"); break;
                }
            } else if (join_result.stanza_error != null) {
                label_text = _("Could not connect to %s").printf((new Jid(jid)).domainpart);
            }
        } catch (InvalidJidError e) {
            label_text = _("Invalid address");
        }
        notification_label.label = label_text;
        notification_revealer.set_reveal_child(true);
    }

    private bool on_jid_key_release_event(EventKey event) {
        jid_label.label = jid_entry.text;
        if (event.keyval == Key.Return) jid_stack.set_visible_child_name("label");
        return false;
    }

    private bool on_nick_key_release_event(EventKey event) {
        nick_label.label = nick_entry.text;
        if (event.keyval == Key.Return) nick_stack.set_visible_child_name("label");
        return false;
    }

    private bool on_password_key_release_event(EventKey event) {
        string filler = "";
        for (int i = 0; i < password_entry.text.length; i++) filler += password_entry.get_invisible_char().to_string();
        password_label.label = filler;
        if (event.keyval == Key.Return) password_stack.set_visible_child_name("label");
        return false;
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
