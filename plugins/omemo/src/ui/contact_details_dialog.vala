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

    [GtkChild] private Label automatically_accept_new_label;
    [GtkChild] private Label automatically_accept_new_descr;
    [GtkChild] private Label own_key_label;
    [GtkChild] private Label new_keys_label;
    [GtkChild] private Label associated_keys_label;
    [GtkChild] private Box own_fingerprint_container;
    [GtkChild] private Label own_fingerprint_label;
    [GtkChild] private Box new_keys_container;
    [GtkChild] private ListBox new_keys_listbox;
    [GtkChild] private Box keys_container;
    [GtkChild] private ListBox keys_listbox;
    [GtkChild] private ListBox unused_keys_listbox;
    [GtkChild] private Switch auto_accept_switch;
    [GtkChild] private Button copy_button;
    [GtkChild] private Button show_qrcode_button;
    [GtkChild] private Image qrcode_image;
    [GtkChild] private Popover qrcode_popover;

    construct {
        // If we set the strings in the .ui file, they don't get translated
        title = _("OMEMO Key Management");
        automatically_accept_new_label.label = _("Automatically accept new keys");
        automatically_accept_new_descr.label = _("When this contact adds new encryption keys to their account, automatically accept them.");
        own_key_label.label = _("Own key");
        new_keys_label.label = _("New keys");
        associated_keys_label.label = _("Associated keys");
    }

    public ContactDetailsDialog(Plugin plugin, Account account, Jid jid) {
        Object(use_header_bar : Environment.get_variable("GTK_CSD") != "0" ? 1 : 0);
        this.plugin = plugin;
        this.account = account;
        this.jid = jid;

        if (Environment.get_variable("GTK_CSD") != "0") {
            (get_header_bar() as HeaderBar).set_subtitle(jid.bare_jid.to_string());
        }

        keys_listbox.row_activated.connect(on_key_entry_clicked);
        unused_keys_listbox.row_activated.connect(on_key_entry_clicked);
        auto_accept_switch.state_set.connect(on_auto_accept_toggled);

        int identity_id = plugin.db.identity.get_id(account.id);
        if (identity_id < 0) return;

        auto_accept_switch.set_active(plugin.db.trust.get_blind_trust(identity_id, jid.bare_jid.to_string()));

        // Dialog opened from the account settings menu
        // Show the fingerprint for this device separately with buttons for a qrcode and to copy
        if(jid.equals(account.bare_jid)) {
            own = true;
            own_id = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];

            automatically_accept_new_descr.label = _("When you add new encryption keys to your account, automatically accept them.");

            own_fingerprint_container.visible = true;

            string own_b64 = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.identity_key_public_base64];
            string fingerprint = fingerprint_from_base64(own_b64);
            own_fingerprint_label.set_markup(fingerprint_markup(fingerprint));

            copy_button.clicked.connect(() => {Clipboard.get_default(get_display()).set_text(fingerprint, fingerprint.length);});

            int sid = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];
            Pixbuf qr_pixbuf = new QRcode(@"xmpp:$(account.bare_jid)?omemo-sid-$(sid)=$(fingerprint)", 2).to_pixbuf();
            qr_pixbuf = qr_pixbuf.scale_simple(150, 150, InterpType.NEAREST);

            Pixbuf pixbuf = new Pixbuf(
                qr_pixbuf.colorspace,
                qr_pixbuf.has_alpha,
                qr_pixbuf.bits_per_sample,
                170,
                170
            );
            pixbuf.fill(uint32.MAX);
            qr_pixbuf.copy_area(0, 0, 150, 150, pixbuf, 10, 10);

            qrcode_image.set_from_pixbuf(pixbuf);
            show_qrcode_button.clicked.connect(qrcode_popover.popup);
        }

        new_keys_listbox.set_header_func(header_function);

        keys_listbox.set_header_func(header_function);

        //Show any new devices for which the user must decide whether to accept or reject
        foreach (Row device in plugin.db.identity_meta.get_new_devices(identity_id, jid.to_string())) {
            add_new_fingerprint(device);
        }

        //Show the normal devicelist
        foreach (Row device in plugin.db.identity_meta.get_known_devices(identity_id, jid.to_string())) {
            if(own && device[plugin.db.identity_meta.device_id] == own_id) {
                continue;
            }
            add_fingerprint(device, (TrustLevel) device[plugin.db.identity_meta.trust_level]);
        }
    }

    private void header_function(ListBoxRow row, ListBoxRow? before) {
        if (row.get_header() == null && before != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        }
    }

    private void add_fingerprint(Row device, TrustLevel trust) {
        string key_base64 = device[plugin.db.identity_meta.identity_key_public_base64];
        bool key_active = device[plugin.db.identity_meta.now_active];
        FingerprintRow fingerprint_row = new FingerprintRow(device, key_base64, trust, key_active) { visible = true, activatable = true, hexpand = true };

        if (device[plugin.db.identity_meta.now_active]) {
            keys_container.visible = true;
            keys_listbox.add(fingerprint_row);
        } else {
            unused_keys_listbox.add(fingerprint_row);
        }
    }

    private void on_key_entry_clicked(ListBoxRow widget) {
        FingerprintRow? fingerprint_row = widget as FingerprintRow;
        if (fingerprint_row == null) return;

        Row updated_device = plugin.db.identity_meta.get_device(fingerprint_row.row[plugin.db.identity_meta.identity_id], fingerprint_row.row[plugin.db.identity_meta.address_name], fingerprint_row.row[plugin.db.identity_meta.device_id]);
        ManageKeyDialog manage_dialog = new ManageKeyDialog(updated_device, plugin.db);
        manage_dialog.set_transient_for((Gtk.Window) get_toplevel());
        manage_dialog.present();
        manage_dialog.response.connect((response) => {
            fingerprint_row.update_trust_state(response, fingerprint_row.row[plugin.db.identity_meta.now_active]);
            update_stored_trust(response, fingerprint_row.row);
        });
    }

    private bool on_auto_accept_toggled(bool active) {
        plugin.trust_manager.set_blind_trust(account, jid, active);

        if (active) {
            int identity_id = plugin.db.identity.get_id(account.id);
            if (identity_id < 0) return false;

            new_keys_container.visible = false;
            foreach (Row device in plugin.db.identity_meta.get_new_devices(identity_id, jid.to_string())) {
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.TRUSTED);
                add_fingerprint(device, TrustLevel.TRUSTED);
            }
        }
        return false;
    }

    private void update_stored_trust(int response, Row device) {
        switch (response) {
            case TrustLevel.TRUSTED:
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.TRUSTED);
                break;
            case TrustLevel.UNTRUSTED:
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.UNTRUSTED);
                break;
            case TrustLevel.VERIFIED:
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.VERIFIED);
                plugin.trust_manager.set_blind_trust(account, jid, false);
                auto_accept_switch.set_active(false);
                break;
        }
    }

    private void add_new_fingerprint(Row device) {
        new_keys_container.visible = true;

        ListBoxRow lbr = new ListBoxRow() { visible = true, activatable = false, hexpand = true };
        Box box = new Box(Gtk.Orientation.HORIZONTAL, 40) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14, hexpand = true };

        Button accept_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        accept_button.add(new Image.from_icon_name("emblem-ok-symbolic", IconSize.BUTTON) { visible=true }); // using .image = sets .image-button. Together with .suggested/destructive action that breaks the button Adwaita
        accept_button.get_style_context().add_class("suggested-action");
        accept_button.tooltip_text = _("Accept key");

        Button reject_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        reject_button.add(new Image.from_icon_name("action-unavailable-symbolic", IconSize.BUTTON) { visible=true });
        reject_button.get_style_context().add_class("destructive-action");
        reject_button.tooltip_text = _("Reject key");

        accept_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.TRUSTED);
            add_fingerprint(device, TrustLevel.TRUSTED);
            new_keys_listbox.remove(lbr);
            if (new_keys_listbox.get_children().length() < 1) new_keys_container.visible = false;
        });

        reject_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.UNTRUSTED);
            add_fingerprint(device, TrustLevel.UNTRUSTED);
            new_keys_listbox.remove(lbr);
            if (new_keys_listbox.get_children().length() < 1) new_keys_container.visible = false;
        });

        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label fingerprint_label = new Label(res) { use_markup=true, justify=Justification.RIGHT, visible=true, halign = Align.START, valign = Align.CENTER, hexpand = false };
        box.add(fingerprint_label);

        Box control_box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, hexpand = true };
        control_box.add(accept_button);
        control_box.add(reject_button);
        control_box.get_style_context().add_class("linked"); // .linked: Visually link the accept / reject buttons
        box.add(control_box);

        lbr.add(box);
        new_keys_listbox.add(lbr);
    }
}

