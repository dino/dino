using Xmpp;

namespace Dino.Omemo {

    public class EncryptionListEntry : Plugins.EncryptionListEntry, Object {
        private Plugin plugin;

        public EncryptionListEntry(Plugin plugin) {
            this.plugin = plugin;
        }

        public Entities.Encryption encryption { get {
            return Entities.Encryption.OMEMO;
        }}

        public string name { get {
            return "OMEMO";
        }}

        public bool can_encrypt(Entities.Conversation conversation) {
            return Manager.get_instance(plugin.app.stream_interaction).con_encrypt(conversation);
        }
    }

    public class AccountSettingsEntry : Plugins.AccountSettingsEntry {
        private Plugin plugin;

        public AccountSettingsEntry(Plugin plugin) {
            this.plugin = plugin;
        }

        public override string id { get {
            return "omemo_identity_key";
        }}

        public override string name { get {
            return "OMEMO";
        }}

        public override Plugins.AccountSettingsWidget get_widget() {
            return new AccountSettingWidget(plugin);
        }
    }

    public class AccountSettingWidget : Plugins.AccountSettingsWidget, Gtk.Box {
        private Plugin plugin;
        private Gtk.Label fingerprint;
        private Entities.Account account;

        public AccountSettingWidget(Plugin plugin) {
            this.plugin = plugin;

            fingerprint = new Gtk.Label("...");
            fingerprint.xalign = 0;
            Gtk.Border border = new Gtk.Button().get_style_context().get_padding(Gtk.StateFlags.NORMAL);
            fingerprint.set_padding(border.left + 1, border.top + 1);
            fingerprint.visible = true;
            pack_start(fingerprint);

            Gtk.Button btn = new Gtk.Button();
            btn.image = new Gtk.Image.from_icon_name("view-list-symbolic", Gtk.IconSize.BUTTON);
            btn.relief = Gtk.ReliefStyle.NONE;
            btn.visible = true;
            btn.valign = Gtk.Align.CENTER;
            btn.clicked.connect(() => { activated(); });
            pack_start(btn, false);
        }

        public void set_account(Entities.Account account) {
            this.account = account;
            try {
                Qlite.Row? row = plugin.db.identity.row_with(plugin.db.identity.account_id, account.id);
                if (row == null) {
                    fingerprint.set_markup(@"Own fingerprint\n<span font='8'>Will be generated on first connect</span>");
                } else {
                    uint8[] arr = Base64.decode(row[plugin.db.identity.identity_key_public_base64]);
                    arr = arr[1:arr.length];
                    string res = "";
                    foreach (uint8 i in arr) {
                        string s = i.to_string("%x");
                        if (s.length == 1) s = "0" + s;
                        res = res + s;
                        if ((res.length % 9) == 8) {
                            if (res.length == 35) {
                                res += "\n";
                            } else {
                                res += " ";
                            }
                        }
                    }
                    fingerprint.set_markup(@"Own fingerprint\n<span font_family='monospace' font='8'>$res</span>");
                }
            } catch (Qlite.DatabaseError e) {
                fingerprint.set_markup(@"Own fingerprint\n<span font='8'>Database error</span>");
            }
        }

        public void deactivate() {
        }
    }

    public class Plugin : Plugins.RootInterface, Object {
        public Dino.Application app;
        public Database db;
        public EncryptionListEntry list_entry;
        public AccountSettingsEntry settings_entry;

        public void registered(Dino.Application app) {
            this.app = app;
            this.db = new Database("omemo.db");
            this.list_entry = new EncryptionListEntry(this);
            this.settings_entry = new AccountSettingsEntry(this);
            app.plugin_registry.register_encryption_list_entry(list_entry);
            app.plugin_registry.register_account_settings_entry(settings_entry);
            app.stream_interaction.module_manager.initialize_account_modules.connect((account, list) => {
                list.add(new Module());
            });
            Manager.start(app.stream_interaction, db);
        }

        public void shutdown() {
            // Nothing to do
        }
    }

}

public Type register_plugin(Module module) {
    return typeof (Dino.Omemo.Plugin);
}
