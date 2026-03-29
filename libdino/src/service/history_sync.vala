using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Qlite;

public class Dino.HistorySync {

    public signal void syncing(bool before);
    public signal void syncing_done();

    private StreamInteractor stream_interactor;
    private Database db;

    public HashMap<Account, HashMap<Jid, int>> current_catchup_id = new HashMap<Account, HashMap<Jid, int>>(Account.hash_func, Account.equals_func);
    public WeakMap<Account, XmppStream> sync_streams = new WeakMap<Account, XmppStream>(Account.hash_func, Account.equals_func);
    public HashMap<Account, HashMap<Jid, Cancellable>> cancellables = new HashMap<Account, HashMap<Jid, Cancellable>>(Account.hash_func, Account.equals_func);
    public HashMap<Account, HashMap<string, DateTime>> mam_times = new HashMap<Account, HashMap<string, DateTime>>();
    public HashMap<string, int> hitted_range = new HashMap<string, int>();

    private HashMap<Conversation, HashMap<bool, PageRequestResult>> mam_cursors = new HashMap<Conversation, HashMap<bool, PageRequestResult?>>(Conversation.hash_func, Conversation.equals_func);

    // Server ID of the latest message of the previous segment
    public HashMap<Account, string> catchup_until_id = new HashMap<Account, string>(Account.hash_func, Account.equals_func);
    // Time of the latest message of the previous segment
    public HashMap<Account, DateTime> catchup_until_time = new HashMap<Account, DateTime>(Account.hash_func, Account.equals_func);

    private HashMap<string, Gee.List<Xmpp.MessageStanza>> stanzas = new HashMap<string, Gee.List<Xmpp.MessageStanza>>();

    // Conversations for which we have successfully synced forwards this session.
    // Cleared when the stream reconnects, since we may have missed messages while disconnected.
    private HashSet<Conversation> forwards_synced = new HashSet<Conversation>(Conversation.hash_func, Conversation.equals_func);

    public HistorySync(Database db, StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.account_added.connect(on_account_added);

        stream_interactor.stream_negotiated.connect((account, stream) => {
            if (current_catchup_id.has_key(account)) {
                debug("MAM: [%s] Reset catchup_id", account.bare_jid.to_string());
                current_catchup_id[account].clear();
            }
            // Any forwards sync state for this account is stale after a reconnect
            var stale = new Gee.ArrayList<Conversation>();
            foreach (var conv in forwards_synced) {
                if (conv.account.equals(account)) stale.add(conv);
            }
            forwards_synced.remove_all(stale);
        });
    }

    public bool process(Account account, Xmpp.MessageStanza message_stanza) {
        var mam_flag = Xmpp.MessageArchiveManagement.MessageFlag.get_flag(message_stanza);

        if (mam_flag != null) {
            process_mam_message(account, message_stanza, mam_flag);
            return true;
        } else {
            update_latest_db_range(account, message_stanza);
            return false;
        }
    }

    public async bool can_do_mam(Conversation conversation) {
        Jid mam_server = conversation.type_ == Conversation.Type.GROUPCHAT
            ? conversation.counterpart.bare_jid
            : conversation.account.bare_jid;
        return yield stream_interactor.get_module(EntityInfo.IDENTITY)
            .has_feature(conversation.account, mam_server,
                         Xmpp.MessageArchiveManagement.NS_URI);
    }

    public void update_latest_db_range(Account account, Xmpp.MessageStanza message_stanza) {
        Jid mam_server = stream_interactor.get_module(MucManager.IDENTITY).might_be_groupchat(message_stanza.from.bare_jid, account) ? message_stanza.from.bare_jid : account.bare_jid;

        if (!current_catchup_id.has_key(account) || !current_catchup_id[account].has_key(mam_server)) return;

        string? stanza_id = UniqueStableStanzaIDs.get_stanza_id(message_stanza, mam_server);
        if (stanza_id == null) return;

        db.mam_catchup.update()
                .with(db.mam_catchup.id, "=", current_catchup_id[account][mam_server])
                .set(db.mam_catchup.to_time, (long)new DateTime.now_utc().to_unix())
                .set(db.mam_catchup.to_id, stanza_id)
                .perform();
    }

    public void process_mam_message(Account account, Xmpp.MessageStanza message_stanza, Xmpp.MessageArchiveManagement.MessageFlag mam_flag) {
        Jid mam_server = mam_flag.sender_jid;
        Jid message_author = message_stanza.from;

        // MUC servers may only send MAM messages from that MUC
        bool is_muc_mam = stream_interactor.get_module(MucManager.IDENTITY).might_be_groupchat(mam_server, account) &&
                message_author.equals_bare(mam_server);

        bool from_our_server = mam_server.equals_bare(account.bare_jid);

        if (!is_muc_mam && !from_our_server) {
            warning("Received alleged MAM message from %s, ignoring", mam_server.to_string());
            return;
        }

        if (!stanzas.has_key(mam_flag.query_id)) stanzas[mam_flag.query_id] = new ArrayList<Xmpp.MessageStanza>();
        stanzas[mam_flag.query_id].add(message_stanza);
    }