public class FingerprintRow : ListBoxRow {

    private Image trust_image = new Image() { visible = true, halign = Align.END, icon_size = IconSize.BUTTON };
    private Label fingerprint_label = new Label("") { use_markup=true, justify=Justification.RIGHT, visible=true, halign = Align.START, valign = Align.CENTER, hexpand = false };
    private Label trust_label = new Label(null) { visible = true, hexpand = true, xalign = 0 };

    public Row row;

    construct {
        Box box = new Box(Gtk.Orientation.HORIZONTAL, 40) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14, hexpand = true };
        Box status_box = new Box(Gtk.Orientation.HORIZONTAL, 5) { visible = true, hexpand = true };

        box.add(fingerprint_label);
        box.add(status_box);

        status_box.add(trust_label);
        status_box.add(trust_image);

        this.add(box);
    }

    public FingerprintRow(Row row, string key_base64, int trust, bool now_active) {
        this.row = row;
        fingerprint_label.label = fingerprint_markup(fingerprint_from_base64(key_base64));
        update_trust_state(trust, now_active);
    }

    public void update_trust_state(int trust, bool now_active) {
        switch(trust) {
            case TrustLevel.TRUSTED:
                trust_image.icon_name = "emblem-ok-symbolic";
                trust_label.set_markup("<span color='#1A63D9'>%s</span>".printf(_("Accepted")));
                fingerprint_label.get_style_context().remove_class("dim-label");
                break;
            case TrustLevel.UNTRUSTED:
                trust_image.icon_name = "action-unavailable-symbolic";
                trust_label.set_markup("<span color='#D91900'>%s</span>".printf(_("Rejected")));
                fingerprint_label.get_style_context().add_class("dim-label");
                break;
            case TrustLevel.VERIFIED:
                trust_image.icon_name = "security-high-symbolic";
                trust_label.set_markup("<span color='#1A63D9'>%s</span>".printf(_("Verified")));
                fingerprint_label.get_style_context().remove_class("dim-label");
                break;
        }

        if (!now_active) {
            trust_image.icon_name = "appointment-missed-symbolic";
            trust_label.set_markup("<span color='#8b8e8f'>%s</span>".printf(_("Unused")));
        }
    }
}

}
