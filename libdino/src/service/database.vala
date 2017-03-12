using Gee;
using Sqlite;
using Qlite;

using Dino.Entities;

namespace Dino {

public class Database : Qlite.Database {
    private const int VERSION = 0;

    public class AccountTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> bare_jid = new Column.Text("bare_jid") { unique = true, not_null = true };
        public Column<string> resourcepart = new Column.Text("resourcepart");
        public Column<string> password = new Column.Text("password");
        public Column<string> alias = new Column.Text("alias");
        public Column<bool> enabled = new Column.BoolInt("enabled");

        protected AccountTable(Database db) {
            base(db, "account");
            init({id, bare_jid, resourcepart, password, alias, enabled});
        }
    }

    public class JidTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> bare_jid = new Column.Text("bare_jid") { unique = true, not_null = true };

        protected JidTable(Database db) {
            base(db, "jid");
            init({id, bare_jid});
        }
    }

    public class MessageTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> stanza_id = new Column.Text("stanza_id");
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

        protected MessageTable(Database db) {
            base(db, "message");
            init({id, stanza_id, account_id, counterpart_id, our_resource, counterpart_resource, direction,
                type_, time, local_time, body, encryption, marked});
        }
    }

    public class RealJidTable : Table {
        public Column<int> message_id = new Column.Integer("message_id") { primary_key = true };
        public Column<string> real_jid = new Column.Text("real_jid");

        protected RealJidTable(Database db) {
            base(db, "real_jid");
            init({message_id, real_jid});
        }
    }

    public class UndecryptedTable : Table {
        public Column<int> message_id = new Column.Integer("message_id");
        public Column<int> type_ = new Column.Integer("type");
        public Column<string> data = new Column.Text("data");

        protected UndecryptedTable(Database db) {
            base(db, "undecrypted");
            init({message_id, type_, data});
        }
    }

    public class ConversationTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> jid_id = new Column.Integer("jid_id") { not_null = true };
        public Column<bool> active = new Column.BoolInt("active");
        public Column<long> last_active = new Column.Long("last_active");
        public Column<int> type_ = new Column.Integer("type");
        public Column<int> encryption = new Column.Integer("encryption");
        public Column<int> read_up_to = new Column.Integer("read_up_to");

        protected ConversationTable(Database db) {
            base(db, "conversation");
            init({id, account_id, jid_id, active, last_active, type_, encryption, read_up_to});
        }
    }

    public class AvatarTable : Table {
        public Column<string> jid = new Column.Text("jid");
        public Column<string> hash = new Column.Text("hash");
        public Column<int> type_ = new Column.Integer("type");

        protected AvatarTable(Database db) {
            base(db, "avatar");
            init({jid, hash, type_});
        }
    }

    public class EntityFeatureTable : Table {
        public Column<string> entity = new Column.Text("entity");
        public Column<string> feature = new Column.Text("feature");

        protected EntityFeatureTable(Database db) {
            base(db, "entity_feature");
            init({entity, feature});
        }
    }

    public AccountTable account { get; private set; }
    public JidTable jid { get; private set; }
    public MessageTable message { get; private set; }
    public RealJidTable real_jid { get; private set; }
    public ConversationTable conversation { get; private set; }
    public AvatarTable avatar { get; private set; }
    public EntityFeatureTable entity_feature { get; private set; }

    public Database(string fileName) {
        base(fileName, VERSION);
        account = new AccountTable(this);
        jid = new JidTable(this);
        message = new MessageTable(this);
        real_jid = new RealJidTable(this);
        conversation = new ConversationTable(this);
        avatar = new AvatarTable(this);
        entity_feature = new EntityFeatureTable(this);
        init({ account, jid, message, real_jid, conversation, avatar, entity_feature });
    }

    public override void migrate(long oldVersion) {
        // new table columns are added, outdated columns are still present
    }

    public void add_account(Account new_account) {
        new_account.id = (int) account.insert()
                .value(account.bare_jid, new_account.bare_jid.to_string())
                .value(account.resourcepart, new_account.resourcepart)
                .value(account.password, new_account.password)
                .value(account.alias, new_account.alias)
                .value(account.enabled, new_account.enabled)
                .perform();
        new_account.notify.connect(on_account_update);
    }

    private void on_account_update(Object o, ParamSpec sp) {
        Account changed_account = (Account) o;
        account.update().with(account.id, "=", changed_account.id)
                .set(account.bare_jid, changed_account.bare_jid.to_string())
                .set(account.resourcepart, changed_account.resourcepart)
                .set(account.password, changed_account.password)
                .set(account.alias, changed_account.alias)
                .set(account.enabled, changed_account.enabled)
                .perform();
    }

    public void remove_account(Account to_delete) {
        account.delete().with(account.bare_jid, "=", to_delete.bare_jid.to_string()).perform();
    }

    public ArrayList<Account> get_accounts() {
        ArrayList<Account> ret = new ArrayList<Account>();
        foreach(Row row in account.select()) {
            Account account = get_account_from_row(row);
            account.notify.connect(on_account_update);
            ret.add(account);
        }
        return ret;
    }

    private Account? get_account_by_id(int id) {
        Row? row = account.row_with(account.id, id);
        if (row != null) {
            return get_account_from_row(row);
        }
        return null;
    }

    private Account get_account_from_row(Row row) {
        Account new_account = new Account.from_bare_jid(row[account.bare_jid]);

        new_account.id = row[account.id];
        new_account.resourcepart = row[account.resourcepart];
        new_account.password = row[account.password];
        new_account.alias = row[account.alias];
        new_account.enabled = row[account.enabled];
        return new_account;
    }

    public void add_message(Message new_message, Account account) {
        InsertBuilder builder = message.insert()
            .value(message.account_id, new_message.account.id)
            .value(message.counterpart_id, get_jid_id(new_message.counterpart))
            .value(message.counterpart_resource, new_message.counterpart.resourcepart)
            .value(message.our_resource, new_message.ourpart.resourcepart)
            .value(message.direction, new_message.direction)
            .value(message.type_, new_message.type_)
            .value(message.time, (long) new_message.time.to_unix())
            .value(message.local_time, (long) new_message.local_time.to_unix())
            .value(message.body, new_message.body)
            .value(message.encryption, new_message.encryption)
            .value(message.marked, new_message.marked);
        if (new_message.stanza_id != null) builder.value(message.stanza_id, new_message.stanza_id);
        new_message.id = (int) builder.perform();

        if (new_message.real_jid != null) {
            real_jid.insert()
                .value(real_jid.message_id, new_message.id)
                .value(real_jid.real_jid, new_message.real_jid)
                .perform();
        }
        new_message.notify.connect(on_message_update);
    }

    private void on_message_update(Object o, ParamSpec sp) {
        Message changed_message = (Message) o;
        UpdateBuilder update_builder = message.update().with(message.id, "=", changed_message.id);
        switch (sp.get_name()) {
            case "stanza_id":
                update_builder.set(message.stanza_id, changed_message.stanza_id); break;
            case "counterpart":
                update_builder.set(message.counterpart_id, get_jid_id(changed_message.counterpart));
                update_builder.set(message.counterpart_resource, changed_message.counterpart.resourcepart); break;
            case "ourpart":
                update_builder.set(message.our_resource, changed_message.ourpart.resourcepart); break;
            case "direction":
                update_builder.set(message.direction, changed_message.direction); break;
            case "type_":
                update_builder.set(message.type_, changed_message.type_); break;
            case "time":
                update_builder.set(message.time, (long) changed_message.time.to_unix()); break;
            case "local_time":
                update_builder.set(message.local_time, (long) changed_message.local_time.to_unix()); break;
            case "body":
                update_builder.set(message.body, changed_message.body); break;
            case "encryption":
                update_builder.set(message.encryption, changed_message.encryption); break;
            case "marked":
                update_builder.set(message.marked, changed_message.marked); break;
        }
        update_builder.perform();

        if (sp.get_name() == "real_jid") {
            real_jid.insert()
                .value(real_jid.message_id, changed_message.id)
                .value(real_jid.real_jid, changed_message.real_jid)
                .perform();
        }
    }

    public Gee.List<Message> get_messages(Jid jid, Account account, int count, Message? before) {
        string jid_id = get_jid_id(jid).to_string();

        QueryBuilder select = message.select()
                .with(message.counterpart_id, "=", get_jid_id(jid))
                .with(message.account_id, "=", account.id)
                .order_by(message.id, "DESC")
                .limit(count);
        if (before != null) {
            select.with(message.time, "<", (long) before.time.to_unix());
        }

        LinkedList<Message> ret = new LinkedList<Message>();
        foreach (Row row in select) {
            ret.insert(0, get_message_from_row(row));
        }
        return ret;
    }

    public Gee.List<Message> get_unsend_messages(Account account) {
        Gee.List<Message> ret = new ArrayList<Message>();
        foreach (Row row in message.select().with(message.marked, "=", (int) Message.Marked.UNSENT)) {
            ret.add(get_message_from_row(row));
        }
        return ret;
    }

    public bool contains_message(Message query_message, Account account) {
        int jid_id = get_jid_id(query_message.counterpart);
        return message.select()
                .with(message.account_id, "=", account.id)
                .with(message.stanza_id, "=", query_message.stanza_id)
                .with(message.counterpart_id, "=", jid_id)
                .with(message.counterpart_resource, "=", query_message.counterpart.resourcepart)
                .with(message.body, "=", query_message.body)
                .with(message.time, "<", (long) query_message.time.add_minutes(1).to_unix())
                .with(message.time, ">", (long) query_message.time.add_minutes(-1).to_unix())
                .count() > 0;
    }

    public bool contains_message_by_stanza_id(string stanza_id) {
        return message.select()
                .with(message.stanza_id, "=", stanza_id)
                .count() > 0;
    }

    public Message? get_message_by_id(int id) {
        Row? row = message.row_with(message.id, id);
        if (row != null) {
            return get_message_from_row(row);
        }
        return null;
    }

    public Message get_message_from_row(Row row) {
        Message new_message = new Message();

        new_message.id = row[message.id];
        new_message.stanza_id = row[message.stanza_id];
        string from = get_jid_by_id(row[message.counterpart_id]);
        string from_resource = row[message.counterpart_resource];
        if (from_resource != null) {
            new_message.counterpart = new Jid(from + "/" + from_resource);
        } else {
            new_message.counterpart = new Jid(from);
        }
        new_message.direction = row[message.direction];
        new_message.type_ = (Message.Type) row[message.type_];
        new_message.time = new DateTime.from_unix_utc(row[message.time]);
        new_message.body = row[message.body];
        new_message.account = get_account_by_id(row[message.account_id]); // TODO dont have to generate acc new
        new_message.marked = (Message.Marked) row[message.marked];
        new_message.encryption = (Encryption) row[message.encryption];
        new_message.real_jid = get_real_jid_for_message(new_message);

        new_message.notify.connect(on_message_update);
        return new_message;
    }

    public string? get_real_jid_for_message(Message message) {
        return real_jid.select({real_jid.real_jid}).with(real_jid.message_id, "=", message.id)[real_jid.real_jid];
    }

    public void add_conversation(Conversation new_conversation) {
        var insert = conversation.insert()
                .value(conversation.jid_id, get_jid_id(new_conversation.counterpart))
                .value(conversation.account_id, new_conversation.account.id)
                .value(conversation.type_, new_conversation.type_)
                .value(conversation.encryption, new_conversation.encryption)
                //.value(conversation.read_up_to, new_conversation.read_up_to)
                .value(conversation.active, new_conversation.active);
        if (new_conversation.last_active != null) {
            insert.value(conversation.last_active, (long) new_conversation.last_active.to_unix());
        } else {
            insert.value_null(conversation.last_active);
        }
        new_conversation.id = (int) insert.perform();
        new_conversation.notify.connect(on_conversation_update);
    }

    public ArrayList<Conversation> get_conversations(Account account) {
        ArrayList<Conversation> ret = new ArrayList<Conversation>();
        foreach (Row row in conversation.select().with(conversation.account_id, "=", account.id)) {
            ret.add(get_conversation_from_row(row));
        }
        return ret;
    }

    private void on_conversation_update(Object o, ParamSpec sp) {
        Conversation changed_conversation = (Conversation) o;
        var update = conversation.update().with(conversation.jid_id, "=", get_jid_id(changed_conversation.counterpart)).with(conversation.account_id, "=", changed_conversation.account.id)
                .set(conversation.type_, changed_conversation.type_)
                .set(conversation.encryption, changed_conversation.encryption)
                //.set(conversation.read_up_to, changed_conversation.read_up_to)
                .set(conversation.active, changed_conversation.active);
        if (changed_conversation.last_active != null) {
            update.set(conversation.last_active, (long) changed_conversation.last_active.to_unix());
        } else {
            update.set_null(conversation.last_active);
        }
        update.perform();
    }

    private Conversation get_conversation_from_row(Row row) {
        Conversation new_conversation = new Conversation(new Jid(get_jid_by_id(row[conversation.jid_id])), get_account_by_id(row[conversation.account_id]));

        new_conversation.id = row[conversation.id];
        new_conversation.active = row[conversation.active];
        int64? last_active = row[conversation.last_active];
        if (last_active != null) new_conversation.last_active = new DateTime.from_unix_utc(last_active);
        new_conversation.type_ = (Conversation.Type) row[conversation.type_];
        new_conversation.encryption = (Encryption) row[conversation.encryption];
        int? read_up_to = row[conversation.read_up_to];
        if (read_up_to != null) new_conversation.read_up_to = get_message_by_id(read_up_to);

        new_conversation.notify.connect(on_conversation_update);
        return new_conversation;
    }

    public void set_avatar_hash(Jid jid, string hash, int type) {
        avatar.insert().or("REPLACE")
                .value(avatar.jid, jid.to_string())
                .value(avatar.hash, hash)
                .value(avatar.type_, type)
                .perform();
    }

    public HashMap<Jid, string> get_avatar_hashes(int type) {
        HashMap<Jid, string> ret = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
        foreach (Row row in avatar.select({avatar.jid, avatar.hash}).with(avatar.type_, "=", type)) {
            ret[new Jid(row[avatar.jid])] = row[avatar.hash];
        }
        return ret;
    }

    public void add_entity_features(string entity, ArrayList<string> features) {
        foreach (string feature in features) {
            entity_feature.insert()
                    .value(entity_feature.entity, entity)
                    .value(entity_feature.feature, feature)
                    .perform();
        }
    }

    public ArrayList<string> get_entity_features(string entity) {
        ArrayList<string> ret = new ArrayList<string>();
        foreach (Row row in entity_feature.select({entity_feature.feature}).with(entity_feature.entity, "=", entity)) {
            ret.add(row[entity_feature.feature]);
        }
        return ret;
    }


    private int get_jid_id(Jid jid_obj) {
        Row? row = jid.row_with(jid.bare_jid, jid_obj.bare_jid.to_string());
        return row != null ? row[jid.id] : add_jid(jid_obj);
    }

    private string? get_jid_by_id(int id) {
        return jid.select({jid.bare_jid}).with(jid.id, "=", id)[jid.bare_jid];
    }

    private int add_jid(Jid jid_obj) {
        return (int) jid.insert().value(jid.bare_jid, jid_obj.bare_jid.to_string()).perform();
    }
}

}