using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/org/dino-im/conversation_titlebar.ui")]
public class ConversationTitlebar : Gtk.HeaderBar {

    [GtkChild] private MenuButton menu_button;
    [GtkChild] private MenuButton encryption_button;
    [GtkChild] private MenuButton groupchat_button;

    private RadioButton? button_unencrypted;
    private RadioButton? button_pgp;

    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    public ConversationTitlebar(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        MucManager.get_instance(stream_interactor).groupchat_subject_set.connect((account, jid, subject) => {
            Idle.add(() => { on_groupchat_subject_set(account, jid, subject); return false; });
        });
        create_conversation_menu();
        create_encryption_menu();
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;
        update_encryption_menu_state();
        update_encryption_menu_icon();
        update_groupchat_menu();
        update_title();
        update_subtitle();
    }

    private void update_encryption_menu_state() {
        string? pgp_id = PgpManager.get_instance(stream_interactor).get_key_id(conversation.account, conversation.counterpart);
        button_pgp.set_sensitive(pgp_id != null);
        switch (conversation.encryption) {
            case Conversation.Encryption.UNENCRYPTED:
                button_unencrypted.set_active(true);
                break;
            case Conversation.Encryption.PGP:
                button_pgp.set_active(true);
                break;
        }
    }

    private void update_encryption_menu_icon() {
        encryption_button.visible = (conversation.type_ == Conversation.Type.CHAT);
        if (conversation.type_ == Conversation.Type.CHAT) {
            if (conversation.encryption == Conversation.Encryption.UNENCRYPTED) {
                encryption_button.set_image(new Image.from_icon_name("changes-allow-symbolic", IconSize.BUTTON));
            } else {
                encryption_button.set_image(new Image.from_icon_name("changes-prevent-symbolic", IconSize.BUTTON));
            }
        }
    }

    private void update_groupchat_menu() {
        groupchat_button.visible = conversation.type_ == Conversation.Type.GROUPCHAT;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            groupchat_button.set_use_popover(true);
            Popover popover = new Popover(null);
            OccupantList occupant_list = new OccupantList(stream_interactor, conversation);
            popover.add(occupant_list);
            occupant_list.show_all();
            groupchat_button.set_popover(popover);
        }
    }

    private void update_title() {
        set_title(Util.get_conversation_display_name(stream_interactor, conversation));
    }

    private void update_subtitle(string? subtitle = null) {
        if (subtitle != null) {
            set_subtitle(subtitle);
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            string subject = MucManager.get_instance(stream_interactor).get_groupchat_subject(conversation.counterpart, conversation.account);
            set_subtitle(subject != "" ? subject : null);
        } else {
            set_subtitle(null);
        }
    }

    private void create_conversation_menu() {
        Builder builder = new Builder.from_resource("/org/dino-im/menu_conversation.ui");
        MenuModel menu = builder.get_object("menu_conversation") as MenuModel;
        menu_button.set_menu_model(menu);
    }

    private void create_encryption_menu() {
        Builder builder = new Builder.from_resource("/org/dino-im/menu_encryption.ui");
        PopoverMenu menu = builder.get_object("menu_encryption") as PopoverMenu;
        button_unencrypted = builder.get_object("button_unencrypted") as RadioButton;
        button_pgp = builder.get_object("button_pgp") as RadioButton;
        encryption_button.set_use_popover(true);
        encryption_button.set_popover(menu);
        encryption_button.set_image(new Image.from_icon_name("changes-allow-symbolic", IconSize.BUTTON));

        button_unencrypted.toggled.connect(() => {
            if (conversation != null) {
                if (button_unencrypted.get_active()) {
                    conversation.encryption = Conversation.Encryption.UNENCRYPTED;
                } else if (button_pgp.get_active()) {
                    conversation.encryption = Conversation.Encryption.PGP;
                }
                update_encryption_menu_icon();
            }
        });
    }

    private void on_groupchat_subject_set(Account account, Jid jid, string subject) {
        if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
            update_subtitle(subject);
        }
    }
}

}