using Qlite;
using Qrencode;
using Gee;
using Xmpp;
using Dino.Entities;
using Gtk;
using Omemo;

namespace Dino.Plugins.Omemo {

public class OmemoPreferencesEntry : Plugins.EncryptionPreferencesEntry {

    OmemoPreferencesWidget widget;
    Plugin plugin;

    public OmemoPreferencesEntry(Plugin plugin) {
        this.plugin = plugin;
    }

    public override Object? get_widget(Account account, WidgetType type) {
        if (type != WidgetType.GTK4) return null;
        var widget  = new OmemoPreferencesWidget(plugin);
        widget.set_jid(account, account.bare_jid);
        return widget;
    }

    public override string id { get { return "omemo_preferences_entryption"; }}
}

[GtkTemplate (ui = "/im/dino/Dino/omemo/encryption_preferences_entry.ui")]
public class OmemoPreferencesWidget : Adw.PreferencesGroup {
    private Plugin plugin;
    private Account account;
    private Jid jid;
    private int identity_id = 0;
    private Store store;
    private Set<uint32> displayed_ids = new HashSet<uint32>();

    [GtkChild] private unowned Adw.ActionRow automatically_accept_new_row;
    [GtkChild] private Switch automatically_accept_new_switch;
    [GtkChild] private unowned Adw.ActionRow encrypt_by_default_row;
    [GtkChild] private Switch encrypt_by_default_switch;
    [GtkChild] private unowned Label new_keys_label;

    [GtkChild] private unowned Adw.PreferencesGroup keys_preferences_group;
    [GtkChild] private unowned ListBox new_keys_listbox;
    [GtkChild] private unowned Picture qrcode_picture;
    [GtkChild] private unowned Popover qrcode_popover;

    private ArrayList<Widget> keys_preferences_group_children = new ArrayList<Widget>();

    construct {
        // If we set the strings in the .ui file, they don't get translated
        encrypt_by_default_row.title = _("OMEMO by default");
        encrypt_by_default_row.subtitle = _("Enable OMEMO encryption for new conversations");
        automatically_accept_new_row.title = _("Encrypt to new devices");
        automatically_accept_new_row.subtitle = _("Automatically encrypt to new devices from this contact.");
        new_keys_label.label = _("New keys");
    }

    public OmemoPreferencesWidget(Plugin plugin) {
        this.plugin = plugin;
    }

    public void set_jid(Account account, Jid jid) {
        this.account = account;
        this.jid = jid;
        this.identity_id = plugin.db.identity.get_id(account.id);
        if (identity_id <= 0) {
            warning("OmemoPreferencesWidget missing identity_id");
            return;
        }

        automatically_accept_new_switch.set_active(plugin.db.trust.get_blind_trust(identity_id, jid.bare_jid.to_string(), true));
        automatically_accept_new_switch.state_set.connect(on_auto_accept_toggled);

        encrypt_by_default_row.visible = account.bare_jid.equals_bare(jid);
        encrypt_by_default_switch.set_active(plugin.app.settings.get_default_encryption(account) != Encryption.NONE);
        encrypt_by_default_switch.state_set.connect(on_omemo_by_default_toggled);

        Dino.Application? app = Application.get_default() as Dino.Application;
        if (app != null) {
            store = app.stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).store;
        }

        redraw_key_list();

        // Check for unknown devices
        fetch_unknown_bundles();
    }

    private void redraw_key_list() {
        // Remove current widgets
        foreach (var widget in keys_preferences_group_children) {
            keys_preferences_group.remove(widget);
        }
        keys_preferences_group_children.clear();

        // Dialog opened from the account settings menu
        // Show the fingerprint for this device separately with buttons for a qrcode and to copy
        if(jid.equals(account.bare_jid)) {
            automatically_accept_new_row.subtitle = _("New encryption keys from your other devices will be accepted automatically.");
            add_own_fingerprint();
        }

        //Show the normal devicelist
        var own_id = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.device_id];
        foreach (Row device in plugin.db.identity_meta.get_known_devices(identity_id, jid.to_string())) {
            if(jid.equals(account.bare_jid) && device[plugin.db.identity_meta.device_id] == own_id) {
                // If this is our own account, don't show this device twice (did it separately already)
                continue;
            }
            add_fingerprint(device, (TrustLevel) device[plugin.db.identity_meta.trust_level]);
        }

        //Show any new devices for which the user must decide whether to accept or reject
        foreach (Row device in plugin.db.identity_meta.get_new_devices(identity_id, jid.to_string())) {
            add_new_fingerprint(device);
        }
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
                redraw_key_list();
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

    private void add_own_fingerprint() {
        string own_b64 = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id)[plugin.db.identity.identity_key_public_base64];
        string fingerprint = fingerprint_from_base64(own_b64);

