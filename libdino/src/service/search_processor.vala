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

    private QueryBuilder prepare_search(string query, bool join_content) {
        string words = "";
        string? with = null;
        string? in_ = null;
        string? from = null;
        foreach(string word in query.split(" ")) {
            if (word.has_prefix("with:")) {
                if (with == null) {
                    @with = word.substring(5);
                } else {
                    return db.message.select().where("0");
                }
            } else if (word.has_prefix("in:")) {
                if (in_ == null) {
                    in_ = word.substring(3);
                } else {
                    return db.message.select().where("0");
                }
            } else if (word.has_prefix("from:")) {
                if (from == null) {
                    from = word.substring(5);
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
            .outer_join_with(db.real_jid, db.real_jid.message_id, db.message.id)
            .with(db.account.enabled, "=", true);
        if (join_content) {
            rows.join_on(db.content_item, "message.id=content_item.foreign_id AND content_item.content_type=1")
                .with(db.content_item.content_type, "=", 1);
        }
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

    public Gee.List<SearchSuggestion> suggest_auto_complete(string query, int cursor_position, int limit = 5) {
        int after_prev_space = query.substring(0, cursor_position).last_index_of(" ") + 1;
        int next_space = query.index_of(" ", after_prev_space);
        if (next_space < 0) next_space = query.length;
        string current_query = query.substring(after_prev_space, next_space - after_prev_space);
        Gee.List<SearchSuggestion> suggestions = new ArrayList<SearchSuggestion>();

        if (current_query.has_prefix("from:")) {
            if (cursor_position < after_prev_space + 5) return suggestions;
            string current_from = current_query.substring(5);
            string[] splitted = query.split(" ");
            foreach(string s in splitted) {
                if (s.has_prefix("from:") && s != "from:" + current_from) {
                    // Already have an from: filter -> no useful autocompletion possible
                    return suggestions;
                }
            }
            string? current_in = null;
            string? current_with = null;
            foreach(string s in splitted) {
                if (s.has_prefix("in:")) {
                    current_in = s.substring(3);
                } else if (s.has_prefix("with:")) {
                    current_with = s.substring(5);
                }
            }
            if (current_in != null && current_with != null) {
                // in: and with: -> no useful autocompletion possible
                return suggestions;
            }
            if (current_with != null) {
                // Can only be the other one or us

                // Normal chat
                QueryBuilder chats = db.conversation.select()
                    .join_with(db.jid, db.jid.id, db.conversation.jid_id)
                    .join_with(db.account, db.account.id, db.conversation.account_id)
                    .with(db.jid.bare_jid, "=", current_with)
                    .with(db.account.enabled, "=", true)
                    .with(db.conversation.type_, "=", Conversation.Type.CHAT)
                    .order_by(db.conversation.last_active, "DESC");
                foreach(Row chat in chats) {
                    try {
                        if (suggestions.size == 0) {
                            suggestions.add(new SearchSuggestion(new Conversation.from_row(db, chat), new Jid(chat[db.jid.bare_jid]), "from:"+chat[db.jid.bare_jid], after_prev_space, next_space));
                        }
                        suggestions.add(new SearchSuggestion(new Conversation.from_row(db, chat), new Jid(chat[db.account.bare_jid]), "from:"+chat[db.account.bare_jid], after_prev_space, next_space));
                    } catch (InvalidJidError e) {
                        warning("Ignoring search suggestion with invalid Jid: %s", e.message);
                    }
                }
                return suggestions;
            }
            if (current_in != null) {
                // All members of the MUC with history
                QueryBuilder msgs = db.message.select()
                    .select_string(@"account.*, $(db.message.counterpart_resource), conversation.*")
                    .join_with(db.jid, db.jid.id, db.message.counterpart_id)
                    .join_with(db.account, db.account.id, db.message.account_id)
                    .join_on(db.conversation, @"$(db.conversation.account_id)=$(db.account.id) AND $(db.conversation.jid_id)=$(db.jid.id)")
                    .with(db.jid.bare_jid, "=", current_in)
                    .with(db.account.enabled, "=", true)
                    .with(db.message.type_, "=", Message.Type.GROUPCHAT)
                    .with(db.conversation.type_, "=", Conversation.Type.GROUPCHAT)
                    .with(db.message.counterpart_resource, "LIKE", @"%$current_from%")
                    .group_by({db.message.counterpart_resource})
                    .order_by_name(@"MAX($(db.message.time))", "DESC")
                    .limit(5);
                foreach(Row msg in msgs) {
                    try {
                        suggestions.add(new SearchSuggestion(new Conversation.from_row(db, msg), new Jid(current_in).with_resource(msg[db.message.counterpart_resource]), "from:"+msg[db.message.counterpart_resource], after_prev_space, next_space));
                    } catch (InvalidJidError e) {
                        warning("Ignoring search suggestion with invalid Jid: %s", e.message);
                    }
                }
            }
            // TODO: auto complete from
        } else if (current_query.has_prefix("with:")) {
            if (cursor_position < after_prev_space + 5) return suggestions;
            string current_with = current_query.substring(5);
            string[] splitted = query.split(" ");
            foreach(string s in splitted) {
                if ((s.has_prefix("with:") && s != "with:" + current_with) || s.has_prefix("in:")) {
                    // Already have an in: or with: filter -> no useful autocompletion possible
                    return suggestions;
                }
            }

            // Normal chat
            QueryBuilder chats = db.conversation.select()
                .join_with(db.jid, db.jid.id, db.conversation.jid_id)
                .join_with(db.account, db.account.id, db.conversation.account_id)
                .outer_join_on(db.roster, @"$(db.jid.bare_jid) = $(db.roster.jid) AND $(db.account.id) = $(db.roster.account_id)")
                .where(@"$(db.jid.bare_jid) LIKE ? OR $(db.roster.handle) LIKE ?", {@"%$current_with%", @"%$current_with%"})
                .with(db.account.enabled, "=", true)
                .with(db.conversation.type_, "=", Conversation.Type.CHAT)
                .order_by(db.conversation.last_active, "DESC")
                .limit(limit);
            foreach(Row chat in chats) {
                try {
                    suggestions.add(new SearchSuggestion(new Conversation.from_row(db, chat), new Jid(chat[db.jid.bare_jid]), "with:"+chat[db.jid.bare_jid], after_prev_space, next_space) { order = chat[db.conversation.last_active]});
                } catch (InvalidJidError e) {
                    warning("Ignoring search suggestion with invalid Jid: %s", e.message);
                }
            }

            // Groupchat PM
            if (suggestions.size < 5) {
                chats = db.conversation.select()
                    .join_with(db.jid, db.jid.id, db.conversation.jid_id)
                    .join_with(db.account, db.account.id, db.conversation.account_id)
                    .where(@"$(db.jid.bare_jid) LIKE ? OR $(db.conversation.resource) LIKE ?", {@"%$current_with%", @"%$current_with%"})
                    .with(db.account.enabled, "=", true)
                    .with(db.conversation.type_, "=", Conversation.Type.GROUPCHAT_PM)
                    .order_by(db.conversation.last_active, "DESC")
                    .limit(limit - suggestions.size);
                foreach(Row chat in chats) {
                    try {
                        suggestions.add(new SearchSuggestion(new Conversation.from_row(db, chat), new Jid(chat[db.jid.bare_jid]).with_resource(chat[db.conversation.resource]), "with:"+chat[db.jid.bare_jid]+"/"+chat[db.conversation.resource], after_prev_space, next_space) { order = chat[db.conversation.last_active]});
                    } catch (InvalidJidError e) {
                        warning("Ignoring search suggestion with invalid Jid: %s", e.message);
                    }
                }
                suggestions.sort((a, b) => (int)(b.order - a.order));
            }
        } else if (current_query.has_prefix("in:")) {
            if (cursor_position < after_prev_space + 3) return suggestions;
            string current_in = current_query.substring(3);
            string[] splitted = query.split(" ");
            foreach(string s in splitted) {
                if ((s.has_prefix("in:") && s != "in:" + current_in) || s.has_prefix("with:")) {
                    // Already have an in: or with: filter -> no useful autocompletion possible
                    return suggestions;
                }
            }
            QueryBuilder groupchats = db.conversation.select()
                .join_with(db.jid, db.jid.id, db.conversation.jid_id)
                .join_with(db.account, db.account.id, db.conversation.account_id)
                .with(db.jid.bare_jid, "LIKE", @"%$current_in%")
                .with(db.account.enabled, "=", true)
                .with(db.conversation.type_, "=", Conversation.Type.GROUPCHAT)
                .order_by(db.conversation.last_active, "DESC")
                .limit(limit);
            foreach(Row chat in groupchats) {
                try {
                    suggestions.add(new SearchSuggestion(new Conversation.from_row(db, chat), new Jid(chat[db.jid.bare_jid]), "in:"+chat[db.jid.bare_jid], after_prev_space, next_space));
                } catch (InvalidJidError e) {
                    warning("Ignoring search suggestion with invalid Jid: %s", e.message);
                }
            }
        } else {
            // Other auto complete?
        }
        return suggestions;
    }

    public Gee.List<MessageItem> match_messages(string query, int offset = -1) {
        Gee.List<MessageItem> ret = new ArrayList<MessageItem>();
        QueryBuilder rows = prepare_search(query, true).limit(10);
        if (offset > 0) {
            rows.offset(offset);
        }
        foreach (Row row in rows) {
            try {
                Message message = new Message.from_row(db, row);
                Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
                ret.add(new MessageItem(message, conversation, row[db.content_item.id]));
            } catch (InvalidJidError e) {
                warning("Ignoring search result with invalid Jid: %s", e.message);
            }
        }
        return ret;
    }

    public int count_match_messages(string query) {
        return (int)prepare_search(query, false).select({db.message.id}).count();
    }
}

public class SearchSuggestion : Object {
    public Account account { get { return conversation.account; } }
    public Conversation conversation { get; private set; }
    public Jid? jid { get; private set; }
    public string completion { get; private set; }
    public int start_index { get; private set; }
    public int end_index { get; private set; }
    public long order { get; set; }

    public SearchSuggestion(Conversation conversation, Jid? jid, string completion, int start_index, int end_index) {
        this.conversation = conversation;
        this.jid = jid;
        this.completion = completion;
        this.start_index = start_index;
        this.end_index = end_index;
    }
}

}
