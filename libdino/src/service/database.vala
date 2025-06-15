using Gee;
using Qlite;
using Xmpp;

using Dino.Entities;

namespace Dino {

public class Database : Qlite.Database {
    private const int VERSION = 30;

    public class AccountTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<string> bare_jid = new Column.Text("bare_jid") { unique = true, not_null = true };
        public Column<string> resourcepart = new Column.Text("resourcepart");
        public Column<string> password = new Column.Text("password");
        public Column<string> alias = new Column.Text("alias");
        public Column<bool> enabled = new Column.BoolInt("enabled");
        public Column<string> roster_version = new Column.Text("roster_version") { min_version=2 };
        // no longer used. all usages already removed. remove db column at some point.
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
            index("contentitem_conversation_hide_time_idx", {conversation_id, hide, time});
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
        public Column<bool> retracted = new Column.BoolInt("retracted") { not_null = true, default = "0", min_version = 30 };

        internal MessageTable(Database db) {
            base(db, "message");
            init({id, stanza_id, server_id, account_id, counterpart_id, our_resource, counterpart_resource, direction,
                type_, time, local_time, body, encryption, marked, retracted});

            // get latest messages
            index("message_account_counterpart_time_idx", {account_id, counterpart_id, time});

            // deduplication
            index("message_account_counterpart_stanzaid_idx", {account_id, counterpart_id, stanza_id});
            index("message_account_counterpart_serverid_idx", {account_id, counterpart_id, server_id});

            // message by marked
            index("message_account_marked_idx", {account_id, marked});

            fts({body});
        }
    }

    public class BodyMeta : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> message_id = new Column.Integer("message_id");
        public Column<int> from_char = new Column.Integer("from_char");
        public Column<int> to_char = new Column.Integer("to_char");
        public Column<string> info_type = new Column.Text("info_type");
        public Column<string> info = new Column.Text("info");

        internal BodyMeta(Database db) {
            base(db, "body_meta");
            init({id, message_id, from_char, to_char, info_type, info});
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

    public class ReplyTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> message_id = new Column.Integer("message_id") { not_null = true, unique=true };
        public Column<int> quoted_content_item_id = new Column.Integer("quoted_message_id");
        public Column<string?> quoted_message_stanza_id = new Column.Text("quoted_message_stanza_id");
        public Column<string?> quoted_message_from = new Column.Text("quoted_message_from");

        internal ReplyTable(Database db) {
            base(db, "reply");
            init({id, message_id, quoted_content_item_id, quoted_message_stanza_id, quoted_message_from});
            index("reply_quoted_message_stanza_id", {quoted_message_stanza_id});
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

    public class OccupantIdTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<string> last_nick = new Column.Text("last_nick");
        public Column<int> jid_id = new Column.Integer("jid_id");
        public Column<string> occupant_id = new Column.Text("occupant_id");

        internal OccupantIdTable(Database db) {
            base(db, "occupant_id");
            init({id, account_id, last_nick, jid_id, occupant_id});
            unique({account_id, jid_id, occupant_id}, "REPLACE");
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
        public Column<string> file_sharing_id = new Column.Text("file_sharing_id") { min_version=28 };
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
        public Column<long> size = new Column.Long("size");
        public Column<int> state = new Column.Integer("state");
        public Column<int> provider = new Column.Integer("provider");
        public Column<string> info = new Column.Text("info");
        public Column<long> modification_date = new Column.Long("modification_date") { default = "-1", min_version=28 };
        public Column<int> width = new Column.Integer("width") { default = "-1", min_version=28 };
        public Column<int> height = new Column.Integer("height") { default = "-1", min_version=28 };
        public Column<long> length = new Column.Integer("length") { default = "-1", min_version=28 };

        internal FileTransferTable(Database db) {
            base(db, "file_transfer");
            init({id, file_sharing_id, account_id, counterpart_id, counterpart_resource, our_resource, direction,
                time, local_time, encryption, file_name, path, mime_type, size, state, provider, info, modification_date,
                width, height, length});
        }
    }

    public class FileHashesTable : Table {
        public Column<int> id = new Column.Integer("id");
        public Column<string> algo = new Column.Text("algo") { not_null = true };
        public Column<string> value = new Column.Text("value") { not_null = true };

        internal FileHashesTable(Database db) {
            base(db, "file_hashes");
            init({id, algo, value});
            unique({id, algo}, "REPLACE");
        }
    }

    public class FileThumbnailsTable : Table {
        public Column<int> id = new Column.Integer("id");
        // TODO store data as bytes, not as data uri
        public Column<string> uri = new Column.Text("uri") { not_null = true };
        public Column<string> mime_type = new Column.Text("mime_type");
        public Column<int> width = new Column.Integer("width");
        public Column<int> height = new Column.Integer("height");

        internal FileThumbnailsTable(Database db) {
            base(db, "file_thumbnails");
            init({id, uri, mime_type, width, height});
        }
    }

    public class SourcesTable : Table {
        public Column<int> file_transfer_id = new Column.Integer("file_transfer_id");
        public Column<string> type = new Column.Text("type") { not_null = true };
        public Column<string> data = new Column.Text("data") { not_null = true };

        internal SourcesTable(Database db) {
            base(db, "sfs_sources");
            init({file_transfer_id, type, data});
            index("sfs_sources_file_transfer_id_idx", {file_transfer_id});
        }
    }

    public class CallTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> counterpart_id = new Column.Integer("counterpart_id") { not_null = true };
        public Column<string> counterpart_resource = new Column.Text("counterpart_resource");
        public Column<string> our_resource = new Column.Text("our_resource");
        public Column<bool> direction = new Column.BoolInt("direction") { not_null = true };
        public Column<long> time = new Column.Long("time") { not_null = true };
        public Column<long> local_time = new Column.Long("local_time") { not_null = true };
        public Column<long> end_time = new Column.Long("end_time");
        public Column<int> encryption = new Column.Integer("encryption") { min_version=21 };
        public Column<int> state = new Column.Integer("state");

        internal CallTable(Database db) {
            base(db, "call");
            init({id, account_id, counterpart_id, counterpart_resource, our_resource, direction, time, local_time, end_time, encryption, state});
        }
    }

    public class CallCounterpartTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> call_id = new Column.Integer("call_id") { not_null = true };
        public Column<int> jid_id = new Column.Integer("jid_id") { not_null = true };
        public Column<string> resource = new Column.Text("resource");

        internal CallCounterpartTable(Database db) {
            base(db, "call_counterpart");
            init({call_id, jid_id, resource});
            index("call_counterpart_call_jid_idx", {call_id});
        }
    }