        var own_action_box = new Box(Orientation.HORIZONTAL, 6);
        var show_qrcode_button = new MenuButton() { icon_name="dino-qr-code-symbolic", valign=Align.CENTER };
        own_action_box.append(show_qrcode_button);
        var copy_button = new Button() { icon_name="edit-copy-symbolic", valign=Align.CENTER };
        copy_button.clicked.connect(() => { copy_button.get_clipboard().set_text(fingerprint); });
        own_action_box.append(copy_button);

        Adw.ActionRow action_row = new Adw.ActionRow() { use_markup = true };
        action_row.title = _("This device");
        action_row.subtitle = fingerprint_markup(fingerprint_from_base64(own_b64));
        action_row.add_suffix(own_action_box);
        add_key_row(action_row);

        // Create and set QR code popover
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

    private void add_fingerprint(Row device, TrustLevel trust) {
        string key_base64 = device[plugin.db.identity_meta.identity_key_public_base64];
        bool key_active = device[plugin.db.identity_meta.now_active];
        if (store != null) {
            try {
                Address address = new Address(jid.to_string(), device[plugin.db.identity_meta.device_id]);
                SessionRecord? session = null;
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

        if (device[plugin.db.identity_meta.now_active]) {
            Adw.ActionRow action_row = new Adw.ActionRow() { use_markup = true };
            action_row.activated.connect(() => {
                Row updated_device = plugin.db.identity_meta.get_device(device[plugin.db.identity_meta.identity_id], device[plugin.db.identity_meta.address_name], device[plugin.db.identity_meta.device_id]);
                ManageKeyDialog manage_dialog = new ManageKeyDialog(updated_device, plugin.db);
                manage_dialog.set_transient_for((Gtk.Window) get_root());
                manage_dialog.present();
                manage_dialog.response.connect((response) => {
                    update_stored_trust(response, updated_device);
                    redraw_key_list();
                });
            });
            action_row.activatable = true;
            action_row.title = account.bare_jid.equals_bare(jid) ? _("Other device") : _("Device");
            action_row.subtitle = fingerprint_markup(fingerprint_from_base64(key_base64));
            string trust_str = _("Accepted");
            switch(trust) {
                case TrustLevel.UNTRUSTED:
                    trust_str = _("Rejected");
                    break;
                case TrustLevel.VERIFIED:
                    trust_str = _("Verified");
                    break;
            }

            action_row.add_suffix(new Label(trust_str));
            add_key_row(action_row);
        }
        displayed_ids.add(device[plugin.db.identity_meta.device_id]);
    }

    private bool on_auto_accept_toggled(bool active) {
        plugin.trust_manager.set_blind_trust(account, jid, active);

        if (active) {
            int identity_id = plugin.db.identity.get_id(account.id);
            if (identity_id < 0) return false;

            foreach (Row device in plugin.db.identity_meta.get_new_devices(identity_id, jid.to_string())) {
                plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.TRUSTED);
                add_fingerprint(device, TrustLevel.TRUSTED);
            }
        }
        return false;
    }

    private bool on_omemo_by_default_toggled(bool active) {
        var encryption_value = active ? Encryption.OMEMO : Encryption.NONE;
        plugin.app.settings.set_default_encryption(account, encryption_value);
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
                automatically_accept_new_switch.set_active(false);
                break;
        }
    }

    private void add_new_fingerprint(Row device) {
        Adw.ActionRow action_row = new Adw.ActionRow() { use_markup = true };
        action_row.title = _("New device");
        action_row.subtitle = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));

        Button accept_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        accept_button.set_icon_name("check-plain-symbolic"); // using .image = sets .image-button. Together with .suggested/destructive action that breaks the button Adwaita
        accept_button.add_css_class("suggested-action");
        accept_button.tooltip_text = _("Accept key");

        Button reject_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
        reject_button.set_icon_name("action-unavailable-symbolic");
        reject_button.add_css_class("destructive-action");
        reject_button.tooltip_text = _("Reject key");

        accept_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.TRUSTED);
            add_fingerprint(device, TrustLevel.TRUSTED);
            remove_key_row(action_row);
        });

        reject_button.clicked.connect(() => {
            plugin.trust_manager.set_device_trust(account, jid, device[plugin.db.identity_meta.device_id], TrustLevel.UNTRUSTED);
            add_fingerprint(device, TrustLevel.UNTRUSTED);
            remove_key_row(action_row);
        });

        Box control_box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, hexpand = true };
        control_box.append(accept_button);
        control_box.append(reject_button);
        control_box.add_css_class("linked"); // .linked: Visually link the accept / reject buttons

        action_row.add_suffix(control_box);

        add_key_row(action_row);
        displayed_ids.add(device[plugin.db.identity_meta.device_id]);
    }

    private void add_key_row(Adw.PreferencesRow widget) {
        keys_preferences_group.add(widget);
        keys_preferences_group_children.add(widget);
    }

    private void remove_key_row(Adw.PreferencesRow widget) {
        keys_preferences_group.remove(widget);
        keys_preferences_group_children.remove(widget);
    }
}
}