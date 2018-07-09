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

    public Gee.List<Message> match_messages(string match, int offset = -1) {
        Gee.List<Message> ret = new ArrayList<Message>(Message.equals_func);
        var query = db.message
            .match(db.message.body, parse_search(match))
            .order_by(db.message.id, "DESC")
            .limit(10);
        if (offset > 0) {
            query.offset(offset);
        }
        foreach (Row row in query) {
            ret.add(new Message.from_row(db, row));
        }
        return ret;
    }

    public int count_match_messages(string match) {
        return (int)db.message.match(db.message.body, parse_search(match)).count();
    }

    private string parse_search(string search) {
        string ret = "";
        foreach(string word in search.split(" ")) {
            ret += word + "* ";
        }
        return ret;
    }
}

}