    public class ConversationTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> jid_id = new Column.Integer("jid_id") { not_null = true };
        public Column<string> resource = new Column.Text("resource") { min_version=1 };
        public Column<bool> active = new Column.BoolInt("active");
        public Column<long> active_last_changed = new Column.Integer("active_last_changed") { not_null=true, default="0", min_version=23 };
        public Column<long> last_active = new Column.Long("last_active");
        public Column<int> type_ = new Column.Integer("type");
        public Column<int> encryption = new Column.Integer("encryption");
        public Column<int> read_up_to = new Column.Integer("read_up_to");
        public Column<int> read_up_to_item = new Column.Integer("read_up_to_item") { not_null=true, default="-1", min_version=15 };
        public Column<int> notification = new Column.Integer("notification") { min_version=3 };
        public Column<int> send_typing = new Column.Integer("send_typing") { min_version=3 };
        public Column<int> send_marker = new Column.Integer("send_marker") { min_version=3 };
        public Column<int> pinned = new Column.Integer("pinned") { default="0", min_version=25 };

        internal ConversationTable(Database db) {
            base(db, "conversation");
            init({id, account_id, jid_id, resource, active, active_last_changed, last_active, type_, encryption, read_up_to, read_up_to_item, notification, send_typing, send_marker, pinned});
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
            unique({jid_id, account_id, type_}, "REPLACE");
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
        public Column<string> ask = new Column.Text("ask") { min_version=29 };

        internal RosterTable(Database db) {
            base(db, "roster");
            init({account_id, jid, handle, subscription, ask});
            unique({account_id, jid}, "IGNORE");
        }
    }

    public class MamCatchupTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<string> server_jid = new Column.Text("server_jid") { not_null = true };
        public Column<string> from_id = new Column.Text("from_id") { not_null = true };
        public Column<long> from_time = new Column.Long("from_time") { not_null = true };
        public Column<bool> from_end = new Column.BoolInt("from_end") { not_null = true };
        public Column<string> to_id = new Column.Text("to_id") { not_null = true };
        public Column<long> to_time = new Column.Long("to_time") { not_null = true };