    private void on_unprocessed_message(Account account, XmppStream stream, MessageStanza message) {
        // Check that it's a legit MAM server
        bool is_muc_mam = stream_interactor.get_module(MucManager.IDENTITY).might_be_groupchat(message.from, account);
        bool from_our_server = message.from.equals_bare(account.bare_jid);
        if (!is_muc_mam && !from_our_server) return;

        // Get the server time of the message and store it in `mam_times`
        string? id = message.stanza.get_deep_attribute(Xmpp.MessageArchiveManagement.NS_URI + ":result", "id");
        if (id == null) return;
        StanzaNode? delay_node = message.stanza.get_deep_subnode(Xmpp.MessageArchiveManagement.NS_URI + ":result", StanzaForwarding.NS_URI + ":forwarded", DelayedDelivery.NS_URI + ":delay");
        if (delay_node == null) {
            warning("MAM result did not contain delayed time %s", message.stanza.to_string());
            return;
        }
        DateTime? time = DelayedDelivery.get_time_for_node(delay_node);
        if (time == null) return;
        mam_times[account][id] = time;

        // Check if this is the target message
        string? query_id = message.stanza.get_deep_attribute(Xmpp.MessageArchiveManagement.NS_URI + ":result", Xmpp.MessageArchiveManagement.NS_URI + ":queryid");
        if (query_id != null && id == catchup_until_id[account]) {
            debug("[%s] Hitted range (id) %s", account.bare_jid.to_string(), id);
            hitted_range[query_id] = -2;
        }
    }

    public void on_server_id_duplicate(Account account, Xmpp.MessageStanza message_stanza, Entities.Message message) {
        Xmpp.MessageArchiveManagement.MessageFlag? mam_flag = Xmpp.MessageArchiveManagement.MessageFlag.get_flag(message_stanza);
        if (mam_flag == null) return;

//        debug(@"MAM: [%s] Hitted range duplicate server id. id %s qid %s", account.bare_jid.to_string(), message.server_id, mam_flag.query_id);
        if (catchup_until_time.has_key(account) && mam_flag.server_time.compare(catchup_until_time[account]) < 0) {
            hitted_range[mam_flag.query_id] = -1;
//            debug(@"MAM: [%s] In range (time) %s < %s", account.bare_jid.to_string(), mam_flag.server_time.to_string(), catchup_until_time[account].to_string());
        }
    }

    // public async void fetch_everything(Account account, Jid mam_server, Cancellable? cancellable = null, DateTime until_earliest_time = new DateTime.from_unix_utc(0)) {
    //     debug("[%s | %s] Fetch everything %s", account.bare_jid.to_string(), mam_server.to_string(), until_earliest_time != null ? @"(until $until_earliest_time)" : "");
    //     RowOption latest_row_opt = db.mam_catchup.select()
    //             .with(db.mam_catchup.account_id, "=", account.id)
    //             .with(db.mam_catchup.server_jid, "=", mam_server.to_string())
    //             .with(db.mam_catchup.to_time, ">=", (long) until_earliest_time.to_unix())
    //             .order_by(db.mam_catchup.to_time, "DESC")
    //             .single().row();
    //     Row? latest_row = latest_row_opt.is_present() ? latest_row_opt.inner : null;

    //     Row? new_row = yield fetch_latest_page(account, mam_server, null, latest_row, until_earliest_time, cancellable);

    //     if (new_row != null) {
    //         current_catchup_id[account][mam_server] = new_row[db.mam_catchup.id];
    //     } else if (latest_row != null) {
    //         current_catchup_id[account][mam_server] = latest_row[db.mam_catchup.id];
    //     }

    //     // Set the previous and current row
    //     Row? previous_row = null;
    //     Row? current_row = null;
    //     if (new_row != null) {
    //         current_row = new_row;
    //         previous_row = latest_row;
    //     } else if (latest_row != null) {
    //         current_row = latest_row;
    //         RowOption previous_row_opt = db.mam_catchup.select()
    //                 .with(db.mam_catchup.account_id, "=", account.id)
    //                 .with(db.mam_catchup.server_jid, "=", mam_server.to_string())
    //                 .with(db.mam_catchup.to_time, "<", current_row[db.mam_catchup.from_time])
    //                 .with(db.mam_catchup.to_time, ">=", (long) until_earliest_time.to_unix())
    //                 .order_by(db.mam_catchup.to_time, "DESC")
    //                 .single().row();
    //         previous_row = previous_row_opt.is_present() ? previous_row_opt.inner : null;
    //     }

    //     // Fetch messages between two db ranges and merge them
    //     while (current_row != null && previous_row != null) {
    //         if (current_row[db.mam_catchup.from_end]) {
    //             debug("[%s | %s] No logs on server before %s, aborting sync.", account.bare_jid.to_string(), mam_server.to_string(), current_row[db.mam_catchup.from_time].to_string());
    //             return;
    //         }

