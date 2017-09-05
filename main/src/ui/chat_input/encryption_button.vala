using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class EncryptionButton : MenuButton {

    private Conversation? conversation;
    private RadioButton? button_unencrypted;
    private Map<RadioButton, Plugins.EncryptionListEntry> encryption_radios = new HashMap<RadioButton, Plugins.EncryptionListEntry>();

    public EncryptionButton() {
        relief = ReliefStyle.NONE;
        use_popover = true;
        image = new Image.from_icon_name("changes-allow-symbolic", IconSize.BUTTON);
        get_style_context().add_class("flat");

        Builder builder = new Builder.from_resource("/im/dino/menu_encryption.ui");
        popover = builder.get_object("menu_encryption") as PopoverMenu;
        Box encryption_box = builder.get_object("encryption_box") as Box;
        button_unencrypted = builder.get_object("button_unencrypted") as RadioButton;
        button_unencrypted.toggled.connect(encryption_changed);

        Application app = GLib.Application.get_default() as Application;
        foreach (var e in app.plugin_registry.encryption_list_entries) {
            RadioButton btn = new RadioButton.with_label(button_unencrypted.get_group(), e.name);
            encryption_radios[btn] = e;
            btn.toggled.connect(encryption_changed);
            btn.visible = true;
            encryption_box.pack_end(btn, false);
        }
        clicked.connect(update_encryption_menu_state);
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
        if (conversation.encryption == Encryption.NONE) {
            set_image(new Image.from_icon_name("changes-allow-symbolic", IconSize.BUTTON));
        } else {
            set_image(new Image.from_icon_name("changes-prevent-symbolic", IconSize.BUTTON));
        }
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;
        update_encryption_menu_state();
        update_encryption_menu_icon();
    }
}

}
