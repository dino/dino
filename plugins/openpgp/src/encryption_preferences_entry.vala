using Adw;
using Dino.Entities;
using Gtk;

namespace Dino.Plugins.OpenPgp {

    public class PgpPreferencesEntry : Plugins.EncryptionPreferencesEntry {

        private Plugin plugin;

        public PgpPreferencesEntry(Plugin plugin) {
            this.plugin = plugin;
        }

        public override Object? get_widget(Account account, WidgetType type) {
            if (type != WidgetType.GTK4) return null;
            StringList string_list = new StringList(null);
            string_list.append(_("Querying GnuPG"));

            Adw.PreferencesGroup preferences_group = new Adw.PreferencesGroup() { title="OpenPGP" };
            populate_string_list.begin(account, preferences_group);

            return preferences_group;
        }

        public override string id { get { return "pgp_preferences_encryption"; }}

        private async void populate_string_list(Account account, Adw.PreferencesGroup preferences_group) {
            var keys = yield get_pgp_keys();

            if (keys == null) {
                preferences_group.add(new Adw.ActionRow() { title="Announce key", subtitle="Error in GnuPG" });
                return;
            }
            if (keys.size == 0) {
                preferences_group.add(new Adw.ActionRow() { title="Announce key", subtitle="No keys available. Generate one!" });
                return;
            }

            StringList string_list = new StringList(null);
#if Adw_1_4
            var drop_down = new Adw.ComboRow() { title = "Announce key" };
            drop_down.model = string_list;
            preferences_group.add(drop_down);
#else
            var view = new Adw.ActionRow() { title = "Announce key" };
            var drop_down = new DropDown(string_list, null) { valign = Align.CENTER };
            drop_down.remove_css_class("error");
            view.activatable_widget = drop_down;
            view.add_suffix(drop_down);
            preferences_group.add(view);
#endif

            string_list.append(_("Disabled"));
            for (int i = 0; i < keys.size; i++) {
                if(!keys[i].expired && !keys[i].revoked) string_list.append(@"$(keys[i].uids[0].uid)\n$(keys[i].fpr.substring(24, 16))");
                if (keys[i].fpr == plugin.db.get_account_key(account)) {
                    if(keys[i].expired || keys[i].revoked){
                        string status = keys[i].expired ? _("Key is expired!") : _("Key is revoked!");
                        string_list.append(@"$(keys[i].uids[0].uid)\n$(keys[i].fpr.substring(24, 16))\n$(status)");
                        drop_down.add_css_class("error");
                        drop_down.selected = string_list.get_n_items() - 1;
                    }
                    else{
                        drop_down.remove_css_class("error");
                        drop_down.selected = i + 1;
                    }
                }
            }

            drop_down.notify["selected"].connect(() => {
                var key_id = drop_down.selected == 0 ? "" : keys[(int)drop_down.selected - 1].fpr;
                if (drop_down.selected == 0) {
                    drop_down.remove_css_class("error");
                }
                if (drop_down.selected > 0) {
                    if(keys[(int)drop_down.selected - 1].expired || keys[(int)drop_down.selected - 1].revoked ) {
                        drop_down.add_css_class("error");
                    }
                    else {
                        drop_down.remove_css_class("error");
                    }
                }

                if (plugin.modules.has_key(account)) {
                    plugin.modules[account].set_private_key_id(key_id);
                }
                plugin.db.set_account_key(account, key_id);
            });
        }

        private static async Gee.List<GPG.Key> get_pgp_keys() {
            Gee.List<GPG.Key> keys = null;
            SourceFunc callback = get_pgp_keys.callback;
            new Thread<void*> (null, () => { // Querying GnuPG might take some time
                try {
                    keys = GPGHelper.get_keylist(null, true);
                } catch (Error e) {
                    warning(e.message);
                }
                Idle.add((owned)callback);
                return null;
            });
            yield;
            return keys;
        }
    }
}
