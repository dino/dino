using Gtk;
using Xmpp;
using Gee;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/Dino/omemo/contact_details_dialog.ui")]
public class ContactDetailsDialog : Gtk.Dialog {

    private Plugin plugin;
    private Account account;
    private Jid jid;

    private Gee.List<Widget> toggles;

    [GtkChild] private Grid fingerprints;
    [GtkChild] private Box fingerprints_prompt_label;
    [GtkChild] private Frame fingerprints_prompt_container;
    [GtkChild] private Grid fingerprints_prompt;
    [GtkChild] private Box fingerprints_verified_label;
    [GtkChild] private Frame fingerprints_verified_container;
    [GtkChild] private Grid fingerprints_verified;
    [GtkChild] private Switch key_mgmnt;


    private void set_device_trust(Row device, bool trust) {
        Database.IdentityMetaTable.TrustLevel trust_level = trust ? Database.IdentityMetaTable.TrustLevel.TRUSTED : Database.IdentityMetaTable.TrustLevel.UNTRUSTED;
        plugin.db.identity_meta.update()
                .with(plugin.db.identity_meta.identity_id, "=", account.id)
                .with(plugin.db.identity_meta.address_name, "=", device[plugin.db.identity_meta.address_name])
                .with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id])
                .set(plugin.db.identity_meta.trusted_identity, trust_level).perform();

        if(!trust) {
            plugin.app.stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).untrust_device(jid, device[plugin.db.identity_meta.device_id]);
        } else {
            plugin.app.stream_interactor.module_manager.get_module(account, StreamModule.IDENTITY).trust_device(jid, device[plugin.db.identity_meta.device_id]);
        }
    }

    private void add_fingerprint(Row device, int row, Database.IdentityMetaTable.TrustLevel trust) {
        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label lbl = new Label(res)
            { use_markup=true, justify=Justification.RIGHT, visible=true, margin = 8, halign = Align.START, valign = Align.CENTER };
        //TODO: handle display of verified devices
        Switch tgl = new Switch() {visible = true, halign = Align.END, valign = Align.CENTER, margin = 8, hexpand = true, active = (trust == Database.IdentityMetaTable.TrustLevel.TRUSTED) };
        tgl.state_set.connect((active) => {
            set_device_trust(device, active);

            return false;
        });
        toggles.add(tgl);

        fingerprints.attach(lbl, 0, row);
        fingerprints.attach(tgl, 1, row);
    }

    public ContactDetailsDialog(Plugin plugin, Account account, Jid jid) {
        Object(use_header_bar : 1);
        this.plugin = plugin;
        this.account = account;
        this.jid = jid;

        toggles = new ArrayList<Widget>();

        int i = 0;
        foreach (Row device in plugin.db.identity_meta.with_address(account.id, jid.to_string()).with(plugin.db.identity_meta.trusted_identity, "!=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).with(plugin.db.identity_meta.trusted_identity, "!=", Database.IdentityMetaTable.TrustLevel.VERIFIED)) {
            if (device[plugin.db.identity_meta.identity_key_public_base64] == null) {
                continue;
            }
            add_fingerprint(device, i, (Database.IdentityMetaTable.TrustLevel) device[plugin.db.identity_meta.trusted_identity]);

            i++;

        }

        int j = 0;
        foreach (Row device in plugin.db.identity_meta.with_address(account.id, jid.to_string()).with(plugin.db.identity_meta.trusted_identity, "=", Database.IdentityMetaTable.TrustLevel.UNKNOWN)) {
            if (device[plugin.db.identity_meta.identity_key_public_base64] == null) {
                continue;
            }

            string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
            Label lbl = new Label(res)
                { use_markup=true, justify=Justification.RIGHT, visible=true, margin = 8, halign = Align.START };

            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, valign = Align.CENTER, hexpand = true, margin = 8 };

            Button yes = new Button() { visible = true, valign = Align.CENTER, hexpand = true};
            yes.image = new Image.from_icon_name("list-add-symbolic", IconSize.BUTTON);

            yes.clicked.connect(() => {
                set_device_trust(device, true);
                
                fingerprints_prompt.remove(box);
                fingerprints_prompt.remove(lbl);
                toggles.remove(box);
                j--;

                add_fingerprint(device, i, Database.IdentityMetaTable.TrustLevel.TRUSTED);
                i++;

                if (j == 0) {
                    fingerprints_prompt.attach(new Label("No more new devices") { visible = true, valign = Align.CENTER, halign = Align.CENTER, margin = 8, hexpand = true }, 0, 0);
                }
            });

            Button no = new Button() { visible = true, valign = Align.CENTER, hexpand = true};
            no.image = new Image.from_icon_name("list-remove-symbolic", IconSize.BUTTON);

            no.clicked.connect(() => {
                set_device_trust(device, false);

                fingerprints_prompt.remove(box);
                fingerprints_prompt.remove(lbl);
                toggles.remove(box);
                j--;

                add_fingerprint(device, i, Database.IdentityMetaTable.TrustLevel.UNTRUSTED);
                i++;

                if (j == 0) {
                    fingerprints_prompt.attach(new Label("No more new devices") { visible = true, valign = Align.CENTER, halign = Align.CENTER, margin = 8, hexpand = true }, 0, 0);
                }
            });

            box.pack_start(yes);
            box.pack_start(no);

            box.get_style_context().add_class("linked");
            toggles.add(box);

            fingerprints_prompt.attach(lbl, 0, j);
            fingerprints_prompt.attach(box, 1, j);
            j++;
        }
        if( j > 0 ){
            fingerprints_prompt_label.visible = true;
            fingerprints_prompt_container.visible = true;
        }

        int k = 0;
        foreach (Row device in plugin.db.identity_meta.with_address(account.id, jid.to_string()).without_null(plugin.db.identity_meta.identity_key_public_base64).with(plugin.db.identity_meta.trusted_identity, "=", Database.IdentityMetaTable.TrustLevel.VERIFIED)) {
            string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
            Label lbl = new Label(res)
                { use_markup=true, justify=Justification.RIGHT, visible=true, margin = 8, halign = Align.START };

            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, valign = Align.CENTER, hexpand = true, margin = 8 };

            Button no = new Button() { visible = true, valign = Align.CENTER, halign = Align.END, hexpand = false };
            no.image = new Image.from_icon_name("list-remove-symbolic", IconSize.BUTTON);

            no.clicked.connect(() => {
                set_device_trust(device, false);

                fingerprints_verified.remove(no);
                fingerprints_verified.remove(lbl);
                toggles.remove(no);
                k--;

                add_fingerprint(device, i, Database.IdentityMetaTable.TrustLevel.UNTRUSTED);
                i++;

                if (k == 0) {
                    fingerprints_verified.attach(new Label("No more new devices") { visible = true, valign = Align.CENTER, halign = Align.CENTER, margin = 8, hexpand = true }, 0, 0);
                }
            });

            box.pack_end(no);
            toggles.add(no);

            fingerprints_verified.attach(lbl, 0, k);
            fingerprints_verified.attach(box, 1, k);
            k++;
        }

        if( k > 0 ){
            fingerprints_verified_label.visible = true;
            fingerprints_verified_container.visible = true;
        }

        bool blind_trust = plugin.db.trust.get_blind_trust(account.id, jid.bare_jid.to_string());
        key_mgmnt.set_active(!blind_trust);
        foreach(Widget tgl in toggles){
            tgl.set_sensitive(!blind_trust);
        }

        key_mgmnt.state_set.connect((active) => {
            plugin.db.trust.update().with(plugin.db.trust.identity_id, "=", account.id).with(plugin.db.trust.address_name, "=", jid.bare_jid.to_string()).set(plugin.db.trust.blind_trust, !active).perform();
            foreach(Widget tgl in toggles){
                tgl.set_sensitive(active);
            }

            return false;
        });

    }

}

}
