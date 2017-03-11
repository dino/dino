using Gee;
using Xmpp;

using Xmpp;
using Dino.Entities;

namespace Dino {
    public class PgpManager : StreamInteractionModule, Object {
        public const string id = "pgp_manager";

        public const string MESSAGE_ENCRYPTED = "pgp";

        private StreamInteractor stream_interactor;
        private Database db;
        private HashMap<Jid, string> pgp_key_ids = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);

        public static void start(StreamInteractor stream_interactor, Database db) {
            PgpManager m = new PgpManager(stream_interactor, db);
            stream_interactor.add_module(m);

            Plugins.Registry plugin_registry = (GLib.Application.get_default() as Application).plugin_registry;
            plugin_registry.register_encryption_list_entry(new EncryptionListEntry(m));
            plugin_registry.register_account_settings_entry(new AccountSettingsEntry(m));
        }

        private class AccountSettingsEntry : Plugins.AccountSettingsEntry {
            private PgpManager pgp_manager;

            public AccountSettingsEntry(PgpManager pgp_manager) {
                this.pgp_manager = pgp_manager;
            }

            public override string id { get {
                return "pgp_key_picker";
            }}

            public override string name { get {
                return "OpenPGP";
            }}

            public override Plugins.AccountSettingsWidget get_widget() {
                return new AccountSettingsWidget();
            }
        }

        [GtkTemplate (ui = "/org/dino-im/manage_accounts/pgp_stack.ui")]
        private class AccountSettingsWidget : Gtk.Stack, Plugins.AccountSettingsWidget {
            [GtkChild] private Gtk.Label pgp_label;
            [GtkChild] private Gtk.Button pgp_button;
            [GtkChild] private Gtk.ComboBox pgp_combobox;

            private Gtk.ListStore list_store = new Gtk.ListStore(2, typeof(string), typeof(string?));

            public AccountSettingsWidget() {
                Gtk.CellRendererText renderer = new Gtk.CellRendererText();
                renderer.set_padding(0, 0);
                pgp_combobox.pack_start(renderer, true);
                pgp_combobox.add_attribute(renderer, "markup", 0);
                pgp_button.clicked.connect(() => { activated(); this.set_visible_child_name("entry"); pgp_combobox.popup(); });
            }

            public void deactivate() {
                this.set_visible_child_name("label");
            }

            private void key_changed() {
                Gtk.TreeIter selected;
                pgp_combobox.get_active_iter(out selected);
                Value text;
                list_store.get_value(selected, 0, out text);
                pgp_label.set_markup((string) text);
                deactivate();
            }

            public void set_account(Account account) {
                populate_pgp_combobox(account);
            }

            private void populate_pgp_combobox(Account account) {
                pgp_combobox.changed.disconnect(key_changed);

                Gtk.TreeIter iter;
                pgp_combobox.set_model(list_store);

                list_store.clear();
                list_store.append(out iter);
                pgp_label.set_markup("Disabled\n<span font='9'>Select key</span>");
                list_store.set(iter, 0, "Disabled\n<span font='9'>Select key</span>", 1, null);
                Gee.List<GPG.Key> list = GPGHelper.get_keylist(null, true);
                foreach (GPG.Key key in list) {
                    list_store.append(out iter);
                    list_store.set(iter, 0, @"<span font='11'>$(Markup.escape_text(key.uids[0].uid))</span>\n<span font='9'>0x$(Markup.escape_text(key.fpr[0:16]))</span>");
                    list_store.set(iter, 1, key.fpr);
                }

                pgp_combobox.set_active(0);
                pgp_combobox.changed.connect(key_changed);
            }
        }

        private class EncryptionListEntry : Plugins.EncryptionListEntry, Object {
            private PgpManager pgp_manager;

            public EncryptionListEntry(PgpManager pgp_manager) {
                this.pgp_manager = pgp_manager;
            }

            public Entities.Encryption encryption { get {
                return Encryption.PGP;
            }}

            public string name { get {
                return "OpenPGP";
            }}

            public bool can_encrypt(Entities.Conversation conversation) {
                return pgp_manager.pgp_key_ids.has_key(conversation.counterpart);
            }
        }

        private PgpManager(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;

            stream_interactor.account_added.connect(on_account_added);
            MessageManager.get_instance(stream_interactor).pre_message_received.connect(on_pre_message_received);
            MessageManager.get_instance(stream_interactor).pre_message_send.connect(on_pre_message_send);
        }

        private void on_pre_message_received(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
            if (Xep.Pgp.MessageFlag.get_flag(message_stanza) != null && Xep.Pgp.MessageFlag.get_flag(message_stanza).decrypted) {
                message.encryption = Encryption.PGP;
            }
        }

        private void on_pre_message_send(Entities.Message message, Xmpp.Message.Stanza message_stanza, Conversation conversation) {
            if (message.encryption == Encryption.PGP) {
                string? key_id = get_key_id(conversation.account, message.counterpart);
                bool encrypted = false;
                if (key_id != null) {
                    encrypted = stream_interactor.get_stream(conversation.account).get_module(Xep.Pgp.Module.IDENTITY).encrypt(message_stanza, key_id);
                }
                if (!encrypted) {
                    message.marked = Entities.Message.Marked.WONTSEND;
                }
            }
        }

        public string? get_key_id(Account account, Jid jid) {
            return db.get_pgp_key(jid);
        }

        public static PgpManager? get_instance(StreamInteractor stream_interactor) {
            return (PgpManager) stream_interactor.get_module(id);
        }

        internal string get_id() {
            return id;
        }

        private void on_account_added(Account account) {
            stream_interactor.module_manager.get_module(account, Xep.Pgp.Module.IDENTITY).received_jid_key_id.connect((stream, jid, key_id) => {
                on_jid_key_received(account, new Jid(jid), key_id);
            });
        }

        private void on_jid_key_received(Account account, Jid jid, string key_id) {
            if (!pgp_key_ids.has_key(jid) || pgp_key_ids[jid] != key_id) {
                if (!MucManager.get_instance(stream_interactor).is_groupchat_occupant(jid, account)) {
                    db.set_pgp_key(jid.bare_jid, key_id);
                }
            }
            pgp_key_ids[jid] = key_id;
        }
    }
}