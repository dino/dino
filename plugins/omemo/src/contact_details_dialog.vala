using Gtk;
using Xmpp;
using Gee;
using Qlite;
using Dino.Entities;
using Qrencode;
using Gdk;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/Dino/omemo/contact_details_dialog.ui")]
public class ContactDetailsDialog : Gtk.Dialog {

    private Plugin plugin;
    private Account account;
    private Jid jid;
    private bool own = false;
    private int own_id = 0;

    [GtkChild] private Box own_fingerprint_container;
    [GtkChild] private Label own_fingerprint_label;
    [GtkChild] private Box new_keys_container;
    [GtkChild] private ListBox new_keys_listbox;
    [GtkChild] private Box keys_container;
    [GtkChild] private ListBox keys_listbox;
    [GtkChild] private Switch auto_accept_switch;
    [GtkChild] private Button copy_button;
    [GtkChild] private Button show_qrcode_button;
    [GtkChild] private Image qrcode_image;
    [GtkChild] private Popover qrcode_popover;

    public ContactDetailsDialog(Plugin plugin, Account account, Jid jid) {
        Object(use_header_bar : 1);
        this.plugin = plugin;
        this.account = account;
        this.jid = jid;

        (get_header_bar() as HeaderBar).set_subtitle(jid.bare_jid.to_string());


         // Dialog opened from the account settings menu
         // Show the fingerprint for this device separately with buttons for a qrcode and to copy
        if(jid.equals(account.bare_jid)) {
            own = true;
            own_id = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];

            own_fingerprint_container.visible = true;

            string own_b64 = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.identity_key_public_base64];
            string fingerprint = fingerprint_from_base64(own_b64);
            own_fingerprint_label.set_markup(fingerprint_markup(fingerprint));

            copy_button.clicked.connect(() => {Clipboard.get_default(get_display()).set_text(fingerprint, fingerprint.length);});

