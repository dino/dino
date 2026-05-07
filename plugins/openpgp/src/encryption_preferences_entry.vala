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
                preferences_group.add(new Adw.ActionRow() { title=_("Announce key"), subtitle=_("Error in GnuPG") });
                return;
            }
            if (keys.size == 0) {
                preferences_group.add(new Adw.ActionRow() { title=_("Announce key"), subtitle= _("No keys available. Generate one!") });
                return;
            }

            StringList string_list = new StringList(null);
            var drop_down = new Adw.ComboRow() { title = _("Announce key") };
            drop_down.model = string_list;
            preferences_group.add(drop_down);

            string_list.append(_("Disabled"));

            // Cleanup revoked or expired keys, except if linked to an account
            for (int i = 0; i < keys.size; i++) {
                if (keys[i].revoked || keys[i].expired){
                    if (keys[i].fpr != plugin.db.get_account_key(account)) keys.remove(keys[i]);
                }
            }

            for (int i = 0; i < keys.size; i++) {
                var key_status="";
                if (keys[i].revoked) key_status = _("\nKey is revoked!");
                if (keys[i].expired) key_status = _("\nKey is expired!");
                string_list.append(@"$(keys[i].uids[0].uid)\n$(keys[i].fpr.substring(24, 16))$(key_status)");
                if (keys[i].fpr == plugin.db.get_account_key(account)) {
                    drop_down.selected = i + 1;
                    if (keys[i].expired || keys[i].revoked) drop_down.add_css_class("error");
                }
            }

            drop_down.notify["selected"].connect(() => {
                var key_id = drop_down.selected == 0 ? "" : keys[(int)drop_down.selected - 1].fpr;
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