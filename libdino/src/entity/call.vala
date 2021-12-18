using Xmpp;

namespace Dino.Entities {

    public class Call : Object {

        public const bool DIRECTION_OUTGOING = true;
        public const bool DIRECTION_INCOMING = false;

        public enum State {
            RINGING,
            ESTABLISHING,
            IN_PROGRESS,
            OTHER_DEVICE,
            ENDED,
            DECLINED,
            MISSED,
            FAILED
        }

        public int id { get; set; default=-1; }
        public Account account { get; set; }
        public Jid counterpart { get; set; } // For backwards compatibility with db version 21. Not to be used anymore.
        public Gee.List<Jid> counterparts = new Gee.ArrayList<Jid>(Jid.equals_bare_func);
        public Jid ourpart { get; set; }
        public bool direction { get; set; }
        public DateTime time { get; set; }
        public DateTime local_time { get; set; }
        public DateTime end_time { get; set; }
        public Encryption encryption { get; set; default=Encryption.NONE; }

        public State state { get; set; }

        private Database? db;

        public Call.from_row(Database db, Qlite.Row row) throws InvalidJidError {
            this.db = db;

            id = row[db.call.id];
            account = db.get_account_by_id(row[db.call.account_id]);

            string our_resource = row[db.call.our_resource];
            if (our_resource != null) {
                ourpart = account.bare_jid.with_resource(our_resource);
            } else {
                ourpart = account.bare_jid;
            }
            direction = row[db.call.direction];
            time = new DateTime.from_unix_utc(row[db.call.time]);
            local_time = new DateTime.from_unix_utc(row[db.call.local_time]);
            end_time = new DateTime.from_unix_utc(row[db.call.end_time]);
            encryption = (Encryption) row[db.call.encryption];
            state = (State) row[db.call.state];

            Qlite.QueryBuilder counterparts_select = db.call_counterpart.select().with(db.call_counterpart.call_id, "=", id);
            foreach (Qlite.Row counterparts_row in counterparts_select) {
                Jid peer = db.get_jid_by_id(counterparts_row[db.call_counterpart.jid_id]);
                if (!counterparts.contains(peer)) { // Legacy: The first peer is also in the `call` table. Don't add twice.
                    counterparts.add(peer);
                }
                if (counterpart == null) counterpart = peer;
            }

            counterpart = db.get_jid_by_id(row[db.call.counterpart_id]);
            string counterpart_resource = row[db.call.counterpart_resource];
            if (counterpart_resource != null) counterpart = counterpart.with_resource(counterpart_resource);
            if (counterparts.is_empty) {
                counterparts.add(counterpart);
                counterpart = counterpart;
            }

            notify.connect(on_update);
        }

        public void persist(Database db) {
            if (id != -1) return;

            this.db = db;
            Qlite.InsertBuilder builder = db.call.insert()
                    .value(db.call.account_id, account.id)
                    .value(db.call.our_resource, ourpart.resourcepart)
                    .value(db.call.direction, direction)
                    .value(db.call.time, (long) time.to_unix())
                    .value(db.call.local_time, (long) local_time.to_unix())
                    .value(db.call.encryption, encryption)
                    .value(db.call.state, State.ENDED); // No point in persisting states that can't survive a restart
            if (end_time != null) {
                builder.value(db.call.end_time, (long) end_time.to_unix());
            } else {
                builder.value(db.call.end_time, (long) local_time.to_unix());
            }
            if (counterpart != null) {
                builder.value(db.call.counterpart_id, db.get_jid_id(counterpart))
                    .value(db.call.counterpart_resource, counterpart.resourcepart);
            }
            id = (int) builder.perform();

            foreach (Jid peer in counterparts) {
                db.call_counterpart.insert()
                        .value(db.call_counterpart.call_id, id)
                        .value(db.call_counterpart.jid_id, db.get_jid_id(peer))
                        .value(db.call_counterpart.resource, peer.resourcepart)
                        .perform();
            }

            notify.connect(on_update);
        }

        public void add_peer(Jid peer) {
            if (counterpart == null) counterpart = peer;

            if (counterparts.contains(peer)) return;

            counterparts.add(peer);
            if (db != null) {
                db.call_counterpart.insert()
                        .value(db.call_counterpart.call_id, id)
                        .value(db.call_counterpart.jid_id, db.get_jid_id(peer))
                        .value(db.call_counterpart.resource, peer.resourcepart)
                        .perform();
            }
        }

        public bool equals(Call c) {
            return equals_func(this, c);
        }

        public static bool equals_func(Call c1, Call c2) {
            if (c1.id == c2.id) {
                return true;
            }
            return false;
        }

        public static uint hash_func(Call call) {
            return (uint)call.id;
        }

        private void on_update(Object o, ParamSpec sp) {
            Qlite.UpdateBuilder update_builder = db.call.update().with(db.call.id, "=", id);
            switch (sp.name) {
                case "counterpart":
                    update_builder.set(db.call.counterpart_id, db.get_jid_id(counterpart));
                    update_builder.set(db.call.counterpart_resource, counterpart.resourcepart); break;
                case "ourpart":
                    update_builder.set(db.call.our_resource, ourpart.resourcepart); break;
                case "direction":
                    update_builder.set(db.call.direction, direction); break;
                case "time":
                    update_builder.set(db.call.time, (long) time.to_unix()); break;
                case "local-time":
                    update_builder.set(db.call.local_time, (long) local_time.to_unix()); break;
                case "end-time":
                    update_builder.set(db.call.end_time, (long) end_time.to_unix()); break;
                case "encryption":
                    update_builder.set(db.call.encryption, encryption); break;
                case "state":
                    // No point in persisting states that can't survive a restart
                    if (state == State.RINGING || state == State.ESTABLISHING || state == State.IN_PROGRESS) return;
                    update_builder.set(db.call.state, state);
                    break;
            }
            update_builder.perform();
        }
    }
}