            int sid = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];
            Pixbuf pixbuf = new QRcode(@"xmpp:$(account.bare_jid)?omemo-sid-$(sid)=$(fingerprint)", 2).to_pixbuf();
            pixbuf = pixbuf.scale_simple(150, 150, InterpType.NEAREST);
            qrcode_image.set_from_pixbuf(pixbuf);
            show_qrcode_button.clicked.connect(qrcode_popover.popup);
        }

        new_keys_listbox.set_header_func(header_function);

        keys_listbox.set_header_func(header_function);

        //Show any new devices for which the user must decide whether to accept or reject
        foreach (Row device in plugin.db.identity_meta.get_new_devices(account.id, jid.to_string())) {
            add_new_fingerprint(device);
        }

        //Show the normal devicelist
        foreach (Row device in plugin.db.identity_meta.get_known_devices(account.id, jid.to_string())) {
            if(own && device[plugin.db.identity_meta.device_id] == own_id) {
                continue;
            }
            add_fingerprint(device, (Database.IdentityMetaTable.TrustLevel) device[plugin.db.identity_meta.trust_level]);
        }

        auto_accept_switch.set_active(plugin.db.trust.get_blind_trust(account.id, jid.bare_jid.to_string()));

        auto_accept_switch.state_set.connect((active) => {
            plugin.trust_manager.set_blind_trust(account, jid, active);

            if (active) {
                new_keys_container.visible = false;

                foreach (Row device in plugin.db.identity_meta.get_new_devices(account.id, jid.to_string())) {
                    plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], Database.IdentityMetaTable.TrustLevel.TRUSTED);
                    add_fingerprint(device, Database.IdentityMetaTable.TrustLevel.TRUSTED);
                }
            }

            return false;
        });

    }

    private void header_function(ListBoxRow row, ListBoxRow? before) {
        if (row.get_header() == null && before != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private void set_row(int trust, bool now_active, Image img, Label status_lbl, Label lbl, ListBoxRow lbr){
        switch(trust) {
            case Database.IdentityMetaTable.TrustLevel.TRUSTED:
                img.icon_name = "emblem-ok-symbolic";
                status_lbl.set_markup("<span color='#1A63D9'>Accepted</span>");
                break;
            case Database.IdentityMetaTable.TrustLevel.UNTRUSTED:
                img.icon_name = "action-unavailable-symbolic";
                status_lbl.set_markup("<span color='#D91900'>Rejected</span>");
                lbl.get_style_context().add_class("dim-label");
                break;
            case Database.IdentityMetaTable.TrustLevel.VERIFIED:
                img.icon_name = "security-high-symbolic";
                status_lbl.set_markup("<span color='#1A63D9'>Verified</span>");
                break;
        }

        if (!now_active) {
            img.icon_name= "appointment-missed-symbolic";
            status_lbl.set_markup("<span color='#8b8e8f'>Unused</span>");
            lbr.activatable = false;
        }
    }

    private void add_fingerprint(Row device, Database.IdentityMetaTable.TrustLevel trust) {
        keys_container.visible = true;

        ListBoxRow lbr = new ListBoxRow() { visible = true, activatable = true, hexpand = true };
        Box box = new Box(Gtk.Orientation.HORIZONTAL, 40) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14, hexpand = true };

        Box status_box = new Box(Gtk.Orientation.HORIZONTAL, 5) { visible = true, hexpand = true };
        Label status_lbl = new Label(null) { visible = true, hexpand = true, xalign = 0 };

        Image img = new Image() { visible = true, halign = Align.END, icon_size = IconSize.BUTTON };

        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label lbl = new Label(res)
            { use_markup=true, justify=Justification.RIGHT, visible=true, halign = Align.START, valign = Align.CENTER, hexpand = false };

        set_row(trust, device[plugin.db.identity_meta.now_active], img, status_lbl, lbl, lbr);

        box.add(lbl);
        box.add(status_box);

        status_box.add(status_lbl);
        status_box.add(img);

        lbr.add(box);
        keys_listbox.add(lbr);

        //Row clicked - pull the most up to date device info from the database and show the manage window
        keys_listbox.row_activated.connect((row) => {
            if(row == lbr) {
                Row updated_device = plugin.db.identity_meta.get_device(device[plugin.db.identity_meta.identity_id], device[plugin.db.identity_meta.address_name], device[plugin.db.identity_meta.device_id]);
                ManageKeyDialog manage_dialog = new ManageKeyDialog(updated_device, plugin.db);
                manage_dialog.set_transient_for((Gtk.Window) get_toplevel());
                manage_dialog.present();
                manage_dialog.response.connect((response) => {
                    set_row(response, device[plugin.db.identity_meta.now_active], img, status_lbl, lbl, lbr);
                    update_device(response, device);
                });
            }
        });
    }

    private void update_device(int response, Row device){
        switch (response) {
            case Database.IdentityMetaTable.TrustLevel.TRUSTED:
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], Database.IdentityMetaTable.TrustLevel.TRUSTED);
                break;
            case Database.IdentityMetaTable.TrustLevel.UNTRUSTED:
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], Database.IdentityMetaTable.TrustLevel.UNTRUSTED);
                break;
            case Database.IdentityMetaTable.TrustLevel.VERIFIED:
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], Database.IdentityMetaTable.TrustLevel.VERIFIED);
                plugin.trust_manager.set_blind_trust(account, jid, false);
                auto_accept_switch.set_active(false);
                break;
        }
    }

    private void add_new_fingerprint(Row device){
        new_keys_container.visible = true;

        ListBoxRow lbr = new ListBoxRow() { visible = true, activatable = false, hexpand = true };
        Box box = new Box(Gtk.Orientation.HORIZONTAL, 40) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14, hexpand = true };

        Box control_box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, hexpand = true };

        Button yes_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        yes_button.image = new Image.from_icon_name("emblem-ok-symbolic", IconSize.BUTTON);
        yes_button.get_style_context().add_class("suggested-action");

        Button no_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        no_button.image = new Image.from_icon_name("action-unavailable-symbolic", IconSize.BUTTON);
        no_button.get_style_context().add_class("destructive-action");

        yes_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], Database.IdentityMetaTable.TrustLevel.TRUSTED);
            add_fingerprint(device, Database.IdentityMetaTable.TrustLevel.TRUSTED);
            new_keys_listbox.remove(lbr);
            if (new_keys_listbox.get_children().length() < 1) new_keys_container.visible = false;
        });

        no_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], Database.IdentityMetaTable.TrustLevel.UNTRUSTED);
            add_fingerprint(device, Database.IdentityMetaTable.TrustLevel.UNTRUSTED);
            new_keys_listbox.remove(lbr);
            if (new_keys_listbox.get_children().length() < 1) new_keys_container.visible = false;
        });

        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label lbl = new Label(res)
            { use_markup=true, justify=Justification.RIGHT, visible=true, halign = Align.START, valign = Align.CENTER, hexpand = false };


        box.add(lbl);

        control_box.add(yes_button);
        control_box.add(no_button);
        control_box.get_style_context().add_class("linked");

        box.add(control_box);

        lbr.add(box);
        new_keys_listbox.add(lbr);
    }
}

}
