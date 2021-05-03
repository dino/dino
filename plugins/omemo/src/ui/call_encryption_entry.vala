using Dino.Entities;
using Gtk;
using Qlite;
using Xmpp;

namespace Dino.Plugins.Omemo {

    public class CallEncryptionEntry : Plugins.CallEncryptionEntry, Object {
        private Database db;

        public CallEncryptionEntry(Database db) {
            this.db = db;
        }

        public Plugins.CallEncryptionWidget? get_widget(Account account, Xmpp.Xep.Jingle.ContentEncryption encryption) {
            DtlsSrtpVerificationDraft.OmemoContentEncryption? omemo_encryption = encryption as DtlsSrtpVerificationDraft.OmemoContentEncryption;
            if (omemo_encryption == null) return null;

            int identity_id = db.identity.get_id(account.id);
            Row? device = db.identity_meta.get_device(identity_id, omemo_encryption.jid.to_string(), omemo_encryption.sid);
            if (device == null) return null;
            TrustLevel trust = (TrustLevel) device[db.identity_meta.trust_level];

            return new CallEncryptionWidget(trust);
        }
    }

    public class CallEncryptionWidget : Plugins.CallEncryptionWidget, Object {

        string? title = null;
        string? icon = null;
        bool should_show_keys = false;

        public CallEncryptionWidget(TrustLevel trust) {
            if (trust == TrustLevel.VERIFIED) {
                title = "This call is <b>encrypted and verified</b> with OMEMO.";
                icon = "dino-security-high-symbolic";
                should_show_keys = false;
            } else {
                title = "This call is encrypted with OMEMO.";
                should_show_keys = true;
            }
        }

        public string? get_title() {
            return title;
        }

        public string? get_icon_name() {
            return icon;
        }

        public bool show_keys() {
            return should_show_keys;
        }
    }
}