    //         debug("[%s | %s] Fetching between ranges %s - %s", account.bare_jid.to_string(), mam_server.to_string(), previous_row[db.mam_catchup.to_time].to_string(), current_row[db.mam_catchup.from_time].to_string());
    //         current_row = yield fetch_between_ranges(account, mam_server, null, previous_row, current_row, cancellable);
    //         if (current_row == null) return;

    //         RowOption previous_row_opt = db.mam_catchup.select()
    //                 .with(db.mam_catchup.account_id, "=", account.id)
    //                 .with(db.mam_catchup.server_jid, "=", mam_server.to_string())
    //                 .with(db.mam_catchup.to_time, "<", current_row[db.mam_catchup.from_time])
    //                 .with(db.mam_catchup.to_time, ">=", (long) until_earliest_time.to_unix())
    //                 .order_by(db.mam_catchup.to_time, "DESC")
    //                 .single().row();
    //         previous_row = previous_row_opt.is_present() ? previous_row_opt.inner : null;
    //     }

    //     // We're at the earliest range. Try to expand it even further back.
    //     if (current_row == null) {
    //         debug("[%s | %s] No current range, aborting sync.", account.bare_jid.to_string(), mam_server.to_string());
    //         return;
    //     } else if (current_row[db.mam_catchup.from_end]) {
    //         debug("[%s | %s] No logs on server before %s, aborting sync.", account.bare_jid.to_string(), mam_server.to_string(), current_row[db.mam_catchup.from_time].to_string());
    //         return;
    //     }
    //     // We don't want to fetch before the earliest range over and over again in MUCs if it's after until_earliest_time.
    //     // For now, don't query if we are within a week of until_earliest_time
    //     if (until_earliest_time != null && current_row[db.mam_catchup.from_time] <= until_earliest_time.to_unix()) {
    //         debug("[%s | %s] Current range starting %s is before limit %s, aborting sync.", account.bare_jid.to_string(), mam_server.to_string(), current_row[db.mam_catchup.from_time].to_string(), until_earliest_time.to_unix().to_string());
    //         return;
    //     }
    //     yield fetch_before_range(account, mam_server, null, current_row, until_earliest_time);
    // }

    // Fetches the latest page (up to previous db row). Extends the previous db row if it was reached, creates a new row otherwise.
    // public async Row? fetch_latest_page(Account account, Jid mam_server, Jid? counterpart, Row? latest_row, DateTime? until_earliest_time, Cancellable? cancellable = null) {
    //     debug("[%s | %s] Fetching latest page", account.bare_jid.to_string(), mam_server.to_string());

    //     int latest_row_id = -1;
    //     DateTime latest_message_time = until_earliest_time;
    //     string? latest_message_id = null;

    //     if (latest_row != null) {
    //         latest_row_id = latest_row[db.mam_catchup.id];
    //         latest_message_time = (new DateTime.from_unix_utc(latest_row[db.mam_catchup.to_time])).add_minutes(-5);
    //         latest_message_id = latest_row[db.mam_catchup.to_id];

    //         // Make sure we only fetch to until_earliest_time if latest_message_time is further back
    //         if (until_earliest_time != null && latest_message_time.compare(until_earliest_time) < 0) {
    //             latest_message_time = until_earliest_time.add_minutes(-5);
    //             latest_message_id = null;
    //         }
    //     }

    //     var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_latest(mam_server, latest_message_time, latest_message_id);
    //     if (counterpart != null) query_params.with = counterpart;

    //     PageRequestResult page_result = yield get_mam_page(account, query_params, null, cancellable);
    //     debug("[%s | %s] Latest page result: %s", account.bare_jid.to_string(), mam_server.to_string(), page_result.page_result.to_string());

    //     if (page_result.page_result == PageResult.Error || page_result.page_result == PageResult.Cancelled) {
    //         return null;
    //     }

    //     // Catchup finished within first page. Update latest db entry.
    //     if (latest_row_id != -1 &&
    //             page_result.page_result in new PageResult[] { PageResult.TargetReached, PageResult.NoMoreMessages }) {

    //         if (page_result.stanzas == null) return null;

    //         string latest_mam_id = page_result.query_result.last;
    //         long latest_mam_time = (long) mam_times[account][latest_mam_id].to_unix();

    //         var query = db.mam_catchup.update()
    //                 .with(db.mam_catchup.id, "=", latest_row_id)
    //                 .set(db.mam_catchup.to_time, latest_mam_time)
    //                 .set(db.mam_catchup.to_id, latest_mam_id);

    //         if (page_result.page_result == PageResult.NoMoreMessages) {
    //             // If the server doesn't have more messages, store that this range is at its end.
    //             query.set(db.mam_catchup.from_end, true);
    //         }
    //         query.perform();
    //         return null;
    //     }

        // if (page_result.query_result.first == null || page_result.query_result.last == null) {
        //     return null;
        // }

        // Either we need to fetch more pages or this is the first db entry ever
    //     debug("[%s | %s] Creating new db range for latest page", account.bare_jid.to_string(), mam_server.to_string());

