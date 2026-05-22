using Gee;

using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

namespace Dino {
    public class MucAffiliations {

        private Database db;

        public MucAffiliations(Database db) {
            this.db = db;
        }

        public string? get_mav_version(Account account, Jid muc_jid) {
            Qlite.RowOption version_rowopt = db.muc_affiliation_version.select()
                .with(db.muc_affiliation_version.account_id, "=", account.id)
                .with(db.muc_affiliation_version.muc_jid_id, "=", db.get_jid_id(muc_jid))
                .single()
                .row();

            return version_rowopt.is_present() ? version_rowopt.inner[db.muc_affiliation_version.version] : null;
        }

        public void clear_affiliations(Account account, Jid muc_jid) {
            db.muc_affiliation.delete()
                .with(db.muc_affiliation.account_id, "=", account.id)
                .with(db.muc_affiliation.muc_jid_id, "=", db.get_jid_id(muc_jid))
                .perform();
        }

        public void clear_mav_version(Account account, Jid muc_jid) {
            db.muc_affiliation_version.delete()
                .with(db.muc_affiliation_version.account_id, "=", account.id)
                .with(db.muc_affiliation_version.muc_jid_id, "=", db.get_jid_id(muc_jid))
                .perform();
        }

        public void update_affiliations(Account account, Jid muc_jid, HashMap<Jid, Muc.Affiliation> affiliations, string? mav_since, string? mav_until) {
            // Update version (if MUC affiliation versioning is used)
            if (mav_until != null && mav_since == null) {
                clear_affiliations(account, muc_jid);
            } else if (mav_until != null) {
                string? previous_version = get_mav_version(account, muc_jid);
                if (mav_since != previous_version) {
                    warning("Got an unexpected affiliations version 'since'. Expected %s; got %s", previous_version, mav_since);
                    clear_affiliations(account, muc_jid);
                    clear_mav_version(account, muc_jid);
                }
            }

            if (mav_until != null) {
                db.muc_affiliation_version.upsert()
                    .value(db.muc_affiliation_version.account_id, account.id, true)
                    .value(db.muc_affiliation_version.muc_jid_id, db.get_jid_id(muc_jid), true)
                    .value(db.muc_affiliation_version.version, mav_until)
                    .perform();
            }

            // Update affiliations
            foreach (Jid real_jid in affiliations.keys) {
                Muc.Affiliation affiliation = affiliations[real_jid];

                if (affiliation == Muc.Affiliation.NONE) {
                    db.muc_affiliation.delete()
                        .with(db.muc_affiliation.account_id, "=", account.id)
                        .with(db.muc_affiliation.muc_jid_id, "=", db.get_jid_id(muc_jid))
                        .with(db.muc_affiliation.real_jid_id, "=", db.get_jid_id(real_jid))
                        .perform();
                } else {
                    db.muc_affiliation.insert()
                        .value(db.muc_affiliation.account_id, account.id)
                        .value(db.muc_affiliation.muc_jid_id, db.get_jid_id(muc_jid))
                        .value(db.muc_affiliation.real_jid_id, db.get_jid_id(real_jid))
                        .value(db.muc_affiliation.affiliation, (int)affiliation)
                        .perform();
                }
            }
        }
    }
}