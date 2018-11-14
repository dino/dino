using Gtk;
using Qlite;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/Dino/omemo/manage_key_dialog.ui")]
public class ManageKeyDialog : Gtk.Dialog {

    [GtkChild] private Stack manage_stack;

    [GtkChild] private Button cancel_button;
    [GtkChild] private Button ok_button;

    [GtkChild] private Label main_desc_label;
    [GtkChild] private ListBox main_action_list;

    [GtkChild] private Image confirm_image;
    [GtkChild] private Label confirm_title_label;
    [GtkChild] private Label confirm_desc_label;

    [GtkChild] private Label verify_label;
    [GtkChild] private Button verify_yes_button;
    [GtkChild] private Button verify_no_button;

    private Row device;
    private Database db;

    private bool return_to_main;
    private int current_response;

    public ManageKeyDialog(Row device, Database db) {
        Object(use_header_bar : 1); 

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
            confirm_image.set_from_icon_name("security-high-symbolic", IconSize.DIALOG);
            confirm_title_label.label = _("Verify key");
            confirm_desc_label.set_markup(_("Once confirmed, any future messages sent by %s using this key will be highlighted accordingly in the chat window.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
            manage_stack.set_visible_child_name("confirm");
            ok_button.sensitive = true;
            return_to_main = false;
            current_response = Database.IdentityMetaTable.TrustLevel.VERIFIED;
        });

        verify_no_button.clicked.connect(() => {
            return_to_main = false;
            confirm_image.set_from_icon_name("dialog-warning-symbolic", IconSize.DIALOG);
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
        lbl_desc.get_style_context().add_class("dim-label");

        box.add(lbl_title);
        box.add(lbl_desc);

        return box;
    }   

    private void setup_main_screen() {
        main_action_list.set_header_func((row, before_row) => {
            if (row.get_header() == null && before_row != null) {
                row.set_header(new Separator(Orientation.HORIZONTAL));
            }
        });

        ListBoxRow verify_row = new ListBoxRow() { visible = true };
        verify_row.add(make_action_box(_("Verify key fingerprint"), _("Compare this key's fingerprint with the fingerprint displayed on the contact's device.")));
        ListBoxRow reject_row = new ListBoxRow() { visible = true };
        reject_row.add(make_action_box(_("Reject key"), _("Stop accepting this key during communication with its associated contact.")));
        ListBoxRow accept_row = new ListBoxRow() {visible = true };
        accept_row.add(make_action_box(_("Accept key"), _("Start accepting this key during communication with its associated contact")));

        switch((Database.IdentityMetaTable.TrustLevel) device[db.identity_meta.trust_level]) {
            case Database.IdentityMetaTable.TrustLevel.TRUSTED:
                main_desc_label.set_markup(_("This key is currently %s.").printf("<span color='#1A63D9'>"+_("accepted")+"</span>")+" "+_("This means it can be used by %s to receive and send messages.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                main_action_list.add(verify_row);
                main_action_list.add(reject_row);
                break;
            case Database.IdentityMetaTable.TrustLevel.VERIFIED:
                main_desc_label.set_markup(_("This key is currently %s.").printf("<span color='#1A63D9'>"+_("verified")+"</span>")+" "+_("This means it can be used by %s to receive and send messages.") + " " + _("Additionally it has been verified to match the key on the contact's device.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                main_action_list.add(reject_row);
                break;
            case Database.IdentityMetaTable.TrustLevel.UNTRUSTED:
                main_desc_label.set_markup(_("This key is currently %s.").printf("<span color='#D91900'>"+_("rejected")+"</span>")+" "+_("This means it cannot be used by %s to receive messages, and any messages sent by it will be ignored.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                main_action_list.add(accept_row);
                break;
        }

        //Row clicked - go to appropriate screen
        main_action_list.row_activated.connect((row) => {
            if(row == verify_row) {
                manage_stack.set_visible_child_name("verify");
            } else if (row == reject_row) {
                confirm_image.set_from_icon_name("action-unavailable-symbolic", IconSize.DIALOG);
                confirm_title_label.label = _("Reject key");
                confirm_desc_label.set_markup(_("Once confirmed, any future messages sent by %s using this key will be ignored and none of your messages will be readable using this key.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                manage_stack.set_visible_child_name("confirm");
                ok_button.sensitive = true;
                return_to_main = true;
                current_response = Database.IdentityMetaTable.TrustLevel.UNTRUSTED;
            } else if (row == accept_row) {
                confirm_image.set_from_icon_name("emblem-ok-symbolic", IconSize.DIALOG);
                confirm_title_label.label = _("Accept key");
                confirm_desc_label.set_markup(_("Once confirmed this key will be usable by %s to receive and send messages.").printf(@"<b>$(device[db.identity_meta.address_name])</b>"));
                manage_stack.set_visible_child_name("confirm");
                ok_button.sensitive = true;
                return_to_main = true;
                current_response = Database.IdentityMetaTable.TrustLevel.TRUSTED;
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