    //     string from_id = page_result.query_result.first != null ? page_result.query_result.first : "";
    //     string to_id = page_result.query_result.last != null ? page_result.query_result.last : "";

    //     long from_time = (long) ( mam_times[account].has_key(from_id) ? mam_times[account][from_id].to_unix() : 0 );
    //     long to_time = (long) ( mam_times[account].has_key(to_id) ? mam_times[account][to_id].to_unix() : 0 );

    //     int new_row_id = (int) db.mam_catchup.insert()
    //             .value(db.mam_catchup.account_id, account.id)
    //             .value(db.mam_catchup.server_jid, mam_server.to_string())
    //             .value(db.mam_catchup.counterpart_jid, counterpart != null ? counterpart.to_string() : null)
    //             .value(db.mam_catchup.from_id, from_id)
    //             .value(db.mam_catchup.from_time, from_time)
    //             .value(db.mam_catchup.from_end, page_result.page_result == PageResult.NoMoreMessages)
    //             .value(db.mam_catchup.to_id, to_id)
    //             .value(db.mam_catchup.to_time, to_time)
    //             .perform();
    //     return db.mam_catchup.select().with(db.mam_catchup.id, "=", new_row_id).single().row().inner;
    // }

    /** Fetches messages between the end of `earlier_range` and start of `later_range`
     ** Merges the `earlier_range` db row into the `later_range` db row.
     ** @return The resulting range comprising `earlier_range`, `later_rage`, and everything in between. null if fetching/merge failed.
     **/
    // private async Row? fetch_between_ranges(Account account, Jid mam_server, Jid? counterpart, Row earlier_range, Row later_range, Cancellable? cancellable = null) {
    //     int later_range_id = (int) later_range[db.mam_catchup.id];
    //     DateTime earliest_time = new DateTime.from_unix_utc(earlier_range[db.mam_catchup.to_time]);
    //     DateTime latest_time = new DateTime.from_unix_utc(later_range[db.mam_catchup.from_time]);
    //     debug("[%s | %s] Fetching between %s (%s) and %s (%s)", account.bare_jid.to_string(), mam_server.to_string(), earliest_time.to_string(), earlier_range[db.mam_catchup.to_id], latest_time.to_string(), later_range[db.mam_catchup.from_id]);

    //     var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_between(mam_server,
    //         earliest_time, earlier_range[db.mam_catchup.to_id],
    //         latest_time, later_range[db.mam_catchup.from_id]);
    //     if (counterpart != null) query_params.with = counterpart;

    //     PageRequestResult page_result = yield fetch_query(account, query_params, later_range_id, cancellable);

    //     if (page_result.page_result == PageResult.TargetReached || page_result.page_result == PageResult.NoMoreMessages) {
    //         debug("[%s | %s] Merging range %i into %i", account.bare_jid.to_string(), mam_server.to_string(), earlier_range[db.mam_catchup.id], later_range_id);
    //         // Merge earlier range into later one.
    //         db.mam_catchup.update()
    //             .with(db.mam_catchup.id, "=", later_range_id)
    //             .set(db.mam_catchup.from_time, earlier_range[db.mam_catchup.from_time])
    //             .set(db.mam_catchup.from_id, earlier_range[db.mam_catchup.from_id])
    //             .set(db.mam_catchup.from_end, earlier_range[db.mam_catchup.from_end])
    //             .perform();

    //         db.mam_catchup.delete().with(db.mam_catchup.id, "=", earlier_range[db.mam_catchup.id]).perform();

    //         // Return the updated version of the later range
    //         return db.mam_catchup.select().with(db.mam_catchup.id, "=", later_range_id).single().row().inner;
    //     }

    //     return null;
    // }

