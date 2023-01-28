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
    private int identity_id = 0;
    private Signal.Store store;
    private Set<uint32> displayed_ids = new HashSet<uint32>();

    [GtkChild] private unowned Label automatically_accept_new_label;
    [GtkChild] private unowned Label automatically_accept_new_descr;
    [GtkChild] private unowned Label own_key_label;
    [GtkChild] private unowned Label new_keys_label;
    [GtkChild] private unowned Label associated_keys_label;
    [GtkChild] private unowned Label inactive_expander_label;

    [GtkChild] private unowned Box own_fingerprint_container;
    [GtkChild] private unowned Label own_fingerprint_label;
    [GtkChild] private unowned Box new_keys_container;
    [GtkChild] private unowned ListBox new_keys_listbox;
    [GtkChild] private unowned Box keys_container;
    [GtkChild] private unowned ListBox keys_listbox;
    [GtkChild] private unowned Expander inactive_keys_expander;
    [GtkChild] private unowned ListBox inactive_keys_listbox;
    [GtkChild] private unowned Switch auto_accept_switch;
    [GtkChild] private unowned Button copy_button;
    [GtkChild] private unowned MenuButton show_qrcode_button;
    [GtkChild] private unowned Picture qrcode_picture;
    [GtkChild] private unowned Popover qrcode_popover;

    private ArrayList<Widget> new_keys_listbox_children = new ArrayList<Widget>();

    construct {
        // If we set the strings in the .ui file, they don't get translated
        title = _("OMEMO Key Management");
        automatically_accept_new_label.label = _("Automatically accept new keys");
        automatically_accept_new_descr.label = _("New encryption keys from this contact will be accepted automatically.");
        own_key_label.label = _("Own key");
        new_keys_label.label = _("New keys");
        associated_keys_label.label = _("Associated keys");
        inactive_expander_label.label = _("Inactive keys");
    }

    public ContactDetailsDialog(Plugin plugin, Account account, Jid jid) {
        Object(use_header_bar : Environment.get_variable("GTK_CSD") != "0" ? 1 : 0);
        this.plugin = plugin;
        this.account = account;
        this.jid = jid;

        if (Environment.get_variable("GTK_CSD") != "0") {
//            ((HeaderBar) get_header_bar()).set_subtitle(jid.bare_jid.to_string());
        }

        keys_listbox.row_activated.connect(on_key_entry_clicked);
        inactive_keys_listbox.row_activated.connect(on_key_entry_clicked);
        auto_accept_switch.state_set.connect(on_auto_accept_toggled);

        identity_id = plugin.db.identity.get_id(account.id);
        if (identity_id < 0) return;
        Dino.Application? app = Application.get_default() as Dino.Application;
        if (app != null) {
            store = app.stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).store;
        }

        auto_accept_switch.set_active(plugin.db.trust.get_blind_trust(identity_id, jid.bare_jid.to_string(), true));

        // Dialog opened from the account settings menu
        // Show the fingerprint for this device separately with buttons for a qrcode and to copy
        if(jid.equals(account.bare_jid)) {
            own = true;
            own_id = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];

            automatically_accept_new_descr.label = _("New encryption keys from your other devices will be accepted automatically.");

            own_fingerprint_container.visible = true;

            string own_b64 = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.identity_key_public_base64];
            string fingerprint = fingerprint_from_base64(own_b64);
            own_fingerprint_label.set_markup(fingerprint_markup(fingerprint));

            copy_button.clicked.connect(() => { copy_button.get_clipboard().set_text(fingerprint); });

            int sid = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];
            var iri_query = @"omemo-sid-$(sid)=$(fingerprint)";
#if GLIB_2_66 && VALA_0_50
            string iri = GLib.Uri.join(UriFlags.NONE, "xmpp", null, null, 0, jid.to_string(), iri_query, null);
#else
            var iri_path_seg = escape_for_iri_path_segment(jid.to_string());
            var iri = @"xmpp:$(iri_path_seg)?$(iri_query)";
