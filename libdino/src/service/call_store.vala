using Xmpp;
using Gee;
using Qlite;

using Dino.Entities;

namespace Dino {

    public class CallStore : StreamInteractionModule, Object {
        public static ModuleIdentity<CallStore> IDENTITY = new ModuleIdentity<CallStore>("call_store");
        public string id { get { return IDENTITY.id; } }

        private StreamInteractor stream_interactor;
        private Database db;

        private WeakMap<int, Call> calls_by_db_id = new WeakMap<int, Call>();

        public static void start(StreamInteractor stream_interactor, Database db) {
            CallStore m = new CallStore(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        private CallStore(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;
        }

        public void add_call(Call call, Conversation conversation) {
            call.persist(db);
            cache_call(call);
        }

        public Call? get_call_by_id(int id, Conversation conversation) {
            Call? call = calls_by_db_id[id];
            if (call != null) {
                return call;
            }

            RowOption row_option = db.call.select().with(db.call.id, "=", id).row();

            return create_call_from_row_opt(row_option, conversation);
        }

        private Call? create_call_from_row_opt(RowOption row_opt, Conversation conversation) {
            if (!row_opt.is_present()) return null;

            try {
                Call call = new Call.from_row(db, row_opt.inner);
                if (conversation.type_.is_muc_semantic()) {
                    call.ourpart = conversation.counterpart.with_resource(call.ourpart.resourcepart);
                }
                cache_call(call);
                return call;
            } catch (InvalidJidError e) {
                warning("Got message with invalid Jid: %s", e.message);
            }
            return null;
        }

        private void cache_call(Call call) {
            calls_by_db_id[call.id] = call;
        }
    }
}