using Gee;
using Qlite;
using Xmpp;

using Dino.Entities;

namespace Dino {

public class Database : Qlite.Database {
    private const int VERSION = 15;

    public class AccountTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> bare_jid = new Column.Text("bare_jid") { unique = true, not_null = true };
        public Column<string> resourcepart = new Column.Text("resourcepart");
        public Column<string> password = new Column.Text("password");
        public Column<string> alias = new Column.Text("alias");
        public Column<bool> enabled = new Column.BoolInt("enabled");
        public Column<string> roster_version = new Column.Text("roster_version") { min_version=2 };
        public Column<long> mam_earliest_synced = new Column.Long("mam_earliest_synced") { min_version=4 };

        internal AccountTable(Database db) {
            base(db, "account");
            init({id, bare_jid, resourcepart, password, alias, enabled, roster_version, mam_earliest_synced});
        }
    }

    public class JidTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> bare_jid = new Column.Text("bare_jid") { unique = true, not_null = true };

        internal JidTable(Database db) {
            base(db, "jid");
            init({id, bare_jid});
        }
    }

    public class EntityTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id");
        public Column<int> jid_id = new Column.Integer("jid_id");
        public Column<string> resource = new Column.Text("resource");
        public Column<string> caps_hash = new Column.Text("caps_hash");
        public Column<long> last_seen = new Column.Long("last_seen");

        internal EntityTable(Database db) {
            base(db, "entity");
            init({id, account_id, jid_id, resource, caps_hash, last_seen});
            unique({account_id, jid_id, resource}, "IGNORE");
        }
    }

    public class ContentItemTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> conversation_id = new Column.Integer("conversation_id") { not_null = true };
        public Column<long> time = new Column.Long("time") { not_null = true };
        public Column<long> local_time = new Column.Long("local_time") { not_null = true };
        public Column<int> content_type = new Column.Integer("content_type") { not_null = true };
        public Column<int> foreign_id = new Column.Integer("foreign_id") { not_null = true };
        public Column<bool> hide = new Column.BoolInt("hide") { default = "0", not_null = true, min_version = 9 };

        internal ContentItemTable(Database db) {
            base(db, "content_item");
            init({id, conversation_id, time, local_time, content_type, foreign_id, hide});
            index("contentitem_localtime_counterpart_idx", {local_time, conversation_id});
            unique({content_type, foreign_id}, "IGNORE");
        }
    }

    public class MessageTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> stanza_id = new Column.Text("stanza_id");
        public Column<string> server_id = new Column.Text("server_id") { min_version=10 };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> counterpart_id = new Column.Integer("counterpart_id") { not_null = true };
        public Column<string> counterpart_resource = new Column.Text("counterpart_resource");
        public Column<string> our_resource = new Column.Text("our_resource");
        public Column<bool> direction = new Column.BoolInt("direction") { not_null = true };
        public Column<int> type_ = new Column.Integer("type");
        public Column<long> time = new Column.Long("time");
        public Column<long> local_time = new Column.Long("local_time");
        public Column<string> body = new Column.Text("body");
        public Column<int> encryption = new Column.Integer("encryption");
        public Column<int> marked = new Column.Integer("marked");

        internal MessageTable(Database db) {
            base(db, "message");
            init({id, stanza_id, server_id, account_id, counterpart_id, our_resource, counterpart_resource, direction,
                type_, time, local_time, body, encryption, marked});

            // get latest messages
            index("message_account_counterpart_localtime_idx", {account_id, counterpart_id, local_time});

            // deduplication
            index("message_account_counterpart_stanzaid_idx", {account_id, counterpart_id, stanza_id});
            fts({body});
        }
    }

    public class MessageCorrectionTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> message_id = new Column.Integer("message_id") { unique=true };
        public Column<string> to_stanza_id = new Column.Text("to_stanza_id");

        internal MessageCorrectionTable(Database db) {
            base(db, "message_correction");
            init({id, message_id, to_stanza_id});
            index("message_correction_to_stanza_id_idx", {to_stanza_id});
        }
    }

    public class RealJidTable : Table {
        public Column<int> message_id = new Column.Integer("message_id") { primary_key = true };
        public Column<string> real_jid = new Column.Text("real_jid");

        internal RealJidTable(Database db) {
            base(db, "real_jid");
            init({message_id, real_jid});
        }
    }

    public class UndecryptedTable : Table {
        public Column<int> message_id = new Column.Integer("message_id");
        public Column<int> type_ = new Column.Integer("type");
        public Column<string> data = new Column.Text("data");

        internal UndecryptedTable(Database db) {
            base(db, "undecrypted");
            init({message_id, type_, data});
        }
    }

    public class FileTransferTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> counterpart_id = new Column.Integer("counterpart_id") { not_null = true };
        public Column<string> counterpart_resource = new Column.Text("counterpart_resource");
        public Column<string> our_resource = new Column.Text("our_resource");
        public Column<bool> direction = new Column.BoolInt("direction") { not_null = true };
        public Column<long> time = new Column.Long("time");
        public Column<long> local_time = new Column.Long("local_time");
        public Column<int> encryption = new Column.Integer("encryption");
        public Column<string> file_name = new Column.Text("file_name");
        public Column<string> path = new Column.Text("path");
        public Column<string> mime_type = new Column.Text("mime_type");
        public Column<int> size = new Column.Integer("size");
        public Column<int> state = new Column.Integer("state");
        public Column<int> provider = new Column.Integer("provider");
        public Column<string> info = new Column.Text("info");

        internal FileTransferTable(Database db) {
            base(db, "file_transfer");
            init({id, account_id, counterpart_id, counterpart_resource, our_resource, direction, time, local_time,
                    encryption, file_name, path, mime_type, size, state, provider, info});
            index("filetransfer_localtime_counterpart_idx", {local_time, counterpart_id});
        }
    }

    public class ConversationTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> jid_id = new Column.Integer("jid_id") { not_null = true };
        public Column<string> resource = new Column.Text("resource") { min_version=1 };
        public Column<bool> active = new Column.BoolInt("active");
        public Column<long> last_active = new Column.Long("last_active");
        public Column<int> type_ = new Column.Integer("type");
        public Column<int> encryption = new Column.Integer("encryption");
        public Column<int> read_up_to = new Column.Integer("read_up_to");
        public Column<int> read_up_to_item = new Column.Integer("read_up_to_item") { not_null=true, default="-1", min_version=15 };
        public Column<int> notification = new Column.Integer("notification") { min_version=3 };
        public Column<int> send_typing = new Column.Integer("send_typing") { min_version=3 };
        public Column<int> send_marker = new Column.Integer("send_marker") { min_version=3 };

        internal ConversationTable(Database db) {
            base(db, "conversation");
            init({id, account_id, jid_id, resource, active, last_active, type_, encryption, read_up_to, read_up_to_item, notification, send_typing, send_marker});
        }
    }

    public class AvatarTable : Table {
        public Column<int> jid_id = new Column.Integer("jid_id");
        public Column<int> account_id = new Column.Integer("account_id");
        public Column<string> hash = new Column.Text("hash");
        public Column<int> type_ = new Column.Integer("type");

        internal AvatarTable(Database db) {
            base(db, "contact_avatar");
            init({jid_id, account_id, hash, type_});
            unique({jid_id, account_id}, "REPLACE");
        }
    }

    public class EntityIdentityTable : Table {
        public Column<string> entity = new Column.Text("entity");
        public Column<string> category = new Column.Text("category");
        public Column<string> type = new Column.Text("type");
        public Column<string> entity_name = new Column.Text("name");

        internal EntityIdentityTable(Database db) {
            base(db, "entity_identity");
            init({entity, category, entity_name, type});
            unique({entity, category, type}, "IGNORE");
            index("entity_identity_idx", {entity});
        }
    }

    public class EntityFeatureTable : Table {
        public Column<string> entity = new Column.Text("entity");
        public Column<string> feature = new Column.Text("feature");

        internal EntityFeatureTable(Database db) {
            base(db, "entity_feature");
            init({entity, feature});
            unique({entity, feature}, "IGNORE");
            index("entity_feature_idx", {entity});
        }
    }

    public class RosterTable : Table {
        public Column<int> account_id = new Column.Integer("account_id");
        public Column<string> jid = new Column.Text("jid");
        public Column<string> handle = new Column.Text("name");
        public Column<string> subscription = new Column.Text("subscription");

        internal RosterTable(Database db) {
            base(db, "roster");
            init({account_id, jid, handle, subscription});
            unique({account_id, jid}, "IGNORE");
        }
    }

    public class MamCatchupTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<bool> from_end = new Column.BoolInt("from_end");
        public Column<string> from_id = new Column.Text("from_id");
        public Column<long> from_time = new Column.Long("from_time") { not_null = true };
        public Column<string> to_id = new Column.Text("to_id");
        public Column<long> to_time = new Column.Long("to_time") { not_null = true };

        internal MamCatchupTable(Database db) {
            base(db, "mam_catchup");
            init({id, account_id, from_end, from_id, from_time, to_id, to_time});
        }
    }

    public class SettingsTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> key = new Column.Text("key") { unique = true, not_null = true };
        public Column<string> value = new Column.Text("value");

        internal SettingsTable(Database db) {
            base(db, "settings");
            init({id, key, value});
        }
    }

    public AccountTable account { get; private set; }
    public JidTable jid { get; private set; }
    public EntityTable entity { get; private set; }
    public ContentItemTable content_item { get; private set; }
    public MessageTable message { get; private set; }
    public MessageCorrectionTable message_correction { get; private set; }
    public RealJidTable real_jid { get; private set; }
    public FileTransferTable file_transfer { get; private set; }
    public ConversationTable conversation { get; private set; }
    public AvatarTable avatar { get; private set; }
    public EntityIdentityTable entity_identity { get; private set; }
    public EntityFeatureTable entity_feature { get; private set; }
    public RosterTable roster { get; private set; }
    public MamCatchupTable mam_catchup { get; private set; }
    public SettingsTable settings { get; private set; }

    public Map<int, Jid> jid_table_cache = new HashMap<int, Jid>();
    public Map<Jid, int> jid_table_reverse = new HashMap<Jid, int>(Jid.hash_func, Jid.equals_func);
    public Map<int, Account> account_table_cache = new HashMap<int, Account>();

    public Database(string fileName) {
        base(fileName, VERSION);
        account = new AccountTable(this);
        jid = new JidTable(this);
        entity = new EntityTable(this);
        content_item = new ContentItemTable(this);
        message = new MessageTable(this);
        message_correction = new MessageCorrectionTable(this);
        real_jid = new RealJidTable(this);
        file_transfer = new FileTransferTable(this);
        conversation = new ConversationTable(this);
        avatar = new AvatarTable(this);
        entity_identity = new EntityIdentityTable(this);
        entity_feature = new EntityFeatureTable(this);
        roster = new RosterTable(this);
        mam_catchup = new MamCatchupTable(this);
        settings = new SettingsTable(this);
        init({ account, jid, entity, content_item, message, message_correction, real_jid, file_transfer, conversation, avatar, entity_identity, entity_feature, roster, mam_catchup, settings });
        try {
            exec("PRAGMA synchronous=0");
        } catch (Error e) { }
        try {
            exec("PRAGMA secure_delete=1");
        } catch (Error e) { }
    }

    public override void migrate(long oldVersion) {
        // new table columns are added, outdated columns are still present
        if (oldVersion < 7) {
            message.fts_rebuild();
        }
        if (oldVersion < 8) {
            try {
                exec("""
                insert into content_item (conversation_id, time, local_time, content_type, foreign_id, hide)
                select conversation.id, message.time, message.local_time, 1, message.id, 0
                from message join conversation on
                    message.account_id=conversation.account_id and
                    message.counterpart_id=conversation.jid_id and
                    message.type=conversation.type+1 and
                    (message.counterpart_resource=conversation.resource or message.type != 3)
                where
                    message.body not in (select info from file_transfer where info not null) and
                    message.id not in (select info from file_transfer where info not null)
                union
                select conversation.id, message.time, message.local_time, 2, file_transfer.id, 0
                from file_transfer
                join message on
                    file_transfer.info=message.id
                join conversation on
                    file_transfer.account_id=conversation.account_id and
                    file_transfer.counterpart_id=conversation.jid_id and
                    message.type=conversation.type+1 and
                    (message.counterpart_resource=conversation.resource or message.type != 3)""");
            } catch (Error e) {
                error("Failed to upgrade to database version 8: %s", e.message);
            }
        }
        if (oldVersion < 9) {
            try {
                exec("""
                insert into content_item (conversation_id, time, local_time, content_type, foreign_id, hide)
                select conversation.id, message.time, message.local_time, 1, message.id, 1
                from message join conversation on
                    message.account_id=conversation.account_id and
                    message.counterpart_id=conversation.jid_id and
                    message.type=conversation.type+1 and
                    (message.counterpart_resource=conversation.resource or message.type != 3)
                where
                    message.body in (select info from file_transfer where info not null) or
                    message.id in (select info from file_transfer where info not null)""");
            } catch (Error e) {
                error("Failed to upgrade to database version 9: %s", e.message);
            }
        }
        if (oldVersion < 11) {
            try {
                exec("""
                insert into mam_catchup (account_id, from_end, from_time, to_time)
                select id, 1, 0, mam_earliest_synced from account where mam_earliest_synced not null and mam_earliest_synced > 0""");
            } catch (Error e) {
                error("Failed to upgrade to database version 11: %s", e.message);
            }
        }
        if (oldVersion < 12) {
            try {
                exec("delete from avatar");
            } catch (Error e) {
                error("Failed to upgrade to database version 12: %s", e.message);
            }
        }
        if (oldVersion < 15) {
            // Initialize `conversation.read_up_to_item` with the content item id corresponding to the `read_up_to` message.
            try {
                exec("
                update conversation
                set read_up_to_item=ifnull((
                    select content_item.id
                    from content_item
                    where content_item.foreign_id=conversation.read_up_to and content_type=1)
                , -1);");
            } catch (Error e) {
                error("Failed to upgrade to database version 15: %s", e.message);
            }
        }
    }

    public ArrayList<Account> get_accounts() {
        ArrayList<Account> ret = new ArrayList<Account>(Account.equals_func);
        foreach(Row row in account.select()) {
            try {
                Account account = new Account.from_row(this, row);
                ret.add(account);
                account_table_cache[account.id] = account;
            } catch (InvalidJidError e) {
                warning("Ignoring account with invalid Jid: %s", e.message);
            }
        }
        return ret;
    }

    public Account? get_account_by_id(int id) {
        if (account_table_cache.has_key(id)) {
            return account_table_cache[id];
        } else {
            Row? row = account.row_with(account.id, id).inner;
            if (row != null) {
                try {
                    Account a = new Account.from_row(this, row);
                    account_table_cache[a.id] = a;
                    return a;
                } catch (InvalidJidError e) {
                    warning("Ignoring account with invalid Jid: %s", e.message);
                }
            }
            return null;
        }
    }

    public int add_content_item(Conversation conversation, DateTime time, DateTime local_time, int content_type, int foreign_id, bool hide) {
        return (int) content_item.insert()
            .value(content_item.conversation_id, conversation.id)
            .value(content_item.local_time, (long) local_time.to_unix())
            .value(content_item.time, (long) time.to_unix())
            .value(content_item.content_type, content_type)
            .value(content_item.foreign_id, foreign_id)
            .value(content_item.hide, hide)
            .perform();
    }

    public Gee.List<Message> get_messages(Jid jid, Account account, Message.Type? type, int count, DateTime? before, DateTime? after, int id) {
        QueryBuilder select = message.select();

        if (before != null) {
            if (id > 0) {
                select.where(@"local_time < ? OR (local_time = ? AND message.id < ?)", { before.to_unix().to_string(), before.to_unix().to_string(), id.to_string() });
            } else {
                select.with(message.id, "<", id);
            }
        }
        if (after != null) {
            if (id > 0) {
                select.where(@"local_time > ? OR (local_time = ? AND message.id > ?)", { after.to_unix().to_string(), after.to_unix().to_string(), id.to_string() });
            } else {
                select.with(message.local_time, ">", (long) after.to_unix());
            }
            if (id > 0) {
                select.with(message.id, ">", id);
            }
        } else {
            select.order_by(message.local_time, "DESC");
        }

        select.with(message.counterpart_id, "=", get_jid_id(jid))
                .with(message.account_id, "=", account.id)
                .limit(count);
        if (jid.resourcepart != null) {
            select.with(message.counterpart_resource, "=", jid.resourcepart);
        }
        if (type != null) {
            select.with(message.type_, "=", (int) type);
        }

        select.outer_join_with(real_jid, real_jid.message_id, message.id);
        select.outer_join_with(message_correction, message_correction.message_id, message.id);

        LinkedList<Message> ret = new LinkedList<Message>();
        foreach (Row row in select) {
            try {
                ret.insert(0, new Message.from_row(this, row));
            } catch (InvalidJidError e) {
                warning("Ignoring message with invalid Jid: %s", e.message);
            }
        }
        return ret;
    }

    public Message? get_message_by_id(int id) {
        Row? row = message.row_with(message.id, id).inner;
        if (row != null) {
            try {
                return new Message.from_row(this, row);
            } catch (InvalidJidError e) {
                warning("Ignoring message with invalid Jid: %s", e.message);
            }
        }
        return null;
    }

    public ArrayList<Conversation> get_conversations(Account account) {
        ArrayList<Conversation> ret = new ArrayList<Conversation>();
        foreach (Row row in conversation.select().with(conversation.account_id, "=", account.id)) {
            try {
                ret.add(new Conversation.from_row(this, row));
            } catch (InvalidJidError e) {
                warning("Ignoring conversation with invalid Jid: %s", e.message);
            }
        }
        return ret;
    }

    public int get_jid_id(Jid jid_obj) {
        var bare_jid = jid_obj.bare_jid;
        if (jid_table_reverse.has_key(bare_jid)) {
            return jid_table_reverse[bare_jid];
        } else {
            Row? row = jid.row_with(jid.bare_jid, jid_obj.bare_jid.to_string()).inner;
            if (row != null) {
                int id = row[jid.id];
                jid_table_cache[id] = bare_jid;
                jid_table_reverse[bare_jid] = id;
                return id;
            } else {
                return add_jid(jid_obj);
            }
        }
    }

    public Jid? get_jid_by_id(int id) throws InvalidJidError {
        if (jid_table_cache.has_key(id)) {
            return jid_table_cache[id];
        } else {
            string? bare_jid = jid.select({jid.bare_jid}).with(jid.id, "=", id)[jid.bare_jid];
            if (bare_jid != null) {
                Jid jid_parsed = new Jid(bare_jid);
                jid_table_cache[id] = jid_parsed;

                // Only store fully normalized Jids for reverse lookup
                if (jid_parsed.to_string() == bare_jid) {
                    jid_table_reverse[jid_parsed] = id;
                }
                return jid_parsed;
            }
            return null;
        }
    }

    private int add_jid(Jid jid_obj) {
        Jid bare_jid = jid_obj.bare_jid;
        int id = (int) jid.insert().value(jid.bare_jid, bare_jid.to_string()).perform();
        jid_table_cache[id] = bare_jid;
        jid_table_reverse[bare_jid] = id;
        return id;
    }
}

}