    // extend MAM by .. one page?
    // returns 'true' if you should continue calling this; false if the archive is exhausted not
    public async bool fetch_mam(Conversation conversation, bool before = false) {
        debug("fetching %s history for %s:%s", before? "<<<=" : "=>>>", conversation.account.bare_jid.to_string(), conversation.counterpart.to_string());
        Jid mam_server = conversation.type_ == Conversation.Type.GROUPCHAT
            ? conversation.counterpart.bare_jid
            : conversation.account.bare_jid;
        Jid counterpart = conversation.type_ == Conversation.Type.GROUPCHAT
            ? null
            : conversation.counterpart.bare_jid;

        var catchup_select = db.mam_catchup.select()
                    .with(db.mam_catchup.account_id, "=", conversation.account.id)
                    .with(db.mam_catchup.server_jid, "=", mam_server.to_string());
        if (counterpart != null) catchup_select.with(db.mam_catchup.counterpart_jid, "=", counterpart.to_string());

        Row? mam_catchup = mam_catchup_row(conversation);

        Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params;
        if (mam_catchup == null) {
            // Do "empty <before/>": https://xmpp.org/extensions/xep-0313.html#sect-idm45587610223104
            query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_latest(mam_server, null, null);
        } else {
            if (before) {
                if (mam_catchup[db.mam_catchup.from_end]) {
                    debug("fetch_mam: already at beginning of history for %s", conversation.counterpart.to_string());
                    return false;
                } else {
                    // time = mam_catchup[db.mam_catchup.from_time]; // todo ?
                    var stanzaid = mam_catchup[db.mam_catchup.from_id];
                    query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_before(mam_server, null, stanzaid);
                }
            } else {
                // For forwards fetch: skip if we already synced forwards this session.
                if (forwards_synced.contains(conversation)) {
                    debug("fetch_mam: have end of history for %s", conversation.counterpart.to_string());
                    return false;
                } else {
                    // time = mam_catchup[db.mam_catchup.to_time];
                    var stanzaid = mam_catchup[db.mam_catchup.from_id];
                    query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_latest(mam_server, null, stanzaid);
                }
            }
        }


        syncing(before);
        try {
            if(!mam_cursors.contains(conversation)) {
                mam_cursors[conversation] = new HashMap<bool, PageRequestResult?>();
            }
            if(!mam_cursors[conversation].contains(before)) {
                debug("making new cursor for %s (mode %s)", conversation.counterpart.to_string(), before.to_string());
                mam_cursors[conversation][before] = null;
            }

            mam_cursors[conversation][before] = yield get_mam_page(conversation, query_params, mam_cursors[conversation][before]/*, TODO: cancellable*/);
            if ( mam_cursors[conversation][before].page_result == PageResult.Error
              || mam_cursors[conversation][before].page_result == PageResult.Cancelled) {
                warning("get_mam_page returned %s", mam_cursors[conversation][before].page_result.to_string());
            }
            if (mam_cursors[conversation][before].page_result != PageResult.MorePagesAvailable) {
                // done. clean up:
                mam_cursors[conversation].unset(before);
                if(mam_cursors[conversation].size == 0) {
                    mam_cursors.unset(conversation);
                }

                return false;
            } else {
                // continue signal to caller to keep going
                return true;
            }
        } finally {
            syncing_done();
        }
    }

    private Row? mam_catchup_row(Conversation conversation) {
        // helper
        Jid mam_server = conversation.type_ == Conversation.Type.GROUPCHAT
            ? conversation.counterpart.bare_jid
            : conversation.account.bare_jid;
        Jid? counterpart = conversation.type_ == Conversation.Type.GROUPCHAT
            ? null
            : conversation.counterpart.bare_jid;

        var select = db.mam_catchup.select()
            .with(db.mam_catchup.account_id, "=", conversation.account.id)
            .with(db.mam_catchup.server_jid, "=", mam_server.to_string());
        if (counterpart != null) select.with(db.mam_catchup.counterpart_jid, "=", counterpart.to_string());
        var row_opt = select.order_by(db.mam_catchup.from_time, "ASC").single().row();

        return row_opt.is_present() ? row_opt.inner : null;
    }

    public bool have_beginning(Conversation conversation) {
        // did we sync back to the "from_end" flag indicating the very start of the chatlog?
        var mam_catchup = mam_catchup_row(conversation);
        return (mam_catchup != null) && mam_catchup[db.mam_catchup.from_end];
    }

    public bool have_ending(Conversation conversation) {
        // did we sync up to the present moment? (we assume we maintain the sync as long as we are connected because we get live updates)
        return forwards_synced.contains(conversation);
    }

    // private async void fetch_after(Account account, Jid mam_server, Jid? counterpart, string stanzaid, Cancellable? cancellable = null) {
    //     debug("[%s | %s | %s] Fetching after > %s", account.bare_jid.to_string(), mam_server.to_string(), counterpart != null ? counterpart : "", stanzaid);

    //     var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_latest(mam_server, null, stanzaid);
    //     if (counterpart != null) query_params.with = counterpart;

    //     yield fetch_query(account, query_params, cancellable);
    // }

    // private async void fetch_before(Account account, Jid mam_server, Jid? counterpart, string stanzaid, Cancellable? cancellable = null) {
    //     debug("[%s | %s | %s] Fetching before < %s", account.bare_jid.to_string(), mam_server.to_string(), counterpart != null ? counterpart : "", stanzaid);

    //     var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_before(mam_server, time, null, stanzaid);
    //     if (counterpart != null) query_params.with = counterpart;

    //     yield fetch_query(account, query_params, cancellable);
    // }
    /**
     * Iteratively fetches all pages returned for a query (until a PageResult other than MorePagesAvailable is returned)

     * Precondition: the database row exists
     * @return The last PageRequestResult result
     **/
    // private async PageRequestResult fetch_query(Account account, Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params, Cancellable? cancellable = null) {
    //     debug("[%s | %s] Fetch query %s - %s - %s",
    //         account.bare_jid.to_string(),
    //         query_params.mam_server.to_string(),
    //         query_params.with != null ? query_params.with.to_string() : "",
    //         query_params.start != null ? query_params.start.to_string() : "",
    //         query_params.end != null ? query_params.end.to_string() : "");

