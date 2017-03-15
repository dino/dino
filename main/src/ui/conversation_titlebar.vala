using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/org/dino-im/conversation_titlebar.ui")]
public class ConversationTitlebar : Gtk.HeaderBar {

    [GtkChild] private MenuButton menu_button;
    [GtkChild] private MenuButton encryption_button;
    [GtkChild] private MenuButton groupchat_button;

    private RadioButton? button_unencrypted;
    private Map<RadioButton, Plugins.EncryptionListEntry> encryption_radios = new HashMap<RadioButton, Plugins.EncryptionListEntry>();

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
        foreach (RadioButton e in encryption_radios.keys) {
            e.set_sensitive(encryption_radios[e].can_encrypt(conversation));
            if (conversation.encryption == encryption_radios[e].encryption) e.set_active(true);
        }
        if (conversation.encryption == Encryption.NONE) {
            button_unencrypted.set_active(true);
        }
    }

    private void update_encryption_menu_icon() {
        encryption_button.visible = (conversation.type_ == Conversation.Type.CHAT);
        if (conversation.type_ == Conversation.Type.CHAT) {
            if (conversation.encryption == Encryption.NONE) {
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

    private void encryption_changed() {
        foreach (RadioButton e in encryption_radios.keys) {
            if (e.get_active()) {
                conversation.encryption = encryption_radios[e].encryption;
                update_encryption_menu_icon();
                return;
            }
        }
        conversation.encryption = Encryption.NONE;
        update_encryption_menu_icon();
    }

    private void create_encryption_menu() {
        Builder builder = new Builder.from_resource("/org/dino-im/menu_encryption.ui");
        PopoverMenu menu = builder.get_object("menu_encryption") as PopoverMenu;
        Box encryption_box = builder.get_object("encryption_box") as Box;
        button_unencrypted = builder.get_object("button_unencrypted") as RadioButton;
        button_unencrypted.toggled.connect(encryption_changed);
        Application app = GLib.Application.get_default() as Application;
        foreach(var e in app.plugin_registry.encryption_list_entries) {
            RadioButton btn = new RadioButton.with_label(button_unencrypted.get_group(), e.name);
            encryption_radios[btn] = e;
            btn.toggled.connect(encryption_changed);
            btn.visible = true;
            encryption_box.pack_end(btn, false);
        }
        encryption_button.clicked.connect(update_encryption_menu_state);
        encryption_button.set_use_popover(true);
        encryption_button.set_popover(menu);
        encryption_button.set_image(new Image.from_icon_name("changes-allow-symbolic", IconSize.BUTTON));
    }

    private void on_groupchat_subject_set(Account account, Jid jid, string subject) {
        if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
            update_subtitle(subject);
        }
    }
}

}