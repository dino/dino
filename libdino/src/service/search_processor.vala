using Gee;

using Xmpp;
using Qlite;
using Dino.Entities;

namespace Dino {

public class SearchProcessor : StreamInteractionModule, Object {
    public static ModuleIdentity<SearchProcessor> IDENTITY = new ModuleIdentity<SearchProcessor>("search_processor");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;

    public static void start(StreamInteractor stream_interactor, Database db) {
        SearchProcessor m = new SearchProcessor(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public SearchProcessor(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
    }

    private QueryBuilder prepare_search(string query) {
        string words = "";
        string? with = null;
        string? in_ = null;
        string? from = null;
        foreach(string word in query.split(" ")) {
            if (word.has_prefix("with:")) {
                if (with == null) {
                    with = word.substring(5) + "%";
                } else {
                    return db.message.select().where("0");
                }
            } else if (word.has_prefix("in:")) {
                if (in_ == null) {
                    in_ = word.substring(3) + "%";
                } else {
                    return db.message.select().where("0");
                }
            } else if (word.has_prefix("from:")) {
                if (from == null) {
                    from = word.substring(5) + "%";
                } else {
                    return db.message.select().where("0");
                }
            } else {
                words += word + "* ";
            }
        }
        if (in_ != null && with != null) {
            return db.message.select().where("0");
        }

        QueryBuilder rows = db.message
            .match(db.message.body, words)
            .order_by(db.message.id, "DESC")
            .join_with(db.jid, db.jid.id, db.message.counterpart_id)
            .join_with(db.account, db.account.id, db.message.account_id)
            .outer_join_with(db.real_jid, db.real_jid.message_id, db.message.id);
        if (with != null) {
            if (with.index_of("/") > 0) {
                rows.with(db.message.type_, "=", Message.Type.GROUPCHAT_PM)
                    .with(db.jid.bare_jid, "LIKE", with.substring(0, with.index_of("/")))
                    .with(db.message.counterpart_resource, "LIKE", with.substring(with.index_of("/") + 1));
            } else {
                rows.where(@"($(db.message.type_) = $((int)Message.Type.CHAT) AND $(db.jid.bare_jid) LIKE ?)"
                    + @" OR ($(db.message.type_) = $((int)Message.Type.GROUPCHAT_PM) AND $(db.real_jid.real_jid) LIKE ?)"
                    + @" OR ($(db.message.type_) = $((int)Message.Type.GROUPCHAT_PM) AND $(db.message.counterpart_resource) LIKE ?)", {with, with, with});
            }
        } else if (in_ != null) {
            rows.with(db.jid.bare_jid, "LIKE", in_)
                .with(db.message.type_, "=", Message.Type.GROUPCHAT);
        }
        if (from != null) {
            rows.where(@"($(db.message.direction) = 1 AND $(db.account.bare_jid) LIKE ?)"
                + @" OR ($(db.message.direction) = 1 AND $(db.message.type_) IN ($((int)Message.Type.GROUPCHAT), $((int)Message.Type.GROUPCHAT_PM)) AND $(db.message.our_resource) LIKE ?)"
                + @" OR ($(db.message.direction) = 0 AND $(db.message.type_) = $((int)Message.Type.CHAT) AND $(db.jid.bare_jid) LIKE ?)"
                + @" OR ($(db.message.direction) = 0 AND $(db.message.type_) IN ($((int)Message.Type.GROUPCHAT), $((int)Message.Type.GROUPCHAT_PM)) AND $(db.real_jid.real_jid) LIKE ?)"
                + @" OR ($(db.message.direction) = 0 AND $(db.message.type_) IN ($((int)Message.Type.GROUPCHAT), $((int)Message.Type.GROUPCHAT_PM)) AND $(db.message.counterpart_resource) LIKE ?)", {from, from, from, from, from});
        }
        return rows;
    }

    public Gee.List<Message> match_messages(string query, int offset = -1) {
        Gee.List<Message> ret = new ArrayList<Message>(Message.equals_func);
        var rows = prepare_search(query).limit(10);
        if (offset > 0) {
            rows.offset(offset);
        }
        foreach (Row row in rows) {
            ret.add(new Message.from_row(db, row));
        }
        return ret;
    }

    public int count_match_messages(string query) {
        return (int)prepare_search(query).select({db.message.id}).count();
    }
}

}