    //     PageRequestResult? page_result = null;
    //     do {
    //         page_result = yield get_mam_page(conversation, query_params, page_result, cancellable);
    //         debug("[%s | %s] Page result %s (got stanzas: %s)", account.bare_jid.to_string(), query_params.mam_server.to_string(), page_result.page_result.to_string(), (page_result.stanzas != null).to_string());
    //     } while (page_result.page_result == PageResult.MorePagesAvailable);

    //     return page_result;
    // }

    enum PageResult {
        MorePagesAvailable,
        TargetReached,
        NoMoreMessages,
        Error,
        Cancelled
    }

    /**
     * prev_page_result: null if this is the first page request
     **/
    private async PageRequestResult get_mam_page(Conversation conversation, Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params, PageRequestResult? prev_page_result, Cancellable? cancellable = null) {
        XmppStream stream = stream_interactor.get_stream(conversation.account);
        Xmpp.MessageArchiveManagement.QueryResult query_result = null;

        if (prev_page_result == null) {
            query_result = yield Xmpp.MessageArchiveManagement.V2.query_archive(stream, query_params, cancellable);
        } else {
            query_result = yield Xmpp.MessageArchiveManagement.V2.page_through_results(stream, query_params, prev_page_result.query_result, cancellable);
        }

        var page_result = yield process_query_result(conversation.account, query_params, query_result, cancellable);

        if ( page_result.page_result == PageResult.Error
          || page_result.page_result == PageResult.Cancelled) {
            return page_result;
        }

        // string earliest_mam_id = page_result.query_result.first;
        // long earliest_mam_time = earliest_mam_id != null ? (long)mam_times[account][earliest_mam_id].to_unix() : 0;

        // if (earliest_mam_id != null) {
        //     debug("[%s | %s] Updating to %s, %s", account.bare_jid.to_string(), query_params.mam_server.to_string(), earliest_mam_time.to_string(), earliest_mam_id);
        //     query.set(db.mam_catchup.from_id, earliest_mam_id);
        //     if (page_result.page_result != PageResult.NoMoreMessages || query_params.start != null || earliest_mam_time < query_params.start.to_unix()) {
        //         query.set(db.mam_catchup.from_time, earliest_mam_time);
        //     }
        // }
        // // TODO: times

        Jid mam_server = conversation.type_ == Conversation.Type.GROUPCHAT
            ? conversation.counterpart.bare_jid
            : conversation.account.bare_jid;
        Jid? counterpart = conversation.type_ == Conversation.Type.GROUPCHAT
            ? null
            : conversation.counterpart.bare_jid;


        // upsert
        Row? mam_catchup = mam_catchup_row(conversation);
        if(mam_catchup == null) {
            if(page_result.query_result.first == null || page_result.query_result.last == null) {
                // the SQLite schema has a NOT NULL on both of these
                // so there's no point trying to record them if they're not defined!
                debug("Don't know about this mam_catchup yet, but also we have a null archive? giving up");
                return page_result;
            }

            debug("Have to make a new mam_catchup");
            var query = db.mam_catchup.insert()
                .value(db.mam_catchup.account_id, conversation.account.id)
                .value(db.mam_catchup.server_jid, mam_server.to_string())
                .value(db.mam_catchup.from_end, false)
                .value(db.mam_catchup.from_id, page_result.query_result.first)
                .value(db.mam_catchup.to_id, page_result.query_result.last)
                .value(db.mam_catchup.from_time, 0)
                .value(db.mam_catchup.to_time, 0);
            if(counterpart != null) {
                query.value(db.mam_catchup.counterpart_jid, counterpart.to_string());
            }
            debug("about to do sql");
            var c = query.perform();
            debug("got back: %l", c);

            // inefficient but whatever
            mam_catchup = mam_catchup_row(conversation);
            debug("we created: %l", mam_catchup[db.mam_catchup.id]);
        }

        // TODO: move this into process_query_result
        debug("Updating mam_catchup.id = %d", mam_catchup[db.mam_catchup.id]);
        var query = db.mam_catchup.update()
                .with(db.mam_catchup.id, "=", mam_catchup[db.mam_catchup.id]);

        if (query_params.start_id == null && query_params.end_id == null) {
            debug("A");
            // this was the <before> case
            if(page_result.query_result.first != null) {
                debug("AA");
                query.set(db.mam_catchup.from_id, page_result.query_result.first);
            }
            if(page_result.query_result.last != null) {
                debug("AB");
                query.set(db.mam_catchup.to_id, page_result.query_result.last);
            }
            // note that if both are null then we're in the degenerate
            // empty archive case; there's no good way to store that fact
            // because we have no stanzas to anchor future queries: they
            // all need to redo the empty-<before/> query. We just eat the
            // cost of this.
        } else if (query_params.start_id != null && query_params.end_id == null) {
            debug("B");
            // this was a forward query, so the end is 'the present'
            query.set(db.mam_catchup.to_id, page_result.query_result.last); // the *last* stanza-id we were given is the outer *forward* ("to") edge of our region
            // query.set(db.mam_catchup.to_time, ...); // TODO

            if (page_result.page_result == PageResult.NoMoreMessages) {
                debug("BA");
                // mark this fully synced with the present
                forwards_synced.add(conversation);
            }

            // debug("[%s | %s] Updating to %s based on query", account.bare_jid.to_string(), query_params.mam_server.to_string(), query_params.start.to_string());
        } else if(query_params.start_id == null && query_params.end_id != null) {
            debug("C");
            // this was a backwards query
            query.set(db.mam_catchup.from_id, page_result.query_result.first);
            // query.set(db.mam_catchup.from_time, ...); // TODO
            if (page_result.page_result == PageResult.NoMoreMessages) {
                debug("CA");
                // mark this fully synced with the past
                forwards_synced.add(conversation);
                query.set(db.mam_catchup.from_end, true);
            }
        } else {
            debug("D");
            warning("MAM between-or-other query exhausted; but we do not handle these cases.");
            warning("QueryParams { query_id=%s, mam_server=%s, with=%s, start=%s, end=%s, start_id=%s, end_id = %s }",
                query_params.query_id,
                query_params.mam_server.to_string(),
                query_params.with != null ? query_params.with.to_string() : "",
                query_params.start != null ? query_params.start.to_string() : "",
                query_params.end != null ? query_params.end.to_string() : "",
                query_params.start_id != null ? query_params.start_id.to_string() : "",
                query_params.end_id != null ? query_params.end_id.to_string() : ""
            );
        }

        debug("Doing last query");
        query.perform();
        debug("it's done");

        return page_result;
    }