#endif

            const int QUIET_ZONE_MODULES = 4;  // MUST be at least 4
            const int MODULE_SIZE_PX = 4;  // arbitrary
            var qr_paintable = new QRcode(iri, 2)
                .to_paintable(MODULE_SIZE_PX * qrcode_picture.scale_factor);
            qrcode_picture.paintable = qr_paintable;
            qrcode_picture.margin_top = qrcode_picture.margin_end =
                    qrcode_picture.margin_bottom = qrcode_picture.margin_start = QUIET_ZONE_MODULES * MODULE_SIZE_PX;
            qrcode_popover.add_css_class("qrcode-container");

            show_qrcode_button.popover = qrcode_popover;
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

        // Check for unknown devices
        fetch_unknown_bundles();
    }

    private static string escape_for_iri_path_segment(string s) {
        // from RFC 3986, 2.2. Reserved Characters:
        string SUB_DELIMS = "!$&'()*+,;=";
        // from RFC 3986, 3.3. Path (pchar without unreserved and pct-encoded):
        string ALLOWED_RESERVED_CHARS = SUB_DELIMS + ":@";
        return GLib.Uri.escape_string(s, ALLOWED_RESERVED_CHARS, true);
    }

    private void fetch_unknown_bundles() {
        Dino.Application app = Application.get_default() as Dino.Application;
        XmppStream? stream = app.stream_interactor.get_stream(account);
        if (stream == null) return;
        StreamModule? module = stream.get_module(StreamModule.IDENTITY);
        if (module == null) return;
        module.bundle_fetched.connect_after((bundle_jid, device_id, bundle) => {
            if (bundle_jid.equals(jid) && !displayed_ids.contains(device_id)) {
                Row? device = plugin.db.identity_meta.get_device(identity_id, jid.to_string(), device_id);
                if (device == null) return;
                if (auto_accept_switch.active) {
                    add_fingerprint(device, (TrustLevel) device[plugin.db.identity_meta.trust_level]);
                } else {
                    add_new_fingerprint(device);
                }
            }
        });
        foreach (Row device in plugin.db.identity_meta.get_unknown_devices(identity_id, jid.to_string())) {
            try {
                module.fetch_bundle(stream, new Jid(device[plugin.db.identity_meta.address_name]), device[plugin.db.identity_meta.device_id], false);
            } catch (InvalidJidError e) {
                warning("Ignoring device with invalid Jid: %s", e.message);
            }
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
        if (store != null) {
            try {
                Signal.Address address = new Signal.Address(jid.to_string(), device[plugin.db.identity_meta.device_id]);
                Signal.SessionRecord? session = null;
                if (store.contains_session(address)) {
                    session = store.load_session(address);
                    string session_key_base64 = Base64.encode(session.state.remote_identity_key.serialize());
                    if (key_base64 != session_key_base64) {
                        critical("Session and database identity key mismatch!");
                        key_base64 = session_key_base64;
                    }
                }
            } catch (Error e) {
                print("Error while reading session store: %s", e.message);
            }
        }
        FingerprintRow fingerprint_row = new FingerprintRow(device, key_base64, trust, key_active) { visible = true, activatable = true, hexpand = true };

        if (device[plugin.db.identity_meta.now_active]) {
            keys_container.visible = true;
            keys_listbox.append(fingerprint_row);
        } else {
            inactive_keys_expander.visible=true;
            inactive_keys_listbox.append(fingerprint_row);
        }
        displayed_ids.add(device[plugin.db.identity_meta.device_id]);
    }

    private void on_key_entry_clicked(ListBoxRow widget) {
        FingerprintRow? fingerprint_row = widget as FingerprintRow;
        if (fingerprint_row == null) return;

        Row updated_device = plugin.db.identity_meta.get_device(fingerprint_row.row[plugin.db.identity_meta.identity_id], fingerprint_row.row[plugin.db.identity_meta.address_name], fingerprint_row.row[plugin.db.identity_meta.device_id]);
        ManageKeyDialog manage_dialog = new ManageKeyDialog(updated_device, plugin.db);
        manage_dialog.set_transient_for((Gtk.Window) get_root());
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
        accept_button.set_icon_name("emblem-ok-symbolic"); // using .image = sets .image-button. Together with .suggested/destructive action that breaks the button Adwaita
        accept_button.add_css_class("suggested-action");
        accept_button.tooltip_text = _("Accept key");

        Button reject_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        reject_button.set_icon_name("action-unavailable-symbolic");
        reject_button.add_css_class("destructive-action");
        reject_button.tooltip_text = _("Reject key");

        accept_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.TRUSTED);
            add_fingerprint(device, TrustLevel.TRUSTED);
            new_keys_listbox.remove(lbr);
            new_keys_listbox_children.remove(lbr);
            if (new_keys_listbox_children.size < 1) new_keys_container.visible = false;
        });

        reject_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.UNTRUSTED);
            add_fingerprint(device, TrustLevel.UNTRUSTED);
            new_keys_listbox.remove(lbr);
            new_keys_listbox_children.remove(lbr);
            if (new_keys_listbox_children.size < 1) new_keys_container.visible = false;
        });

        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label fingerprint_label = new Label(res) { use_markup=true, justify=Justification.RIGHT, halign = Align.START, valign = Align.CENTER, hexpand = false };
        box.append(fingerprint_label);

        Box control_box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, hexpand = true };
        control_box.append(accept_button);
        control_box.append(reject_button);
        control_box.add_css_class("linked"); // .linked: Visually link the accept / reject buttons
        box.append(control_box);

        lbr.set_child(box);
        new_keys_listbox.append(lbr);
        new_keys_listbox_children.add(lbr);
        displayed_ids.add(device[plugin.db.identity_meta.device_id]);
    }
}

public class FingerprintRow : ListBoxRow {

    private Image trust_image = new Image() { visible = true, halign = Align.END };
    private Label fingerprint_label = new Label("") { use_markup=true, justify=Justification.RIGHT, halign = Align.START, valign = Align.CENTER, hexpand = false };
    private Label trust_label = new Label(null) { visible = true, hexpand = true, xalign = 0 };

    public Row row;

    construct {
        Box box = new Box(Gtk.Orientation.HORIZONTAL, 40) { visible = true, margin_start = 20, margin_end = 20, margin_top = 14, margin_bottom = 14, hexpand = true };
        Box status_box = new Box(Gtk.Orientation.HORIZONTAL, 5) { visible = true, hexpand = true };

        box.append(fingerprint_label);
        box.append(status_box);

        status_box.append(trust_label);
        status_box.append(trust_image);

        this.set_child(box);
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
                fingerprint_label.remove_css_class("dim-label");
                break;
            case TrustLevel.UNTRUSTED:
                trust_image.icon_name = "action-unavailable-symbolic";
                trust_label.set_markup("<span color='#D91900'>%s</span>".printf(_("Rejected")));
                fingerprint_label.add_css_class("dim-label");
                break;
            case TrustLevel.VERIFIED:
                trust_image.icon_name = "security-high-symbolic";
                trust_label.set_markup("<span color='#1A63D9'>%s</span>".printf(_("Verified")));
                fingerprint_label.remove_css_class("dim-label");
                break;
        }

        if (!now_active) {
            trust_image.icon_name = "appointment-missed-symbolic";
            trust_label.set_markup("<span color='#8b8e8f'>%s</span>".printf(_("Unused")));
        }
    }
}

}
