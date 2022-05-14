using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class EncryptionButton {

    public signal void encryption_changed(Plugins.EncryptionListEntry? encryption_entry);

    private MenuButton menu_button;
    private Conversation? conversation;
    private CheckButton? button_unencrypted;
    private Map<CheckButton, Plugins.EncryptionListEntry> encryption_radios = new HashMap<CheckButton, Plugins.EncryptionListEntry>();
    private string? current_icon;
    private StreamInteractor stream_interactor;
    private SimpleAction action;

    public EncryptionButton(StreamInteractor stream_interactor, MenuButton menu_button) {
        this.stream_interactor = stream_interactor;
        this.menu_button = menu_button;

        // Build menu model including "Unencrypted" and all registered encryption entries
        Menu menu_model = new Menu();

        MenuItem unencrypted_item = new MenuItem(_("Unencrypted"), "enc.encryption");
        unencrypted_item.set_action_and_target_value("enc.encryption", new Variant.int32(Encryption.NONE));
        menu_model.append_item(unencrypted_item);

        Application app = GLib.Application.get_default() as Application;
        foreach (var e in app.plugin_registry.encryption_list_entries) {
            MenuItem item = new MenuItem(e.name, "enc.encryption");
            item.set_action_and_target_value("enc.encryption", new Variant.int32(e.encryption));
            menu_model.append_item(item);
        }

        // Create action to act on menu selections (stateful => radio buttons)
        SimpleActionGroup action_group = new SimpleActionGroup();
        action = new SimpleAction.stateful("encryption", VariantType.INT32, new Variant.int32(Encryption.NONE));
        action.activate.connect((parameter) => {
            action.set_state(parameter);
            this.conversation.encryption = (Encryption) parameter.get_int32();
        });
        action_group.insert(action);
        menu_button.insert_action_group("enc", action_group);

        // Create and set popover menu
        Gtk.PopoverMenu popover_menu = new Gtk.PopoverMenu.from_model(menu_model);
        menu_button.popover = popover_menu;

        stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect((account, muc_jid) => {
            if (conversation != null && conversation.account.equals(account) && conversation.counterpart.equals(muc_jid)) {
                update_visibility();
            }
        });

        menu_button.activate.connect(update_encryption_menu_state);
    }

    private void encryption_button_toggled() {
        foreach (CheckButton e in encryption_radios.keys) {
            if (e.get_active()) {
                conversation.encryption = encryption_radios[e].encryption;
                encryption_changed(encryption_radios[e]);
                update_encryption_menu_icon();
                return;
            }
        }

        // Selected unencrypted
        conversation.encryption = Encryption.NONE;
        update_encryption_menu_icon();
        encryption_changed(null);
    }

    private void update_encryption_menu_state() {
        action.set_state(new Variant.int32(conversation.encryption));
        action.change_state(new Variant.int32(conversation.encryption));
    }

    private void set_icon(string icon) {
        if (icon != current_icon) {
            menu_button.set_icon_name(icon);
            current_icon = icon;
        }
    }

    private void update_encryption_menu_icon() {
        set_icon(conversation.encryption == Encryption.NONE ? "changes-allow-symbolic" : "changes-prevent-symbolic");
    }

    private void update_visibility() {
        if (conversation.encryption != Encryption.NONE) {
            menu_button.visible = true;
            return;
        }
        switch (conversation.type_) {
            case Conversation.Type.CHAT:
                menu_button.visible = true;
                break;
            case Conversation.Type.GROUPCHAT_PM:
                menu_button.visible = false;
                break;
            case Conversation.Type.GROUPCHAT:
                menu_button.visible = stream_interactor.get_module(MucManager.IDENTITY).is_private_room(conversation.account, conversation.counterpart);
                break;
        }
    }

    public void set_conversation(Conversation conversation) {
        this.conversation = conversation;
        update_encryption_menu_state();
        update_encryption_menu_icon();
        update_visibility();
    }
}

}