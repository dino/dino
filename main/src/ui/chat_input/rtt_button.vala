using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class RttButton : MenuButton {

    public signal void rtt_setting_changed(Conversation.RttSetting rtt_setting);

    private Conversation? conversation;
    private RadioButton? rtt_off_button;
    public Label status_label;
    private Map<RadioButton, Conversation.RttSetting> rtt_radios = new HashMap<RadioButton, Conversation.RttSetting>();
    private string? current_icon;
    private StreamInteractor stream_interactor;

    public RttButton(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        use_popover = true;
        image = new Image.from_icon_name("dino-rtt-inactive-symbolic", IconSize.BUTTON);
        get_style_context().add_class("flat");

        Builder builder = new Builder.from_resource("/im/dino/Dino/menu_rtt.ui");
        popover = builder.get_object("menu_rtt") as PopoverMenu;
        Box rtt_box = builder.get_object("rtt_box") as Box;
        status_label = builder.get_object("rtt_button_status") as Label;
        status_label.wrap = true;
        status_label.max_width_chars = 15;
        rtt_off_button = builder.get_object("rtt_off_button") as RadioButton;
        rtt_off_button.toggled.connect(rtt_button_toggled);

        stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect((account, muc_jid) => {
            if (conversation != null && conversation.account.equals(account) && conversation.counterpart.equals(muc_jid)) {
                update_visibility();
            }
        });

        Application app = GLib.Application.get_default() as Application;
    
        RadioButton btn_bidirectional = new RadioButton.with_label(rtt_off_button.get_group(), _("Send and Receive"));
        rtt_radios[btn_bidirectional] = Conversation.RttSetting.BIDIRECTIONAL;
        btn_bidirectional.toggled.connect(rtt_button_toggled);
        btn_bidirectional.visible = true;
        rtt_box.pack_end(btn_bidirectional, false);

        RadioButton btn_receive = new RadioButton.with_label(rtt_off_button.get_group(), _("Receive only")); 
        rtt_radios[btn_receive] = Conversation.RttSetting.RECEIVE;
        btn_receive.toggled.connect(rtt_button_toggled);
        btn_receive.visible = true;
        rtt_box.pack_end(btn_receive, false);

        clicked.connect(update_rtt_menu_state);
            
    }

    private void rtt_button_toggled() {
        foreach (RadioButton e in rtt_radios.keys) {
            if (e.get_active()) {
                conversation.rtt_setting = rtt_radios[e];
                rtt_setting_changed(rtt_radios[e]);
                update_rtt_menu_icon();
                return;
            }
        }

        // Selected off
        conversation.rtt_setting = Conversation.RttSetting.OFF;
        update_rtt_menu_icon();
        rtt_setting_changed(Conversation.RttSetting.OFF);
    }

    public void update_rtt_menu_state() {
        foreach (RadioButton e in rtt_radios.keys) {
            if (conversation.rtt_setting == rtt_radios[e]) {
                e.set_active(true);
            }
        }
        if (conversation.rtt_setting == Conversation.RttSetting.OFF) {
            rtt_off_button.set_active(true);
        }
    }

    private void set_icon(string icon) {
        if (icon != current_icon) {
            image = new Image.from_icon_name(icon, IconSize.BUTTON);
            current_icon = icon;
        }
    }

    private void update_rtt_menu_icon() {
        set_icon(conversation.rtt_setting == Conversation.RttSetting.OFF ? "dino-rtt-inactive-symbolic" : "dino-rtt-active-symbolic");
    }

    private void update_visibility() {
        if (conversation.type_ == Conversation.Type.CHAT) visible = true;
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;
        update_rtt_menu_state();
        update_rtt_menu_icon();
        update_visibility();
    }
}

}
