using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Qlite;

namespace Dino {

public class MessageProcessor : StreamInteractionModule, Object {
    public static ModuleIdentity<MessageProcessor> IDENTITY = new ModuleIdentity<MessageProcessor>("message_processor");
    public string id { get { return IDENTITY.id; } }

    public signal void message_received(Entities.Message message, Conversation conversation);
    public signal void build_message_stanza(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void pre_message_send(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation);
    public signal void message_sent(Entities.Message message, Conversation conversation);
    public signal void message_sent_or_received(Entities.Message message, Conversation conversation);
    public signal void history_synced(Account account);

    public MessageListenerHolder received_pipeline = new MessageListenerHolder();

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Account, int> current_catchup_id = new HashMap<Account, int>(Account.hash_func, Account.equals_func);
    private HashMap<Account, HashMap<string, DateTime>> mam_times = new HashMap<Account, HashMap<string, DateTime>>();
    public HashMap<string, int> hitted_range = new HashMap<string, int>();
    public HashMap<Account, string> catchup_until_id = new HashMap<Account, string>(Account.hash_func, Account.equals_func);
    public HashMap<Account, DateTime> catchup_until_time = new HashMap<Account, DateTime>(Account.hash_func, Account.equals_func);

    public static void start(StreamInteractor stream_interactor, Database db) {
        MessageProcessor m = new MessageProcessor(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private MessageProcessor(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        received_pipeline.connect(new DeduplicateMessageListener(this, db));
        received_pipeline.connect(new FilterMessageListener());
        received_pipeline.connect(new StoreMessageListener(stream_interactor));
        received_pipeline.connect(new StoreContentItemListener(stream_interactor));
        received_pipeline.connect(new MamMessageListener(stream_interactor));

        stream_interactor.account_added.connect(on_account_added);

        stream_interactor.connection_manager.connection_state_changed.connect((account, state) => {
            if (state == ConnectionManager.ConnectionState.CONNECTED) send_unsent_chat_messages(account);
        });

        stream_interactor.connection_manager.stream_opened.connect((account, stream) => {
            debug("MAM: [%s] Reset catchup_id", account.bare_jid.to_string());
            current_catchup_id.unset(account);
            mam_times[account] = new HashMap<string, DateTime>();
        });
    }

    public Entities.Message send_text(string text, Conversation conversation) {
        Entities.Message message = create_out_message(text, conversation);
        return send_message(message, conversation);
    }

    public Entities.Message send_message(Entities.Message message, Conversation conversation) {
        stream_interactor.get_module(MessageStorage.IDENTITY).add_message(message, conversation);
        stream_interactor.get_module(ContentItemStore.IDENTITY).insert_message(message, conversation);
        send_xmpp_message(message, conversation);
        message_sent(message, conversation);
        return message;
    }

    private void send_unsent_chat_messages(Account account) {
        var select = db.message.select()
                .with(db.message.account_id, "=", account.id)
                .with(db.message.marked, "=", (int) Message.Marked.UNSENT)
                .with(db.message.type_, "=", (int) Message.Type.CHAT);
        send_unsent_messages(account, select);
    }

    public void send_unsent_muc_messages(Account account, Jid muc_jid) {
        var select = db.message.select()
                .with(db.message.account_id, "=", account.id)
                .with(db.message.marked, "=", (int) Message.Marked.UNSENT)
                .with(db.message.counterpart_id, "=", db.get_jid_id(muc_jid));
        send_unsent_messages(account, select);
    }

    private void send_unsent_messages(Account account, QueryBuilder select) {
        foreach (Row row in select) {
            try {
                Message message = new Message.from_row(db, row);
                Conversation? msg_conv = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart, account, Util.get_conversation_type_for_message(message));
                if (msg_conv != null) {
                    send_xmpp_message(message, msg_conv, true);
                }
            } catch (InvalidJidError e) {
                warning("Ignoring message with invalid Jid: %s", e.message);
            }
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_message.connect( (stream, message) => {
            on_message_received.begin(account, message);
        });
        XmppStream? stream_bak = null;
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.MessageArchiveManagement.Module.IDENTITY).feature_available.connect( (stream) => {
            if (stream == stream_bak) return;

            current_catchup_id.unset(account);
            stream_bak = stream;
            debug("MAM: [%s] MAM available", account.bare_jid.to_string());
            do_mam_catchup.begin(account);
        });

        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_message_unprocessed.connect((stream, message) => {
            if (!message.from.equals(account.bare_jid)) return;

            Xep.MessageArchiveManagement.Flag? mam_flag = stream != null ? stream.get_flag(Xep.MessageArchiveManagement.Flag.IDENTITY) : null;
            if (mam_flag == null) return;
            string? id = message.stanza.get_deep_attribute(mam_flag.ns_ver + ":result", "id");
            if (id == null) return;
            StanzaNode? delay_node = message.stanza.get_deep_subnode(mam_flag.ns_ver + ":result", "urn:xmpp:forward:0:forwarded", "urn:xmpp:delay:delay");
            if (delay_node == null) return;
            DateTime? time = DelayedDelivery.get_time_for_node(delay_node);
            if (time == null) return;
            mam_times[account][id] = time;

            string? query_id = message.stanza.get_deep_attribute(mam_flag.ns_ver + ":result", mam_flag.ns_ver + ":queryid");
            if (query_id != null && id == catchup_until_id[account]) {
                debug("MAM: [%s] Hitted range (id) %s", account.bare_jid.to_string(), id);
                hitted_range[query_id] = -2;
            }
        });
    }

    private async void do_mam_catchup(Account account) {
        debug("MAM: [%s] Start catchup", account.bare_jid.to_string());
        string? earliest_id = null;
        DateTime? earliest_time = null;
        bool continue_sync = true;

        while (continue_sync) {
            continue_sync = false;

            // Get previous row
            var previous_qry = db.mam_catchup.select().with(db.mam_catchup.account_id, "=", account.id).order_by(db.mam_catchup.to_time, "DESC");
            if (current_catchup_id.has_key(account)) {
                previous_qry.with(db.mam_catchup.id, "!=", current_catchup_id[account]);
            }
            RowOption previous_row = previous_qry.single().row();
            if (previous_row.is_present()) {
                catchup_until_id[account] = previous_row[db.mam_catchup.to_id];
                catchup_until_time[account] = (new DateTime.from_unix_utc(previous_row[db.mam_catchup.to_time])).add_minutes(-5);
                debug("MAM: [%s] Previous entry exists", account.bare_jid.to_string());
            } else {
                catchup_until_id.unset(account);
                catchup_until_time.unset(account);
            }

            string query_id = Xmpp.random_uuid();
            yield get_mam_range(account, query_id, null, null, earliest_time, earliest_id);

            if (!hitted_range.has_key(query_id)) {
                debug("MAM: [%s] Set catchup end reached", account.bare_jid.to_string());
                db.mam_catchup.update()
                    .set(db.mam_catchup.from_end, true)
                    .with(db.mam_catchup.id, "=", current_catchup_id[account])
                    .perform();
            }

            if (hitted_range.has_key(query_id)) {
                if (merge_ranges(account, null)) {
                    RowOption current_row = db.mam_catchup.row_with(db.mam_catchup.id, current_catchup_id[account]);
                    bool range_from_complete = current_row[db.mam_catchup.from_end];
                    if (!range_from_complete) {
                        continue_sync = true;
                        earliest_id = current_row[db.mam_catchup.from_id];
                        earliest_time = (new DateTime.from_unix_utc(current_row[db.mam_catchup.from_time])).add_seconds(1);
                    }
                }
            }
        }
    }

    /*
     * Merges the row with `current_catchup_id` with the previous range (optional: with `earlier_id`)
     * Changes `current_catchup_id` to the previous range
     */
    private bool merge_ranges(Account account, int? earlier_id) {
        RowOption current_row = db.mam_catchup.row_with(db.mam_catchup.id, current_catchup_id[account]);
        RowOption previous_row = null;

        if (earlier_id != null) {
            previous_row = db.mam_catchup.row_with(db.mam_catchup.id, earlier_id);
        } else {
            previous_row = db.mam_catchup.select()
                .with(db.mam_catchup.account_id, "=", account.id)
                .with(db.mam_catchup.id, "!=", current_catchup_id[account])
                .order_by(db.mam_catchup.to_time, "DESC").single().row();
        }

        if (!previous_row.is_present()) {
            debug("MAM: [%s] Merging: No previous row", account.bare_jid.to_string());
            return false;
        }

        var qry = db.mam_catchup.update().with(db.mam_catchup.id, "=", previous_row[db.mam_catchup.id]);
        debug("MAM: [%s] Merging %ld-%ld with %ld- %ld", account.bare_jid.to_string(), previous_row[db.mam_catchup.from_time], previous_row[db.mam_catchup.to_time], current_row[db.mam_catchup.from_time], current_row[db.mam_catchup.to_time]);
        if (current_row[db.mam_catchup.from_time] < previous_row[db.mam_catchup.from_time]) {
            qry.set(db.mam_catchup.from_id, current_row[db.mam_catchup.from_id])
                    .set(db.mam_catchup.from_time, current_row[db.mam_catchup.from_time]);
        }
        if (current_row[db.mam_catchup.to_time] > previous_row[db.mam_catchup.to_time]) {
            qry.set(db.mam_catchup.to_id, current_row[db.mam_catchup.to_id])
                .set(db.mam_catchup.to_time, current_row[db.mam_catchup.to_time]);
        }
        qry.perform();

        current_catchup_id[account] = previous_row[db.mam_catchup.id];

        db.mam_catchup.delete().with(db.mam_catchup.id, "=", current_row[db.mam_catchup.id]).perform();

        return true;
    }

    private async bool get_mam_range(Account account, string? query_id, DateTime? from_time, string? from_id, DateTime? to_time, string? to_id) {
        debug("MAM: [%s] Get range %s - %s", account.bare_jid.to_string(), from_time != null ? from_time.to_string() : "", to_time != null ? to_time.to_string() : "");
        XmppStream stream = stream_interactor.get_stream(account);

        Iq.Stanza? iq = yield stream.get_module(Xep.MessageArchiveManagement.Module.IDENTITY).query_archive(stream, null, query_id, from_time, from_id, to_time, to_id);

        if (iq == null) {
            debug(@"MAM: [%s] IQ null", account.bare_jid.to_string());
            return true;
        }

        if (iq.stanza.get_deep_string_content("urn:xmpp:mam:2:fin", "http://jabber.org/protocol/rsm" + ":set", "first") == null) {
            return true;
        }

        while (iq != null) {
            string? earliest_id = iq.stanza.get_deep_string_content("urn:xmpp:mam:2:fin", "http://jabber.org/protocol/rsm" + ":set", "first");
            if (earliest_id == null) return true;

            if (!mam_times[account].has_key(earliest_id)) error("wtf");

            debug("MAM: [%s] Update from_id %s", account.bare_jid.to_string(), earliest_id);
            if (!current_catchup_id.has_key(account)) {
                debug("MAM: [%s] We get our first MAM page", account.bare_jid.to_string());
                string? latest_id = iq.stanza.get_deep_string_content("urn:xmpp:mam:2:fin", "http://jabber.org/protocol/rsm" + ":set", "last");
                if (!mam_times[account].has_key(latest_id)) error("wtf2");
                current_catchup_id[account] = (int) db.mam_catchup.insert()
                        .value(db.mam_catchup.account_id, account.id)
                        .value(db.mam_catchup.from_id, earliest_id)
                        .value(db.mam_catchup.from_time, (long)mam_times[account][earliest_id].to_unix())
                        .value(db.mam_catchup.to_id, latest_id)
                        .value(db.mam_catchup.to_time, (long)mam_times[account][latest_id].to_unix())
                        .perform();
            } else {
                // Update existing id
                db.mam_catchup.update()
                        .set(db.mam_catchup.from_id, earliest_id)
                        .set(db.mam_catchup.from_time, (long)mam_times[account][earliest_id].to_unix()) // need to make sure we have this
                        .with(db.mam_catchup.id, "=", current_catchup_id[account])
                        .perform();
            }

            TimeSpan catchup_time_ago = (new DateTime.now_utc()).difference(mam_times[account][earliest_id]);
            int wait_ms = 10;
            if (catchup_time_ago > 14 * TimeSpan.DAY) {
                wait_ms = 2000;
            } else if (catchup_time_ago > 5 * TimeSpan.DAY) {
                wait_ms = 1000;
            } else if (catchup_time_ago > 2 * TimeSpan.DAY) {
                wait_ms = 200;
            } else if (catchup_time_ago > TimeSpan.DAY) {
                wait_ms = 50;
            }

            mam_times[account] = new HashMap<string, DateTime>();

            Timeout.add(wait_ms, () => {
                if (hitted_range.has_key(query_id)) {
                    debug(@"MAM: [%s] Hitted contains key %s", account.bare_jid.to_string(), query_id);
                    iq = null;
                    Idle.add(get_mam_range.callback);
                    return false;
                }

                stream.get_module(Xep.MessageArchiveManagement.Module.IDENTITY).page_through_results.begin(stream, null, query_id, from_time, to_time, iq, (_, res) => {
                    iq = stream.get_module(Xep.MessageArchiveManagement.Module.IDENTITY).page_through_results.end(res);
                    Idle.add(get_mam_range.callback);
                });
                return false;
            });
            yield;
        }
        return false;
    }

    private async void on_message_received(Account account, Xmpp.MessageStanza message_stanza) {
        Entities.Message message = yield parse_message_stanza(account, message_stanza);

        Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
        if (conversation == null) return;

        // MAM state database update
        Xep.MessageArchiveManagement.MessageFlag mam_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message_stanza);
        if (mam_flag == null) {
            if (current_catchup_id.has_key(account)) {
                string? stanza_id = UniqueStableStanzaIDs.get_stanza_id(message_stanza, account.bare_jid);
                if (stanza_id != null) {
                    db.mam_catchup.update()
                        .with(db.mam_catchup.id, "=", current_catchup_id[account])
                        .set(db.mam_catchup.to_time, (long)message.local_time.to_unix())
                        .set(db.mam_catchup.to_id, stanza_id)
                        .perform();
                }
            }
        }

        bool abort = yield received_pipeline.run(message, message_stanza, conversation);
        if (abort) return;

        if (message.direction == Entities.Message.DIRECTION_RECEIVED) {
            message_received(message, conversation);
        } else if (message.direction == Entities.Message.DIRECTION_SENT) {
            message_sent(message, conversation);
        }

        message_sent_or_received(message, conversation);
    }

    public async Entities.Message parse_message_stanza(Account account, Xmpp.MessageStanza message) {
        Entities.Message new_message = new Entities.Message(message.body);
        new_message.account = account;
        new_message.stanza_id = Xep.UniqueStableStanzaIDs.get_origin_id(message) ?? message.id;

        Jid? counterpart_override = null;
        if (message.from.equals(stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(message.from.bare_jid, account))) {
            new_message.direction = Entities.Message.DIRECTION_SENT;
            counterpart_override = message.from.bare_jid;
        } else if (account.bare_jid.equals_bare(message.from)) {
            new_message.direction = Entities.Message.DIRECTION_SENT;
        } else {
            new_message.direction = Entities.Message.DIRECTION_RECEIVED;
        }
        new_message.counterpart = counterpart_override ?? (new_message.direction == Entities.Message.DIRECTION_SENT ? message.to : message.from);
        new_message.ourpart = new_message.direction == Entities.Message.DIRECTION_SENT ? message.from : message.to;

        XmppStream? stream = stream_interactor.get_stream(account);
        Xep.MessageArchiveManagement.MessageFlag? mam_message_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(message);
        Xep.MessageArchiveManagement.Flag? mam_flag = stream != null ? stream.get_flag(Xep.MessageArchiveManagement.Flag.IDENTITY) : null;
        Xep.ServiceDiscovery.Module disco_module = stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY);
        if (mam_message_flag != null && mam_flag != null && mam_flag.ns_ver == Xep.MessageArchiveManagement.NS_URI_2 && mam_message_flag.mam_id != null) {
            new_message.server_id = mam_message_flag.mam_id;
        } else if (message.type_ == Xmpp.MessageStanza.TYPE_GROUPCHAT) {
            bool server_supports_sid = (yield disco_module.has_entity_feature(stream, new_message.counterpart.bare_jid, Xep.UniqueStableStanzaIDs.NS_URI)) ||
                    (yield disco_module.has_entity_feature(stream, new_message.counterpart.bare_jid, Xep.MessageArchiveManagement.NS_URI_2));
            if (server_supports_sid) {
                new_message.server_id = Xep.UniqueStableStanzaIDs.get_stanza_id(message, new_message.counterpart.bare_jid);
            }
        } else if (message.type_ == Xmpp.MessageStanza.TYPE_CHAT) {
            bool server_supports_sid = (yield disco_module.has_entity_feature(stream, account.bare_jid, Xep.UniqueStableStanzaIDs.NS_URI)) ||
                    (yield disco_module.has_entity_feature(stream, account.bare_jid, Xep.MessageArchiveManagement.NS_URI_2));
            if (server_supports_sid) {
                new_message.server_id = Xep.UniqueStableStanzaIDs.get_stanza_id(message, account.bare_jid);
            }
        }

        if (mam_message_flag != null) new_message.local_time = mam_message_flag.server_time;
        DateTime now = new DateTime.from_unix_utc(new DateTime.now_utc().to_unix()); // Remove milliseconds. They are not stored in the db and might lead to ordering issues when compared with times from the db.
        if (new_message.local_time == null || new_message.local_time.compare(now) > 0) new_message.local_time = now;

        Xep.DelayedDelivery.MessageFlag? delayed_message_flag = Xep.DelayedDelivery.MessageFlag.get_flag(message);
        if (delayed_message_flag != null) new_message.time = delayed_message_flag.datetime;
        if (new_message.time == null || new_message.time.compare(new_message.local_time) > 0) new_message.time = new_message.local_time;

        new_message.type_ = yield determine_message_type(account, message, new_message);

        return new_message;
    }