    private async PageRequestResult process_query_result(Account account, Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params, Xmpp.MessageArchiveManagement.QueryResult query_result, Cancellable? cancellable = null) {
        PageResult page_result = PageResult.MorePagesAvailable;

        if (query_result.malformed || query_result.error) {
            page_result = PageResult.Error;
        }

        // We wait until all the messages from the page are processed (and we got the `mam_times` from them)
        Idle.add(process_query_result.callback, Priority.LOW);
        yield;

        // We might have successfully reached the target or the server doesn't have all messages stored anymore
        // If it's the former, we'll overwrite the value with PageResult.MorePagesAvailable below.
        if (query_result.complete) {
            page_result = PageResult.NoMoreMessages;
        }

        string query_id = query_params.query_id;
        string? after_id = query_params.start_id;

        var stanzas_for_query = stanzas.has_key(query_id) && !stanzas[query_id].is_empty ? stanzas[query_id] : null;
        if (cancellable != null && cancellable.is_cancelled()) {
            stanzas.unset(query_id);
            return new PageRequestResult(PageResult.Cancelled, query_result, stanzas_for_query);
        }

        if (stanzas_for_query != null) {

            // Check it we reached our target (from_id)
            foreach (Xmpp.MessageStanza message in stanzas_for_query) {
                Xmpp.MessageArchiveManagement.MessageFlag? mam_message_flag = Xmpp.MessageArchiveManagement.MessageFlag.get_flag(message);
                if (mam_message_flag != null && mam_message_flag.mam_id != null) {
                    if (after_id != null && mam_message_flag.mam_id == after_id) {
                        // Successfully fetched the whole range
                        yield send_messages_back_into_pipeline(account, query_id, cancellable);
                        if (cancellable != null && cancellable.is_cancelled()) {
                            return new PageRequestResult(PageResult.Cancelled, query_result, stanzas_for_query);
                        }
                        return new PageRequestResult(PageResult.TargetReached, query_result, stanzas_for_query);
                    }
                }
            }
            if (hitted_range.has_key(query_id) && hitted_range[query_id] == -2) {
                // Message got filtered out by xmpp-vala, but succesful range fetch nevertheless
                yield send_messages_back_into_pipeline(account, query_id);
                if (cancellable != null && cancellable.is_cancelled()) {
                    return new PageRequestResult(PageResult.Cancelled, query_result, stanzas_for_query);
                }
                return new PageRequestResult(PageResult.TargetReached, query_result, stanzas_for_query);
            }
        }

        yield send_messages_back_into_pipeline(account, query_id);
        if (cancellable != null && cancellable.is_cancelled()) {
            page_result = PageResult.Cancelled;
        }
        return new PageRequestResult(page_result, query_result, stanzas_for_query);
    }

    private async void send_messages_back_into_pipeline(Account account, string query_id, Cancellable? cancellable = null) {
        if (!stanzas.has_key(query_id)) return;

        foreach (Xmpp.MessageStanza message in stanzas[query_id]) {
            if (cancellable != null && cancellable.is_cancelled()) break;
            yield stream_interactor.get_module(MessageProcessor.IDENTITY).run_pipeline_announce(account, message);
        }
        stanzas.unset(query_id);
    }

