using Gtk;
using Qlite;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/Dino/omemo/manage_key_dialog.ui")]
public class ManageKeyDialog : Gtk.Dialog {

    [GtkChild] private unowned HeaderBar headerbar;
    [GtkChild] private unowned Stack manage_stack;

    [GtkChild] private unowned Button cancel_button;
    [GtkChild] private unowned Button ok_button;

    [GtkChild] private unowned Label main_desc_label;
    [GtkChild] private unowned ListBox main_action_list;

    [GtkChild] private unowned Image confirm_image;
    [GtkChild] private unowned Label confirm_title_label;
    [GtkChild] private unowned Label confirm_desc_label;

    [GtkChild] private unowned Label verify_label;
    [GtkChild] private unowned Label compare_fingerprint_label;
    [GtkChild] private unowned Button verify_yes_button;
    [GtkChild] private unowned Button verify_no_button;

    private Row device;
    private Database db;

    private bool return_to_main;
    private int current_response;

    construct {
        // If we set the strings in the .ui file, they don't get translated
        this.title = _("Manage Key");
        compare_fingerprint_label.label = _("Compare the fingerprint, character by character, with the one shown on your contact's device.");
        verify_no_button.label = _("Fingerprints differ");
        verify_yes_button.label = _("Fingerprints match");
        cancel_button.label = _("Cancel");
        ok_button.label = _("Confirm");
    }

    public ManageKeyDialog(Row device, Database db) {
        Object(use_header_bar : Environment.get_variable("GTK_CSD") != "0" ? 1 : 0);

        this.device = device;
        this.db = db;

        setup_main_screen();
        setup_verify_screen();

        cancel_button.clicked.connect(handle_cancel);
        ok_button.clicked.connect(() => {
            response(current_response);
            close();
        });

        verify_yes_button.clicked.connect(() => {
            confirm_image.set_from_icon_name("security-high-symbolic");
            confirm_title_label.label = _("Verify key");
            confirm_desc_label.set_markup(_("Future messages sent by %s from the device that uses this key will be highlighted accordingly in the chat window.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
            manage_stack.set_visible_child_name("confirm");
            ok_button.sensitive = true;
            return_to_main = false;
            current_response = TrustLevel.VERIFIED;
        });

        verify_no_button.clicked.connect(() => {
            return_to_main = false;
            confirm_image.set_from_icon_name("dialog-warning-symbolic");
            confirm_title_label.label = _("Fingerprints do not match");
            confirm_desc_label.set_markup(_("Please verify that you are comparing the correct fingerprint. If fingerprints do not match, %s's account may be compromised and you should consider rejecting this key.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
            manage_stack.set_visible_child_name("confirm");
        });
    }

    private void handle_cancel() {
        if (manage_stack.get_visible_child_name() == "main") close();

        if (manage_stack.get_visible_child_name() == "verify") {
            manage_stack.set_visible_child_name("main");
            cancel_button.label = _("Cancel");
        }

        if (manage_stack.get_visible_child_name() == "confirm") {
            if (return_to_main) {
                manage_stack.set_visible_child_name("main");
                cancel_button.label = _("Cancel");
            } else {
                manage_stack.set_visible_child_name("verify");
            }
        }

        ok_button.sensitive = false;
    }

    private Box make_action_box(string title, string desc){
        Box box = new Box(Orientation.VERTICAL, 0) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14 };
        Label lbl_title = new Label(title) { visible = true, halign = Align.START };
        Label lbl_desc = new Label(desc) { visible = true, xalign = 0, wrap = true, max_width_chars = 40 };

        Pango.AttrList title_attrs = new Pango.AttrList();
        title_attrs.insert(Pango.attr_scale_new(1.1));
        lbl_title.attributes = title_attrs;
        Pango.AttrList desc_attrs = new Pango.AttrList();
        desc_attrs.insert(Pango.attr_scale_new(0.8));
        lbl_desc.attributes = desc_attrs;
        lbl_desc.add_css_class("dim-label");

        box.append(lbl_title);
        box.append(lbl_desc);

        return box;
    }

    private void setup_main_screen() {
        main_action_list.set_header_func((row, before_row) => {
            if (row.get_header() == null && before_row != null) {
                row.set_header(new Separator(Orientation.HORIZONTAL));
            }
        });

        ListBoxRow verify_row = new ListBoxRow() { visible = true };
        verify_row.set_child(make_action_box(_("Verify key fingerprint"), _("Compare this key's fingerprint with the fingerprint displayed on the contact's device.")));
        ListBoxRow reject_row = new ListBoxRow() { visible = true };
        reject_row.set_child(make_action_box(_("Reject key"), _("Block encrypted communication with the contact's device that uses this key.")));
        ListBoxRow accept_row = new ListBoxRow() {visible = true };
        accept_row.set_child(make_action_box(_("Accept key"), _("Allow encrypted communication with the contact's device that uses this key.")));

        switch((TrustLevel) device[db.identity_meta.trust_level]) {
            case TrustLevel.TRUSTED:
                main_desc_label.set_markup(_("This key is currently %s.").printf("<span color='#1A63D9'>"+_("accepted")+"</span>")+" "+_("This means it can be used by %s to receive and send encrypted messages.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                main_action_list.append(verify_row);
                main_action_list.append(reject_row);
                break;
            case TrustLevel.VERIFIED:
                main_desc_label.set_markup(_("This key is currently %s.").printf("<span color='#1A63D9'>"+_("verified")+"</span>")+" "+_("This means it can be used by %s to receive and send encrypted messages.").printf(@"<b>$(device[db.identity_meta.address_name])</b>") + " " + _("Additionally it has been verified to match the key on the contact's device."));
                main_action_list.append(reject_row);
                break;
            case TrustLevel.UNTRUSTED:
                main_desc_label.set_markup(_("This key is currently %s.").printf("<span color='#D91900'>"+_("rejected")+"</span>")+" "+_("This means it cannot be used by %s to decipher your messages, and you won't see messages encrypted with it.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                main_action_list.append(accept_row);
                break;
        }

        //Row clicked - go to appropriate screen
        main_action_list.row_activated.connect((row) => {
            if(row == verify_row) {
                manage_stack.set_visible_child_name("verify");
            } else if (row == reject_row) {
                confirm_image.set_from_icon_name("action-unavailable-symbolic");
                confirm_title_label.label = _("Reject key");
                confirm_desc_label.set_markup(_("You won't see encrypted messages from the device of %s that uses this key. Conversely, that device won't be able to decipher your messages anymore.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                manage_stack.set_visible_child_name("confirm");
                ok_button.sensitive = true;
                return_to_main = true;
                current_response = TrustLevel.UNTRUSTED;
            } else if (row == accept_row) {
                confirm_image.set_from_icon_name("emblem-ok-symbolic");
                confirm_title_label.label = _("Accept key");
                confirm_desc_label.set_markup(_("You will be able to exchange encrypted messages with the device of %s that uses this key.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                manage_stack.set_visible_child_name("confirm");
                ok_button.sensitive = true;
                return_to_main = true;
                current_response = TrustLevel.TRUSTED;
            }
            cancel_button.label = _("Back");
        });

        manage_stack.set_visible_child_name("main");
    }

    private void setup_verify_screen() {
        verify_label.set_markup(fingerprint_markup(fingerprint_from_base64(device[db.identity_meta.identity_key_public_base64])));
    }
}

}
