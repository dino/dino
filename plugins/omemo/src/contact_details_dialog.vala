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
    [GtkChild] private Label own_fingerprint;
    [GtkChild] private Box new_keys_container;
    [GtkChild] private ListBox new_keys;
    [GtkChild] private Box keys_container;
    [GtkChild] private ListBox keys;
    [GtkChild] private Switch auto_accept;
    [GtkChild] private Button copy;
    [GtkChild] private Button show_qrcode;
    [GtkChild] private Image qrcode;
    [GtkChild] private Popover qrcode_popover;

    private void set_device_trust(Row device, bool trust) {
        Database.IdentityMetaTable.TrustLevel trust_level = trust ? Database.IdentityMetaTable.TrustLevel.TRUSTED : Database.IdentityMetaTable.TrustLevel.UNTRUSTED;
        plugin.db.identity_meta.update()
                .with(plugin.db.identity_meta.identity_id, "=", account.id)
                .with(plugin.db.identity_meta.address_name, "=", device[plugin.db.identity_meta.address_name])
                .with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id])
                .set(plugin.db.identity_meta.trust_level, trust_level).perform();
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

        Box status = new Box(Gtk.Orientation.HORIZONTAL, 5) { visible = true, hexpand = true };
        Label status_lbl = new Label(null) { visible = true, hexpand = true, xalign = 0 };

        Image img = new Image() { visible = true, halign = Align.END, icon_size = IconSize.BUTTON };

        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label lbl = new Label(res)
            { use_markup=true, justify=Justification.RIGHT, visible=true, halign = Align.START, valign = Align.CENTER, hexpand = false };

        set_row(trust, device[plugin.db.identity_meta.now_active], img, status_lbl, lbl, lbr);

        box.add(lbl);
        box.add(status);

        status.add(status_lbl);
        status.add(img);

        lbr.add(box);
        keys.add(lbr);

        keys.row_activated.connect((row) => {
            if(row == lbr) {
                Row updated_device = plugin.db.identity_meta.with_address(device[plugin.db.identity_meta.identity_id], device[plugin.db.identity_meta.address_name]).with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id]).single().row().inner;
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
                set_device_trust(device, true);
                break;
            case Database.IdentityMetaTable.TrustLevel.UNTRUSTED:
                set_device_trust(device, false);
                break;
            case Database.IdentityMetaTable.TrustLevel.VERIFIED:
                plugin.db.identity_meta.update()
                    .with(plugin.db.identity_meta.identity_id, "=", account.id)
                    .with(plugin.db.identity_meta.address_name, "=", device[plugin.db.identity_meta.address_name])
                    .with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id])
                    .set(plugin.db.identity_meta.trust_level, Database.IdentityMetaTable.TrustLevel.VERIFIED).perform();
                plugin.db.trust.update().with(plugin.db.trust.identity_id, "=", account.id).with(plugin.db.trust.address_name, "=", jid.bare_jid.to_string()).set(plugin.db.trust.blind_trust, false).perform();
                auto_accept.set_active(false);
                break;
        }
    }

    private void add_new_fingerprint(Row device){
        new_keys_container.visible = true;

        ListBoxRow lbr = new ListBoxRow() { visible = true, activatable = false, hexpand = true };
        Box box = new Box(Gtk.Orientation.HORIZONTAL, 40) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14, hexpand = true };

        Box control = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, hexpand = true };

        Button yes = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        yes.image = new Image.from_icon_name("emblem-ok-symbolic", IconSize.BUTTON);
        yes.get_style_context().add_class("suggested-action");

        Button no = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        no.image = new Image.from_icon_name("action-unavailable-symbolic", IconSize.BUTTON);
        no.get_style_context().add_class("destructive-action");

        yes.clicked.connect(() => {
            set_device_trust(device, true);
            add_fingerprint(device, Database.IdentityMetaTable.TrustLevel.TRUSTED);
            new_keys.remove(lbr);
            if (new_keys.get_children().length() < 1) new_keys_container.visible = false;
        });

        no.clicked.connect(() => {
            set_device_trust(device, false);
            add_fingerprint(device, Database.IdentityMetaTable.TrustLevel.UNTRUSTED);
            new_keys.remove(lbr);
            if (new_keys.get_children().length() < 1) new_keys_container.visible = false;
        });

        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label lbl = new Label(res)
            { use_markup=true, justify=Justification.RIGHT, visible=true, halign = Align.START, valign = Align.CENTER, hexpand = false };


        box.add(lbl);

        control.add(yes);
        control.add(no);
        control.get_style_context().add_class("linked");

        box.add(control);

        lbr.add(box);
        new_keys.add(lbr);
    }

    public ContactDetailsDialog(Plugin plugin, Account account, Jid jid) {
        Object(use_header_bar : 1);
        this.plugin = plugin;
        this.account = account;
        this.jid = jid;

        (get_header_bar() as HeaderBar).set_subtitle(jid.bare_jid.to_string());


        if(jid.equals(account.bare_jid)) {
            own = true;
            own_id = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];

            own_fingerprint_container.visible = true;

            string own_b64 = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.identity_key_public_base64];
            string fingerprint = fingerprint_from_base64(own_b64);
            own_fingerprint.set_markup(fingerprint_markup(fingerprint));

            copy.clicked.connect(() => {Clipboard.get_default(get_display()).set_text(fingerprint, fingerprint.length);});

            int sid = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];
            Pixbuf pixbuf = new QRcode(@"xmpp:$(account.bare_jid)?omemo-sid-$(sid)=$(fingerprint)", 2).to_pixbuf();
            pixbuf = pixbuf.scale_simple(150, 150, InterpType.NEAREST);
            qrcode.set_from_pixbuf(pixbuf);
            show_qrcode.clicked.connect(qrcode_popover.popup);
        }

        new_keys.set_header_func((row, before_row) => {
            if (row.get_header() == null && before_row != null) {
                row.set_header(new Separator(Orientation.HORIZONTAL));
            }
        });

        keys.set_header_func((row, before_row) => {
            if (row.get_header() == null && before_row != null) {
                row.set_header(new Separator(Orientation.HORIZONTAL));
            }
        });

        foreach (Row device in plugin.db.identity_meta.with_address(account.id, jid.to_string()).with(plugin.db.identity_meta.trust_level, "=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).without_null(plugin.db.identity_meta.identity_key_public_base64)) {
            add_new_fingerprint(device);
        }

        foreach (Row device in plugin.db.identity_meta.with_address(account.id, jid.to_string()).with(plugin.db.identity_meta.trust_level, "!=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).without_null(plugin.db.identity_meta.identity_key_public_base64)) {
            if(own && device[plugin.db.identity_meta.device_id] == own_id) {
                continue;
            }
            add_fingerprint(device, (Database.IdentityMetaTable.TrustLevel) device[plugin.db.identity_meta.trust_level]);

        }

        auto_accept.set_active(plugin.db.trust.get_blind_trust(account.id, jid.bare_jid.to_string()));

        auto_accept.state_set.connect((active) => {
            plugin.db.trust.update().with(plugin.db.trust.identity_id, "=", account.id).with(plugin.db.trust.address_name, "=", jid.bare_jid.to_string()).set(plugin.db.trust.blind_trust, active).perform();

            if (active) {
                new_keys_container.visible = false;

                foreach (Row device in plugin.db.identity_meta.with_address(account.id, jid.to_string()).with(plugin.db.identity_meta.trust_level, "=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).without_null(plugin.db.identity_meta.identity_key_public_base64)) {
                    set_device_trust(device, true);
                    add_fingerprint(device, Database.IdentityMetaTable.TrustLevel.TRUSTED);
                }
            }

            return false;
        });

    }

}

}