    private void on_account_added(Account account) {
        cleanup_db_ranges(db, account);

        mam_times[account] = new HashMap<string, DateTime>();

        stream_interactor.connection_manager.stream_attached_modules.connect((account, stream) => {
            if (!current_catchup_id.has_key(account)) {
                current_catchup_id[account] = new HashMap<Jid, int>(Jid.hash_func, Jid.equals_func);
            } else {
                current_catchup_id[account].clear();
            }
        });

        stream_interactor.module_manager.get_module(account, Xmpp.MessageArchiveManagement.Module.IDENTITY).feature_available.connect((stream) => {
            // consider_fetch_everything(account, stream);
        });

        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_message_unprocessed.connect((stream, message) => {
            on_unprocessed_message(account, stream, message);
        });
    }

    // private void consider_fetch_everything(Account account, XmppStream stream) {
    //     if (sync_streams.has(account, stream)) return;

    //     debug("[%s] MAM available", account.bare_jid.to_string());
    //     sync_streams[account] = stream;
    //     if (!cancellables.has_key(account)) {
    //         cancellables[account] = new HashMap<Jid, Cancellable>();
    //     }
    //     if (cancellables[account].has_key(account.bare_jid)) {
    //         cancellables[account][account.bare_jid].cancel();
    //     }
    //     cancellables[account][account.bare_jid] = new Cancellable();
    //     fetch_everything.begin(account, account.bare_jid, cancellables[account][account.bare_jid], new DateTime.from_unix_utc(0), (_, res) => {
    //         fetch_everything.end(res);
    //         cancellables[account].unset(account.bare_jid);
    //     });
    // }

    public static void cleanup_db_ranges(Database db, Account account) {
        var ranges = new HashMap<Jid, ArrayList<MamRange>>(Jid.hash_func, Jid.equals_func);
        foreach (Row row in db.mam_catchup.select().with(db.mam_catchup.account_id, "=", account.id)) {
            var mam_range = new MamRange();
            mam_range.id = row[db.mam_catchup.id];
            mam_range.server_jid = new Jid(row[db.mam_catchup.server_jid]);
            mam_range.from_time = row[db.mam_catchup.from_time];
            mam_range.from_id = row[db.mam_catchup.from_id];
            mam_range.from_end = row[db.mam_catchup.from_end];
            mam_range.to_time = row[db.mam_catchup.to_time];
            mam_range.to_id = row[db.mam_catchup.to_id];

            if (!ranges.has_key(mam_range.server_jid)) ranges[mam_range.server_jid] = new ArrayList<MamRange>();
            ranges[mam_range.server_jid].add(mam_range);
        }

        var to_delete = new ArrayList<MamRange>();

        foreach (Jid server_jid in ranges.keys) {
            foreach (var range1 in ranges[server_jid]) {
                if (to_delete.contains(range1)) continue;

                foreach (MamRange range2 in ranges[server_jid]) {
                    debug("[%s | %s] | %s - %s vs %s - %s", account.bare_jid.to_string(), server_jid.to_string(), range1.from_time.to_string(), range1.to_time.to_string(), range2.from_time.to_string(), range2.to_time.to_string());
                    if (range1 == range2 || to_delete.contains(range2)) continue;

                    // Check if range2 is a subset of range1
                    // range1: #####################
                    // range2:         ######
                    if (range1.from_time <= range2.from_time && range1.to_time >= range2.to_time) {
                        warning("Removing db range which is a subset of %li-%li", range1.from_time, range1.to_time);
                        to_delete.add(range2);
                        continue;
                    }

                    // Check if range2 is an extension of range1 (towards earlier)
                    // range1:        #####################
                    // range2: ###############
                    if (range1.from_time <= range2.to_time <= range1.to_time && range2.from_time <= range1.from_time) {
                        warning("Removing db range that overlapped %li-%li (towards earlier)", range1.from_time, range1.to_time);
                        db.mam_catchup.update()
                                .with(db.mam_catchup.id, "=", range1.id)
                                .set(db.mam_catchup.from_id, range2.from_id)
                                .set(db.mam_catchup.from_time, range2.from_time)
                                .set(db.mam_catchup.from_end, range2.from_end)
                                .perform();
                        to_delete.add(range2);
                        continue;
                    }
                }
            }
        }

        foreach (MamRange row in to_delete) {
            db.mam_catchup.delete().with(db.mam_catchup.id, "=", row.id).perform();
            warning("Removing db range %s %li-%li", row.server_jid.to_string(), row.from_time, row.to_time);
        }
    }

    class MamRange {
        public int id;
        public Jid server_jid;
        public long from_time;
        public string from_id;
        public bool from_end;
        public long to_time;
        public string to_id;
    }

    class PageRequestResult {
        public Gee.List<MessageStanza> stanzas { get; set; }
        public PageResult page_result { get; set; }
        public Xmpp.MessageArchiveManagement.QueryResult query_result { get; set; }

        public PageRequestResult(PageResult page_result, Xmpp.MessageArchiveManagement.QueryResult query_result, Gee.List<MessageStanza>? stanzas) {
            this.page_result = page_result;
            this.query_result = query_result;
            this.stanzas = stanzas;
        }
    }
}