    private async Entities.Message.Type determine_message_type(Account account, Xmpp.MessageStanza message_stanza, Entities.Message message) {
        if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_GROUPCHAT) {
            return Entities.Message.Type.GROUPCHAT;
        }
        if (message_stanza.type_ == Xmpp.MessageStanza.TYPE_CHAT) {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(message.counterpart.bare_jid, account);
            if (conversation != null) {
                if (conversation.type_ == Conversation.Type.CHAT) {
                    return Entities.Message.Type.CHAT;
                } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    return Entities.Message.Type.GROUPCHAT_PM;
                }
            } else {
                XmppStream stream = stream_interactor.get_stream(account);
                if (stream != null) {
                    Gee.Set<Xep.ServiceDiscovery.Identity>? identities = yield stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).get_entity_identities(stream, message.counterpart.bare_jid);
                    if (identities == null) {
                        return Entities.Message.Type.CHAT;
                    }
                    foreach (Xep.ServiceDiscovery.Identity identity in identities) {
                        if (identity.category == Xep.ServiceDiscovery.Identity.CATEGORY_CONFERENCE) {
                            return Entities.Message.Type.GROUPCHAT_PM;
                        } else {
                            return Entities.Message.Type.CHAT;
                        }
                    }
                }
            }
        }
        return Entities.Message.Type.CHAT;
    }

    private class DeduplicateMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "FILTER_EMPTY", "MUC" };
        public override string action_group { get { return "DEDUPLICATE"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private MessageProcessor outer;
        private Database db;

        public DeduplicateMessageListener(MessageProcessor outer, Database db) {
            this.outer = outer;
            this.db = db;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            Account account = conversation.account;

            Xep.MessageArchiveManagement.MessageFlag? mam_flag = Xep.MessageArchiveManagement.MessageFlag.get_flag(stanza);

            // Deduplicate by server_id
            if (message.server_id != null) {
                QueryBuilder builder =  db.message.select()
                        .with(db.message.server_id, "=", message.server_id)
                        .with(db.message.counterpart_id, "=", db.get_jid_id(message.counterpart))
                        .with(db.message.account_id, "=", account.id);
                bool duplicate = builder.count() > 0;

                if (duplicate && mam_flag != null) {
                    debug(@"MAM: [%s] Hitted range duplicate server id. id %s qid %s", account.bare_jid.to_string(), message.server_id, mam_flag.query_id);
                    if (outer.catchup_until_time.has_key(account) && mam_flag.server_time.compare(outer.catchup_until_time[account]) < 0) {
                        outer.hitted_range[mam_flag.query_id] = -1;
                        debug(@"MAM: [%s] In range (time) %s < %s", account.bare_jid.to_string(), mam_flag.server_time.to_string(), outer.catchup_until_time[account].to_string());
                    }
                }
                if (duplicate) return true;
            }

            // Deduplicate messages by uuid
            bool is_uuid = message.stanza_id != null && Regex.match_simple("""[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}""", message.stanza_id);
            if (is_uuid) {
                QueryBuilder builder =  db.message.select()
                        .with(db.message.stanza_id, "=", message.stanza_id)
                        .with(db.message.counterpart_id, "=", db.get_jid_id(message.counterpart))
                        .with(db.message.account_id, "=", account.id);
                if (message.direction == Message.DIRECTION_RECEIVED) {
                    if (message.counterpart.resourcepart != null) {
                        builder.with(db.message.counterpart_resource, "=", message.counterpart.resourcepart);
                    } else {
                        builder.with_null(db.message.counterpart_resource);
                    }
                } else if (message.direction == Message.DIRECTION_SENT) {
                    if (message.ourpart.resourcepart != null) {
                        builder.with(db.message.our_resource, "=", message.ourpart.resourcepart);
                    } else {
                        builder.with_null(db.message.our_resource);
                    }
                }
                RowOption row_opt = builder.single().row();
                bool duplicate = row_opt.is_present();

                if (duplicate && mam_flag != null && row_opt[db.message.server_id] == null &&
                        outer.catchup_until_time.has_key(account) && mam_flag.server_time.compare(outer.catchup_until_time[account]) > 0) {
                    outer.hitted_range[mam_flag.query_id] = -1;
                    debug(@"MAM: [%s] Hitted range duplicate message id. id %s qid %s", account.bare_jid.to_string(), message.stanza_id, mam_flag.query_id);
                }
                return duplicate;
            }

            // Deduplicate messages based on content and metadata
            QueryBuilder builder = db.message.select()
                    .with(db.message.account_id, "=", account.id)
                    .with(db.message.counterpart_id, "=", db.get_jid_id(message.counterpart))
                    .with(db.message.body, "=", message.body)
                    .with(db.message.time, "<", (long) message.time.add_minutes(1).to_unix())
                    .with(db.message.time, ">", (long) message.time.add_minutes(-1).to_unix());
            if (message.stanza_id != null) {
                builder.with(db.message.stanza_id, "=", message.stanza_id);
            } else {
                builder.with_null(db.message.stanza_id);
            }
            if (message.counterpart.resourcepart != null) {
                builder.with(db.message.counterpart_resource, "=", message.counterpart.resourcepart);
            } else {
                builder.with_null(db.message.counterpart_resource);
            }
            return builder.count() > 0;
        }
    }

    private class FilterMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DECRYPT" };
        public override string action_group { get { return "FILTER_EMPTY"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            return (message.body == null);
        }
    }

    private class StoreMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE", "DECRYPT", "FILTER_EMPTY" };
        public override string action_group { get { return "STORE"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public StoreMessageListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (message.body == null) return true;
            stream_interactor.get_module(MessageStorage.IDENTITY).add_message(message, conversation);
            return false;
        }
    }

    private class StoreContentItemListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE", "DECRYPT", "FILTER_EMPTY", "STORE", "CORRECTION" };
        public override string action_group { get { return "STORE_CONTENT_ITEM"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public StoreContentItemListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            if (message.body == null) return true;
            stream_interactor.get_module(ContentItemStore.IDENTITY).insert_message(message, conversation);
            return false;
        }
    }

    private class MamMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "DEDUPLICATE" };
        public override string action_group { get { return "MAM_NODE"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;

        public MamMessageListener(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            bool is_mam_message = Xep.MessageArchiveManagement.MessageFlag.get_flag(stanza) != null;
            XmppStream? stream = stream_interactor.get_stream(conversation.account);
            Xep.MessageArchiveManagement.Flag? mam_flag = stream != null ? stream.get_flag(Xep.MessageArchiveManagement.Flag.IDENTITY) : null;
            if (is_mam_message || (mam_flag != null && mam_flag.cought_up == true)) {
                conversation.account.mam_earliest_synced = message.local_time;
            }
            return false;
        }
    }

    public Entities.Message create_out_message(string text, Conversation conversation) {
        Entities.Message message = new Entities.Message(text);
        message.type_ = Util.get_message_type_for_conversation(conversation);
        message.stanza_id = random_uuid();
        message.account = conversation.account;
        message.body = text;
        DateTime now = new DateTime.from_unix_utc(new DateTime.now_utc().to_unix()); // Remove milliseconds. They are not stored in the db and might lead to ordering issues when compared with times from the db.
        message.time = now;
        message.local_time = now;
        message.direction = Entities.Message.DIRECTION_SENT;
        message.counterpart = conversation.counterpart;
        if (conversation.type_.is_muc_semantic()) {
            message.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.bare_jid;
            message.real_jid = conversation.account.bare_jid;
        } else {
            message.ourpart = conversation.account.full_jid;
        }
        message.marked = Entities.Message.Marked.UNSENT;
        message.encryption = conversation.encryption;
        return message;
    }

    public void send_xmpp_message(Entities.Message message, Conversation conversation, bool delayed = false) {
        XmppStream stream = stream_interactor.get_stream(conversation.account);
        message.marked = Entities.Message.Marked.NONE;

        if (stream == null) {
            message.marked = Entities.Message.Marked.UNSENT;
            return;
        }

        MessageStanza new_message = new MessageStanza(message.stanza_id);
        new_message.to = message.counterpart;
        new_message.body = message.body;
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            new_message.type_ = MessageStanza.TYPE_GROUPCHAT;
        } else {
            new_message.type_ = MessageStanza.TYPE_CHAT;
        }
        build_message_stanza(message, new_message, conversation);
        pre_message_send(message, new_message, conversation);
        if (message.marked == Entities.Message.Marked.UNSENT || message.marked == Entities.Message.Marked.WONTSEND) return;
        if (delayed) {
            DelayedDelivery.Module.set_message_delay(new_message, message.time);
        }

        // Set an origin ID if a MUC doen't guarantee to keep IDs
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Xep.Muc.Flag? flag = stream.get_flag(Xep.Muc.Flag.IDENTITY);
            if (flag == null) {
                message.marked = Entities.Message.Marked.UNSENT;
                return;
            }
            if(!flag.has_room_feature(conversation.counterpart, Xep.Muc.Feature.STABLE_ID)) {
                UniqueStableStanzaIDs.set_origin_id(new_message, message.stanza_id);
            }
        }

        stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, new_message, (_, res) => {
            try {
                stream.get_module(MessageModule.IDENTITY).send_message.end(res);

                // The server might not have given us the resource we asked for. In that case, store the actual resource the message was sent with. Relevant for deduplication.
                Jid? current_own_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
                if (!conversation.type_.is_muc_semantic() && current_own_jid != null && !current_own_jid.equals(message.ourpart)) {
                    message.ourpart = current_own_jid;
                }
            } catch (IOStreamError e) {
                message.marked = Entities.Message.Marked.UNSENT;
            }
        });
    }
}

public abstract class MessageListener : Xmpp.OrderedListener {

    public abstract async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation);
}

public class MessageListenerHolder : Xmpp.ListenerHolder {

    public async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        foreach (OrderedListener ol in listeners) {
            MessageListener l = ol as MessageListener;
            bool stop = yield l.run(message, stanza, conversation);
            if (stop) return true;
        }
        return false;
    }
}

}