        internal MamCatchupTable(Database db) {
            base(db, "mam_catchup");
            init({id, account_id, server_jid, from_end, from_id, from_time, to_id, to_time});
        }
    }

    public class ReactionTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<int> occupant_id = new Column.Integer("occupant_id");
        public Column<int> content_item_id = new Column.Integer("content_item_id") { not_null = true };
        public Column<long> time = new Column.Long("time") { not_null = true };
        public Column<int> jid_id = new Column.Integer("jid_id");
        public Column<string> emojis = new Column.Text("emojis");

        internal ReactionTable(Database db) {
            base(db, "reaction");
            init({id, account_id, occupant_id, content_item_id, time, jid_id, emojis});
            unique({account_id, content_item_id, jid_id}, "REPLACE");
            unique({account_id, content_item_id, occupant_id}, "REPLACE");
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

    public class AccountSettingsTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> account_id = new Column.Integer("account_id") { not_null = true };
        public Column<string> key = new Column.Text("key") { not_null = true };
        public Column<string> value = new Column.Text("value");

        internal AccountSettingsTable(Database db) {
            base(db, "account_settings");
            init({id, account_id, key, value});
            unique({account_id, key}, "REPLACE");
        }

        public string? get_value(int account_id, string key) {
            var row_opt = select({value})
                .with(this.account_id, "=", account_id)
                .with(this.key, "=", key)
                .single()
                .row();
            if (row_opt.is_present()) return row_opt[value];
            return null;
        }
    }

    public class ConversationSettingsTable : Table {
        public Column<int> id = new Column.Integer("id") { primary_key = true, auto_increment = true };
        public Column<int> conversation_id = new Column.Integer("conversation_id") {not_null=true};
        public Column<string> key = new Column.Text("key") { not_null=true };
        public Column<string> value = new Column.Text("value");

        internal ConversationSettingsTable(Database db) {
            base(db, "conversation_settings");
            init({id, conversation_id, key, value});
            index("settings_conversationid_key", { conversation_id, key }, true);
        }
    }

    public AccountTable account { get; private set; }
    public JidTable jid { get; private set; }
    public EntityTable entity { get; private set; }
    public ContentItemTable content_item { get; private set; }
    public MessageTable message { get; private set; }
    public BodyMeta body_meta { get; private set; }
    public ReplyTable reply { get; private set; }
    public MessageCorrectionTable message_correction { get; private set; }
    public RealJidTable real_jid { get; private set; }
    public OccupantIdTable occupantid { get; private set; }
    public FileTransferTable file_transfer { get; private set; }
    public FileHashesTable file_hashes { get; private set; }
    public FileThumbnailsTable file_thumbnails { get; private set; }
    public SourcesTable sfs_sources { get; private set; }
    public CallTable call { get; private set; }
    public CallCounterpartTable call_counterpart { get; private set; }
    public ConversationTable conversation { get; private set; }
    public AvatarTable avatar { get; private set; }
    public EntityIdentityTable entity_identity { get; private set; }
    public EntityFeatureTable entity_feature { get; private set; }
    public RosterTable roster { get; private set; }
    public MamCatchupTable mam_catchup { get; private set; }
    public ReactionTable reaction { get; private set; }
    public SettingsTable settings { get; private set; }
    public AccountSettingsTable account_settings { get; private set; }
    public ConversationSettingsTable conversation_settings { get; private set; }

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
        body_meta = new BodyMeta(this);
        message_correction = new MessageCorrectionTable(this);
        reply = new ReplyTable(this);
        occupantid = new OccupantIdTable(this);
        real_jid = new RealJidTable(this);
        file_transfer = new FileTransferTable(this);
        file_hashes = new FileHashesTable(this);
        file_thumbnails = new FileThumbnailsTable(this);
        sfs_sources = new SourcesTable(this);
        call = new CallTable(this);
        call_counterpart = new CallCounterpartTable(this);
        conversation = new ConversationTable(this);
        avatar = new AvatarTable(this);
        entity_identity = new EntityIdentityTable(this);
        entity_feature = new EntityFeatureTable(this);
        roster = new RosterTable(this);
        mam_catchup = new MamCatchupTable(this);
        reaction = new ReactionTable(this);
        settings = new SettingsTable(this);
        account_settings = new AccountSettingsTable(this);
        conversation_settings = new ConversationSettingsTable(this);
        init({ account, jid, entity, content_item, message, body_meta, message_correction, reply, real_jid, occupantid, file_transfer, file_hashes, file_thumbnails, sfs_sources, call, call_counterpart, conversation, avatar, entity_identity, entity_feature, roster, mam_catchup, reaction, settings, account_settings, conversation_settings });

        try {
            exec("PRAGMA journal_mode = WAL");
            exec("PRAGMA synchronous = NORMAL");
            exec("PRAGMA secure_delete = ON");
        } catch (Error e) {
            error("Failed to set database properties: %s", e.message);
        }
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
        if (oldVersion < 16) {
            try {
                exec("DROP TABLE contact_avatar");
                avatar.create_table_at_version(VERSION);
            } catch (Error e) {
                error("Failed to upgrade to database version 16: %s", e.message);
            }
        }
        if (oldVersion < 17) {
            try {
                exec("DROP INDEX IF EXISTS contentitem_localtime_counterpart_idx");
                exec("CREATE INDEX IF NOT EXISTS contentitem_conversation_hide_localtime_time_idx ON content_item (conversation_id, hide, local_time, time)");
            } catch (Error e) {
                error("Failed to upgrade to database version 17: %s", e.message);
            }
        }
        if (oldVersion < 18) {
            try {
                exec("DROP INDEX IF EXISTS contentitem_conversation_hide_localtime_time_idx");
                exec("CREATE INDEX IF NOT EXISTS contentitem_conversation_hide_time_idx ON content_item (conversation_id, hide, time)");

                exec("DROP INDEX IF EXISTS message_account_counterpart_localtime_idx");
                exec("CREATE INDEX IF NOT EXISTS message_account_counterpart_time_idx ON message (account_id, counterpart_id, time)");

                exec("DROP INDEX IF EXISTS filetransfer_localtime_counterpart_idx");
            } catch (Error e) {
                error("Failed to upgrade to database version 18: %s", e.message);
            }
        }
        if (oldVersion < 22) {
            try {
                exec("INSERT INTO call_counterpart (call_id, jid_id, resource) SELECT id, counterpart_id, counterpart_resource FROM call");
            } catch (Error e) {
                error("Failed to upgrade to database version 22: %s", e.message);
            }
//                exec("ALTER TABLE call RENAME TO call2");
//                call.create_table_at_version(VERSION);
//                exec("INSERT INTO call (id, account_id, our_resource, direction, time, local_time, end_time, encryption, state)
//                            SELECT id, account_id, our_resource, direction, time, local_time, end_time, encryption, state
//                            FROM call2");
//                exec("DROP TABLE call2");
        }
        if (oldVersion < 23) {
            try {
                exec("ALTER TABLE mam_catchup RENAME TO mam_catchup2");
                mam_catchup.create_table_at_version(VERSION);
                exec("""INSERT INTO mam_catchup (id, account_id, server_jid, from_id, from_time, from_end, to_id, to_time)
                                SELECT mam_catchup2.id, account_id, bare_jid, ifnull(from_id, ""), from_time, ifnull(from_end, 0), ifnull(to_id, ""), to_time
                                FROM mam_catchup2 JOIN account ON mam_catchup2.account_id=account.id""");
                exec("DROP TABLE mam_catchup2");
            } catch (Error e) {
                error("Failed to upgrade to database version 23 (mam_catchup): %s", e.message);
            }

            try {
                long active_last_updated = (long) new DateTime.now_utc().to_unix();
                exec(@"UPDATE conversation SET active_last_changed=$active_last_updated WHERE active_last_changed=0");
            } catch (Error e) {
                error("Failed to upgrade to database version 23 (conversation): %s", e.message);
            }
        }
    }

    public ArrayList<Account> get_accounts() {
        ArrayList<Account> ret = new ArrayList<Account>(Account.equals_func);
        foreach(Row row in account.select()) {
            try {
                Account account = new Account.from_row(this, row);
                if (account_table_cache.has_key(account.id)) {
                    account = account_table_cache[account.id];
                }
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
                select.where(@"time < ? OR (time = ? AND message.id < ?)", { before.to_unix().to_string(), before.to_unix().to_string(), id.to_string() });
            } else {
                select.with(message.id, "<", id);
            }
        }
        if (after != null) {
            if (id > 0) {
                select.where(@"time > ? OR (time = ? AND message.id > ?)", { after.to_unix().to_string(), after.to_unix().to_string(), id.to_string() });
            } else {
                select.with(message.time, ">", (long) after.to_unix());
            }
            if (id > 0) {
                select.with(message.id, ">", id);
            }
        } else {
            select.order_by(message.time, "DESC");
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
