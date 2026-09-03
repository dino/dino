using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Qlite;

public class Dino.HistorySync {

    private const string RETAINED_REPLAY_SETTING = "mam-retained-replay-v1";
    private const string RETAINED_REPLAY_CURSOR = "mam-retained-replay-v1-cursor";

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Account, BulkWindowState> bulk_windows = new HashMap<Account, BulkWindowState>(Account.hash_func, Account.equals_func);

    public HashMap<Account, HashMap<Jid, int>> current_catchup_id = new HashMap<Account, HashMap<Jid, int>>(Account.hash_func, Account.equals_func);
    public WeakMap<Account, XmppStream> sync_streams = new WeakMap<Account, XmppStream>(Account.hash_func, Account.equals_func);
    public HashMap<Account, HashMap<string, DateTime>> mam_times = new HashMap<Account, HashMap<string, DateTime>>();
    public HashMap<string, int> hitted_range = new HashMap<string, int>();
    private HashMap<Account, HashMap<string, string>> query_targets = new HashMap<Account, HashMap<string, string>>(Account.hash_func, Account.equals_func);
    private HashMap<Account, HashMap<string, HashSet<string>>> query_result_ids = new HashMap<Account, HashMap<string, HashSet<string>>>(Account.hash_func, Account.equals_func);

    // Server ID of the latest message of the previous segment
    public HashMap<Account, string> catchup_until_id = new HashMap<Account, string>(Account.hash_func, Account.equals_func);
    // Time of the latest message of the previous segment
    public HashMap<Account, DateTime> catchup_until_time = new HashMap<Account, DateTime>(Account.hash_func, Account.equals_func);

    private HashMap<string, Gee.List<Xmpp.MessageStanza>> stanzas = new HashMap<string, Gee.List<Xmpp.MessageStanza>>();

    public HistorySync(Database db, StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.account_added.connect(on_account_added);

        stream_interactor.stream_negotiated.connect((account, stream) => {
            if (current_catchup_id.has_key(account)) {
                debug("MAM: [%s] Reset catchup_id", account.bare_jid.to_string());
                current_catchup_id[account].clear();
            }
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

    public void update_latest_db_range(Account account, Xmpp.MessageStanza message_stanza) {
        Jid mam_server = stream_interactor.get_module(MucManager.IDENTITY).might_be_groupchat(message_stanza.from.bare_jid, account) ? message_stanza.from.bare_jid : account.bare_jid;

        string? stanza_id = UniqueStableStanzaIDs.get_stanza_id(message_stanza, mam_server);
        if (stanza_id == null) return;
        if (mam_server.equals_bare(account.bare_jid)) {
            queue_bulk_window(account, stanza_id);
            return;
        }

        if (!current_catchup_id.has_key(account) || !current_catchup_id[account].has_key(mam_server)) return;

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
        if (query_id != null && query_result_ids.has_key(account) &&
                query_result_ids[account].has_key(query_id)) {
            query_result_ids[account][query_id].add(id);
        }
        if (query_id != null && query_targets.has_key(account) &&
                query_targets[account].has_key(query_id) && id == query_targets[account][query_id]) {
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

    public async void fetch_everything(Account account, Jid mam_server, Cancellable? cancellable = null, DateTime until_earliest_time = new DateTime.from_unix_utc(0)) {
        debug("[%s | %s] Fetch everything %s", account.bare_jid.to_string(), mam_server.to_string(), until_earliest_time != null ? @"(until $until_earliest_time)" : "");
        RowOption latest_row_opt = db.mam_catchup.select()
                .with(db.mam_catchup.account_id, "=", account.id)
                .with(db.mam_catchup.server_jid, "=", mam_server.to_string())
                .with(db.mam_catchup.to_time, ">=", (long) until_earliest_time.to_unix())
                .order_by(db.mam_catchup.to_time, "DESC")
                .single().row();
        Row? latest_row = latest_row_opt.is_present() ? latest_row_opt.inner : null;

        Row? new_row = yield fetch_latest_page(account, mam_server, latest_row, until_earliest_time, cancellable);

        if (new_row != null) {
            current_catchup_id[account][mam_server] = new_row[db.mam_catchup.id];
        } else if (latest_row != null) {
            current_catchup_id[account][mam_server] = latest_row[db.mam_catchup.id];
        }

        // Set the previous and current row
        Row? previous_row = null;
        Row? current_row = null;
        if (new_row != null) {
            current_row = new_row;
            previous_row = latest_row;
        } else if (latest_row != null) {
            current_row = latest_row;
            RowOption previous_row_opt = db.mam_catchup.select()
                    .with(db.mam_catchup.account_id, "=", account.id)
                    .with(db.mam_catchup.server_jid, "=", mam_server.to_string())
                    .with(db.mam_catchup.to_time, "<", current_row[db.mam_catchup.from_time])
                    .with(db.mam_catchup.to_time, ">=", (long) until_earliest_time.to_unix())
                    .order_by(db.mam_catchup.to_time, "DESC")
                    .single().row();
            previous_row = previous_row_opt.is_present() ? previous_row_opt.inner : null;
        }

        // Fetch messages between two db ranges and merge them
        while (current_row != null && previous_row != null) {
            if (current_row[db.mam_catchup.from_end]) {
                debug("[%s | %s] No logs on server before %s, aborting sync.", account.bare_jid.to_string(), mam_server.to_string(), current_row[db.mam_catchup.from_time].to_string());
                return;
            }

            debug("[%s | %s] Fetching between ranges %s - %s", account.bare_jid.to_string(), mam_server.to_string(), previous_row[db.mam_catchup.to_time].to_string(), current_row[db.mam_catchup.from_time].to_string());
            current_row = yield fetch_between_ranges(account, mam_server, previous_row, current_row, cancellable);
            if (current_row == null) return;

            RowOption previous_row_opt = db.mam_catchup.select()
                    .with(db.mam_catchup.account_id, "=", account.id)
                    .with(db.mam_catchup.server_jid, "=", mam_server.to_string())
                    .with(db.mam_catchup.to_time, "<", current_row[db.mam_catchup.from_time])
                    .with(db.mam_catchup.to_time, ">=", (long) until_earliest_time.to_unix())
                    .order_by(db.mam_catchup.to_time, "DESC")
                    .single().row();
            previous_row = previous_row_opt.is_present() ? previous_row_opt.inner : null;
        }

        // We're at the earliest range. Try to expand it even further back.
        if (current_row == null) {
            debug("[%s | %s] No current range, aborting sync.", account.bare_jid.to_string(), mam_server.to_string());
            return;
        } else if (current_row[db.mam_catchup.from_end]) {
            debug("[%s | %s] No logs on server before %s, aborting sync.", account.bare_jid.to_string(), mam_server.to_string(), current_row[db.mam_catchup.from_time].to_string());
            return;
        }
        // We don't want to fetch before the earliest range over and over again in MUCs if it's after until_earliest_time.
        // For now, don't query if we are within a week of until_earliest_time
        if (until_earliest_time != null && current_row[db.mam_catchup.from_time] <= until_earliest_time.to_unix()) {
            debug("[%s | %s] Current range starting %s is before limit %s, aborting sync.", account.bare_jid.to_string(), mam_server.to_string(), current_row[db.mam_catchup.from_time].to_string(), until_earliest_time.to_unix().to_string());
            return;
        }
        yield fetch_before_range(account, mam_server, current_row, until_earliest_time, cancellable);
    }

    // Fetches the latest page (up to previous db row). Extends the previous db row if it was reached, creates a new row otherwise.
    public async Row? fetch_latest_page(Account account, Jid mam_server, Row? latest_row, DateTime? until_earliest_time, Cancellable? cancellable = null) {
        debug("[%s | %s] Fetching latest page", account.bare_jid.to_string(), mam_server.to_string());

        int latest_row_id = -1;
        DateTime latest_message_time = until_earliest_time;
        string? latest_message_id = null;

        if (latest_row != null) {
            latest_row_id = latest_row[db.mam_catchup.id];
            latest_message_time = (new DateTime.from_unix_utc(latest_row[db.mam_catchup.to_time])).add_minutes(-5);
            latest_message_id = latest_row[db.mam_catchup.to_id];

            // Make sure we only fetch to until_earliest_time if latest_message_time is further back
            if (until_earliest_time != null && latest_message_time.compare(until_earliest_time) < 0) {
                latest_message_time = until_earliest_time.add_minutes(-5);
                latest_message_id = null;
            }
        }

        var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_latest(mam_server, latest_message_time, latest_message_id);

        PageRequestResult page_result = yield get_mam_page(account, query_params, null, cancellable);
        debug("[%s | %s] Latest page result: %s", account.bare_jid.to_string(), mam_server.to_string(), page_result.page_result.to_string());

        if (page_result.page_result == PageResult.Error ||
                page_result.page_result == PageResult.Cancelled ||
                page_result.page_result == PageResult.Unstable) {
            return null;
        }

        // The available archive window fits in one page. Extend the latest range.
        if (latest_row_id != -1 &&
                (page_result.page_result == PageResult.TargetReached ||
                page_result.page_result == PageResult.TargetNotReached ||
                (latest_message_id == null && page_result.page_result == PageResult.NoMoreMessages))) {

            if (page_result.stanzas == null) return null;

            string latest_mam_id = page_result.query_result.last;
            long latest_mam_time = (long) mam_times[account][latest_mam_id].to_unix();

            var query = db.mam_catchup.update()
                    .with(db.mam_catchup.id, "=", latest_row_id)
                    .set(db.mam_catchup.to_time, latest_mam_time)
                    .set(db.mam_catchup.to_id, latest_mam_id);

            if (page_result.page_result == PageResult.NoMoreMessages && starts_at_archive_beginning(query_params.start)) {
                // If the server doesn't have more messages, store that this range is at its end.
                query.set(db.mam_catchup.from_end, true);
            }
            query.perform();
            return null;
        }

        if (page_result.query_result.first == null || page_result.query_result.last == null) {
            return null;
        }

        // Either we need to fetch more pages or this is the first db entry ever
        debug("[%s | %s] Creating new db range for latest page", account.bare_jid.to_string(), mam_server.to_string());

        string from_id = page_result.query_result.first;
        string to_id = page_result.query_result.last;

        if (!mam_times[account].has_key(from_id) || !mam_times[account].has_key(to_id)) {
            debug("Missing from/to id %s %s", from_id, to_id);
            return null;
        }

        long from_time = (long) mam_times[account][from_id].to_unix();
        long to_time = (long) mam_times[account][to_id].to_unix();

        int new_row_id = (int) db.mam_catchup.insert()
                .value(db.mam_catchup.account_id, account.id)
                .value(db.mam_catchup.server_jid, mam_server.to_string())
                .value(db.mam_catchup.from_id, from_id)
                .value(db.mam_catchup.from_time, from_time)
                .value(db.mam_catchup.from_end, page_result.page_result == PageResult.NoMoreMessages && starts_at_archive_beginning(query_params.start))
                .value(db.mam_catchup.to_id, to_id)
                .value(db.mam_catchup.to_time, to_time)
                .perform();
        return db.mam_catchup.select().with(db.mam_catchup.id, "=", new_row_id).single().row().inner;
    }

    /** Fetches available messages between the end of `earlier_range` and start of `later_range`.
     ** Merges the ranges after reaching the boundary or exhausting the current archive.
     ** @return The merged range, or null if fetching failed.
     **/
    private async Row? fetch_between_ranges(Account account, Jid mam_server, Row earlier_range, Row later_range, Cancellable? cancellable = null) {
        int later_range_id = (int) later_range[db.mam_catchup.id];
        DateTime earliest_time = new DateTime.from_unix_utc(earlier_range[db.mam_catchup.to_time]);
        DateTime latest_time = new DateTime.from_unix_utc(later_range[db.mam_catchup.from_time]);
        debug("[%s | %s] Fetching between %s (%s) and %s (%s)", account.bare_jid.to_string(), mam_server.to_string(), earliest_time.to_string(), earlier_range[db.mam_catchup.to_id], latest_time.to_string(), later_range[db.mam_catchup.from_id]);

        var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_between(mam_server,
            earliest_time, earlier_range[db.mam_catchup.to_id],
            latest_time, later_range[db.mam_catchup.from_id]);

        PageRequestResult page_result = yield fetch_query(account, query_params, later_range_id, cancellable);

        if (page_result.page_result == PageResult.TargetReached ||
                page_result.page_result == PageResult.TargetNotReached) {
            debug("[%s | %s] Merging range %i into %i", account.bare_jid.to_string(), mam_server.to_string(), earlier_range[db.mam_catchup.id], later_range_id);
            // Merge earlier range into later one.
            db.mam_catchup.update()
                .with(db.mam_catchup.id, "=", later_range_id)
                .set(db.mam_catchup.from_time, earlier_range[db.mam_catchup.from_time])
                .set(db.mam_catchup.from_id, earlier_range[db.mam_catchup.from_id])
                .set(db.mam_catchup.from_end, earlier_range[db.mam_catchup.from_end])
                .perform();

            db.mam_catchup.delete().with(db.mam_catchup.id, "=", earlier_range[db.mam_catchup.id]).perform();

            // Return the updated version of the later range
            return db.mam_catchup.select().with(db.mam_catchup.id, "=", later_range_id).single().row().inner;
        }

        return null;
    }

    private async void fetch_before_range(Account account, Jid mam_server, Row range, DateTime? until_earliest_time, Cancellable? cancellable = null) {
        DateTime latest_time = new DateTime.from_unix_utc(range[db.mam_catchup.from_time]);
        string latest_id = range[db.mam_catchup.from_id];
        debug("[%s | %s] Fetching before range < %s, %s", account.bare_jid.to_string(), mam_server.to_string(), latest_time.to_string(), latest_id);

        Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params;
        if (until_earliest_time == null) {
            query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_before(mam_server, latest_time, latest_id);
        } else {
            query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_between(
                    mam_server,
                    until_earliest_time, null,
                    latest_time, latest_id
            );
        }
        yield fetch_query(account, query_params, range[db.mam_catchup.id], cancellable);
    }

    /**
     * Iteratively fetches all pages returned for a query (until a PageResult other than MorePagesAvailable is returned)
     * @return The last PageRequestResult result
     **/
    private async PageRequestResult fetch_query(Account account, Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params, int db_id, Cancellable? cancellable = null) {
        debug("[%s | %s] Fetch query %s - %s", account.bare_jid.to_string(), query_params.mam_server.to_string(), query_params.start != null ? query_params.start.to_string() : "", query_params.end != null ? query_params.end.to_string() : "");
        PageRequestResult? page_result = null;
        var seen_first_ids = new HashSet<string>();
        do {
            page_result = yield get_mam_page(account, query_params, page_result, cancellable);
            debug("[%s | %s] Page result %s (got stanzas: %s)", account.bare_jid.to_string(), query_params.mam_server.to_string(), page_result.page_result.to_string(), (page_result.stanzas != null).to_string());

            if (page_result.page_result == PageResult.Error ||
                    page_result.page_result == PageResult.Cancelled ||
                    page_result.page_result == PageResult.Unstable) return page_result;

            string earliest_mam_id = page_result.query_result.first;
            if (page_result.page_result == PageResult.MorePagesAvailable &&
                    (earliest_mam_id == null || seen_first_ids.contains(earliest_mam_id))) {
                page_result.page_result = PageResult.Error;
                return page_result;
            }
            if (earliest_mam_id != null) seen_first_ids.add(earliest_mam_id);
            long earliest_mam_time = earliest_mam_id != null ? (long)mam_times[account][earliest_mam_id].to_unix() : 0;

            var query = db.mam_catchup.update()
                    .with(db.mam_catchup.id, "=", db_id);
            if (earliest_mam_id != null) {
                debug("[%s | %s] Updating to %s, %s", account.bare_jid.to_string(), query_params.mam_server.to_string(), earliest_mam_time.to_string(), earliest_mam_id);
                query.set(db.mam_catchup.from_id, earliest_mam_id);
                if (page_result.page_result != PageResult.NoMoreMessages || query_params.start == null || earliest_mam_time < query_params.start.to_unix()) {
                    query.set(db.mam_catchup.from_time, earliest_mam_time);
                }
            }

            if (page_result.page_result == PageResult.NoMoreMessages ||
                    page_result.page_result == PageResult.TargetNotReached) {
                // If the server doesn't have more messages, store that this range is at its end or update the from timestamp
                if (query_params.start != null) {
                    debug("[%s | %s] Updating to %s based on query", account.bare_jid.to_string(), query_params.mam_server.to_string(), query_params.start.to_string());
                    query.set(db.mam_catchup.from_time, (long) query_params.start.to_unix());
                    if (starts_at_archive_beginning(query_params.start)) {
                        query.set(db.mam_catchup.from_end, true);
                    }
                } else {
                    query.set(db.mam_catchup.from_end, true);
                }
            }
            query.perform();
        } while (page_result.page_result == PageResult.MorePagesAvailable);

        return page_result;
    }

    enum PageResult {
        MorePagesAvailable,
        TargetReached,
        TargetNotReached,
        NoMoreMessages,
        Unstable,
        Error,
        Cancelled
    }

    /**
     * prev_page_result: null if this is the first page request
     **/
    private async PageRequestResult get_mam_page(Account account, Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params, PageRequestResult? prev_page_result, Cancellable? cancellable = null, XmppStream? expected_stream = null) {
        XmppStream? stream = expected_stream ?? stream_interactor.get_stream(account);
        if (stream == null || (expected_stream != null && stream_interactor.get_stream(account) != expected_stream)) {
            var empty_result = new Xmpp.MessageArchiveManagement.QueryResult() { error=true };
            return new PageRequestResult(PageResult.Error, empty_result, null);
        }
        query_params.query_id = Xmpp.random_uuid();
        string query_id = query_params.query_id;
        if (!query_result_ids.has_key(account)) {
            query_result_ids[account] = new HashMap<string, HashSet<string>>();
        }
        query_result_ids[account][query_id] = new HashSet<string>();
        if (query_params.start_id != null) {
            if (!query_targets.has_key(account)) {
                query_targets[account] = new HashMap<string, string>();
            }
            query_targets[account][query_id] = (!)query_params.start_id;
        }
        Xmpp.MessageArchiveManagement.QueryResult? query_result = null;
        if (prev_page_result == null) {
            query_result = yield Xmpp.MessageArchiveManagement.V2.query_archive((!)stream, query_params, cancellable);
        } else {
            query_result = yield Xmpp.MessageArchiveManagement.V2.page_through_results((!)stream, query_params, prev_page_result.query_result, cancellable);
        }
        if (query_result == null) {
            clear_query_state(account, query_id);
            var empty_result = new Xmpp.MessageArchiveManagement.QueryResult();
            if (cancellable != null && cancellable.is_cancelled()) {
                return new PageRequestResult(PageResult.Cancelled, empty_result, null);
            }
            empty_result.error = true;
            return new PageRequestResult(PageResult.Error, empty_result, null);
        }
        return yield process_query_result(account, query_params, (!)query_result, cancellable);
    }

    private async PageRequestResult process_query_result(Account account, Xmpp.MessageArchiveManagement.V2.MamQueryParams query_params, Xmpp.MessageArchiveManagement.QueryResult query_result, Cancellable? cancellable = null) {
        // We wait until all the messages from the page are processed (and we got the `mam_times` from them)
        Idle.add(process_query_result.callback, Priority.LOW);
        yield;

        string query_id = query_params.query_id;
        string? after_id = query_params.start_id;
        bool target_reached = false;

        var stanzas_for_query = stanzas.has_key(query_id) && !stanzas[query_id].is_empty ? stanzas[query_id] : null;
        if (cancellable != null && cancellable.is_cancelled()) {
            return finish_query(account, query_id, PageResult.Cancelled, query_result, stanzas_for_query);
        }
        if (query_result.malformed || query_result.error) {
            return finish_query(account, query_id, PageResult.Error, query_result, stanzas_for_query);
        }
        if (!query_result.stable) {
            return finish_query(account, query_id, PageResult.Unstable, query_result, stanzas_for_query);
        }

        if (stanzas_for_query != null) {

            // Check it we reached our target (from_id)
            foreach (Xmpp.MessageStanza message in stanzas_for_query) {
                Xmpp.MessageArchiveManagement.MessageFlag? mam_message_flag = Xmpp.MessageArchiveManagement.MessageFlag.get_flag(message);
                if (mam_message_flag != null && mam_message_flag.mam_id != null) {
                    if (after_id != null && mam_message_flag.mam_id == after_id) {
                        target_reached = true;
                        break;
                    }
                }
            }
        }
        if (after_id != null && hitted_range.has_key(query_id) && hitted_range[query_id] == -2) {
            target_reached = true;
        }

        yield send_messages_back_into_pipeline(account, query_id, cancellable);
        if (cancellable != null && cancellable.is_cancelled()) {
            return finish_query(account, query_id, PageResult.Cancelled, query_result, stanzas_for_query);
        }
        if (target_reached) {
            return finish_query(account, query_id, PageResult.TargetReached, query_result, stanzas_for_query);
        }
        if (query_result.complete) {
            PageResult page_result = after_id == null ? PageResult.NoMoreMessages : PageResult.TargetNotReached;
            return finish_query(account, query_id, page_result, query_result, stanzas_for_query);
        }
        return finish_query(account, query_id, PageResult.MorePagesAvailable, query_result, stanzas_for_query);
    }

    private PageRequestResult finish_query(Account account, string query_id, PageResult page_result, Xmpp.MessageArchiveManagement.QueryResult query_result, Gee.List<MessageStanza>? stanzas_for_query) {
        HashSet<string> result_ids = new HashSet<string>();
        if (query_result_ids.has_key(account) && query_result_ids[account].has_key(query_id)) {
            result_ids = query_result_ids[account][query_id];
        }
        clear_query_state(account, query_id);
        return new PageRequestResult(page_result, query_result, stanzas_for_query, result_ids);
    }

    private void clear_query_state(Account account, string query_id) {
        stanzas.unset(query_id);
        hitted_range.unset(query_id);
        if (query_targets.has_key(account)) query_targets[account].unset(query_id);
        if (query_result_ids.has_key(account)) query_result_ids[account].unset(query_id);
    }

    private bool starts_at_archive_beginning(DateTime? time) {
        return time == null || time.to_unix() == 0;
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
            consider_fetch_everything(account, stream);
        });

        stream_interactor.module_manager.get_module(account, Xmpp.MessageModule.IDENTITY).received_message_unprocessed.connect((stream, message) => {
            on_unprocessed_message(account, stream, message);
        });
    }

    private BulkWindowState get_bulk_window_state(Account account) {
        if (!bulk_windows.has_key(account)) {
            bulk_windows[account] = new BulkWindowState();
        }
        return bulk_windows[account];
    }

    private void queue_bulk_window(Account account, string stanza_id) {
        BulkWindowState state = get_bulk_window_state(account);
        if (state.active_ids.contains(stanza_id) || state.pending_ids.contains(stanza_id)) return;

        state.pending_ids.add(stanza_id);
        state.pending_order.add(stanza_id);
        state.pending_target = stanza_id;
        bool page_ready = state.pending_ids.size % Xmpp.ResultSetManagement.MAX_RESULTS == 0;
        bool existing_generation = state.active_target != null || state.reconnect_stage != ReconnectStage.None;
        bool stalled = state.cancellable == null && existing_generation &&
                !state.live_retry_consumed;
        if (page_ready || stalled) {
            state.live_retry_consumed = existing_generation;
            state.backward_catchup_attempted = false;
            state.wake_requested = true;
            dispatch_bulk_window(account, state);
        }
    }

    private bool capture_pending_window(BulkWindowState state, bool force) {
        if (state.active_target != null || state.pending_target == null) return false;
        if (!force && state.pending_ids.size < Xmpp.ResultSetManagement.MAX_RESULTS) return false;

        state.active_ids = state.pending_ids;
        state.active_order = state.pending_order;
        state.active_target = state.pending_target;
        state.pending_ids = new HashSet<string>();
        state.pending_order = new ArrayList<string>();
        state.pending_target = null;
        state.live_retry_consumed = false;
        return true;
    }

    private string? newest_window_id(ArrayList<string> ids) {
        return ids.is_empty ? null : ids[ids.size - 1];
    }

    private void remove_covered_window_ids(BulkWindowState state, HashSet<string> covered_ids) {
        foreach (string stanza_id in covered_ids) {
            if (state.active_ids.remove(stanza_id)) state.active_order.remove(stanza_id);
            if (state.pending_ids.remove(stanza_id)) state.pending_order.remove(stanza_id);
        }
        state.active_target = newest_window_id(state.active_order);
        state.pending_target = newest_window_id(state.pending_order);
    }

    private void retire_active_window(BulkWindowState state) {
        state.active_ids.clear();
        state.active_order.clear();
        state.active_target = null;
    }

    private Row? get_latest_personal_range(Account account) {
        RowOption row_opt = db.mam_catchup.select()
                .with(db.mam_catchup.account_id, "=", account.id)
                .with(db.mam_catchup.server_jid, "=", account.bare_jid.to_string())
                .order_by(db.mam_catchup.to_time, "DESC")
                .single().row();
        return row_opt.is_present() ? row_opt.inner : null;
    }

    private Row? get_earliest_personal_range(Account account) {
        RowOption row_opt = db.mam_catchup.select()
                .with(db.mam_catchup.account_id, "=", account.id)
                .with(db.mam_catchup.server_jid, "=", account.bare_jid.to_string())
                .order_by(db.mam_catchup.from_time, "ASC")
                .single().row();
        return row_opt.is_present() ? row_opt.inner : null;
    }

    private bool advance_personal_frontier(Account account, Row range, string stanza_id) {
        if (!mam_times[account].has_key(stanza_id)) return false;

        db.mam_catchup.update()
                .with(db.mam_catchup.id, "=", range[db.mam_catchup.id])
                .set(db.mam_catchup.to_id, stanza_id)
                .set(db.mam_catchup.to_time, (long) mam_times[account][stanza_id].to_unix())
                .perform();
        current_catchup_id[account][account.bare_jid] = range[db.mam_catchup.id];
        return true;
    }

    private async ForwardWindowResult fetch_forward_window(Account account, BulkWindowState state, XmppStream stream, string? target_id, Cancellable cancellable) {
        var covered_ids = new HashSet<string>();
        Row? latest_range = get_latest_personal_range(account);
        if (latest_range == null) return new ForwardWindowResult(WindowResult.NeedsCatchup, covered_ids);
        string frontier_id = latest_range[db.mam_catchup.to_id];
        if (target_id != null && target_id == frontier_id) {
            covered_ids.add((!)target_id);
            return new ForwardWindowResult(WindowResult.Complete, covered_ids);
        }

        var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_after(
                account.bare_jid, frontier_id, target_id);
        var seen_cursor_ids = new HashSet<string>();
        seen_cursor_ids.add(frontier_id);
        PageRequestResult? page_result = null;
        do {
            page_result = yield get_mam_page(account, query_params, page_result, cancellable, stream);
            if (page_result.page_result == PageResult.Cancelled) {
                return new ForwardWindowResult(WindowResult.Cancelled, covered_ids);
            }
            if (page_result.page_result == PageResult.Unstable) {
                return new ForwardWindowResult(WindowResult.Failed, covered_ids);
            }
            if (page_result.page_result == PageResult.Error) {
                if (page_result.query_result.error_condition == ErrorStanza.CONDITION_ITEM_NOT_FOUND) {
                    return new ForwardWindowResult(WindowResult.NeedsCatchup, covered_ids);
                }
                return new ForwardWindowResult(WindowResult.Failed, covered_ids);
            }

            string? checkpoint_id = page_result.query_result.last;
            if (checkpoint_id != null && seen_cursor_ids.contains(checkpoint_id)) {
                return new ForwardWindowResult(WindowResult.Failed, covered_ids);
            }
            if (checkpoint_id != null && !advance_personal_frontier(account, latest_range, (!)checkpoint_id)) {
                return new ForwardWindowResult(WindowResult.Failed, covered_ids);
            }
            if (checkpoint_id != null) {
                seen_cursor_ids.add((!)checkpoint_id);
                foreach (string stanza_id in page_result.result_ids) {
                    if (state.active_ids.contains(stanza_id) || state.pending_ids.contains(stanza_id)) {
                        covered_ids.add(stanza_id);
                    }
                }
            }

            if (page_result.page_result == PageResult.TargetReached) {
                if (target_id != null) covered_ids.add((!)target_id);
                return new ForwardWindowResult(WindowResult.Complete, covered_ids,
                        page_result.query_result.complete);
            }
            if (page_result.page_result == PageResult.TargetNotReached ||
                    page_result.page_result == PageResult.NoMoreMessages) {
                return new ForwardWindowResult(WindowResult.Complete, covered_ids, true);
            }
            if (page_result.query_result.last == null) {
                return new ForwardWindowResult(WindowResult.Failed, covered_ids);
            }
        } while (page_result.page_result == PageResult.MorePagesAvailable);

        return new ForwardWindowResult(WindowResult.Failed, covered_ids);
    }

    private async TailRequestResult fetch_reconnect_tail(Account account, XmppStream stream, Cancellable cancellable) {
        var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_before(
                account.bare_jid, null, null);
        query_params.max_results = 1;
        PageRequestResult page_result = yield get_mam_page(account, query_params, null, cancellable, stream);
        if (page_result.page_result == PageResult.Cancelled) {
            return new TailRequestResult(WindowResult.Cancelled, null);
        }
        if (page_result.page_result == PageResult.Error || page_result.page_result == PageResult.Unstable) {
            return new TailRequestResult(WindowResult.Failed, null);
        }
        if (page_result.query_result.last == null && page_result.page_result != PageResult.NoMoreMessages) {
            return new TailRequestResult(WindowResult.Failed, null);
        }
        return new TailRequestResult(WindowResult.Complete, page_result.query_result.last);
    }

    private async WindowResult replay_retained_archive(Account account, XmppStream stream, Cancellable cancellable) {
        Row? earliest_range = get_earliest_personal_range(account);
        if (earliest_range == null) return WindowResult.Complete;

        DateTime earliest_time = new DateTime.from_unix_utc(earliest_range[db.mam_catchup.from_time]);
        string earliest_id_value = earliest_range[db.mam_catchup.from_id];
        string? earliest_id = earliest_id_value == "" ? null : earliest_id_value;
        string? cursor_value = db.account_settings.get_value(account.id, RETAINED_REPLAY_CURSOR);
        string? cursor_id = null;
        DateTime? cursor_time = null;
        if (cursor_value != null) {
            int separator = cursor_value.index_of_char('\n');
            if (separator > 0) {
                string stored_id = cursor_value.substring(separator + 1);
                DateTime? stored_time = DateTimeProfiles.parse_time(cursor_value.substring(0, separator));
                if (stored_id != "" && stored_time != null) {
                    cursor_time = stored_time;
                    cursor_id = stored_id;
                }
            }
        }
        var query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_between(
                account.bare_jid, earliest_time, earliest_id, cursor_time, cursor_id);
        PageRequestResult? page_result = null;
        var seen_cursor_ids = new HashSet<string>();
        if (cursor_id != null) seen_cursor_ids.add(cursor_id);
        bool used_time_fallback = false;
        do {
            page_result = yield get_mam_page(account, query_params, page_result, cancellable, stream);
            if (page_result.page_result == PageResult.Cancelled) return WindowResult.Cancelled;
            if (page_result.page_result == PageResult.Unstable) return WindowResult.Failed;
            if (page_result.page_result == PageResult.Error) {
                if (!used_time_fallback && cursor_time != null &&
                        page_result.query_result.error_condition == ErrorStanza.CONDITION_ITEM_NOT_FOUND) {
                    query_params = new Xmpp.MessageArchiveManagement.V2.MamQueryParams.query_between(
                            account.bare_jid, earliest_time, earliest_id, cursor_time, null);
                    page_result = null;
                    used_time_fallback = true;
                    continue;
                }
                return WindowResult.Failed;
            }

            string? first_id = page_result.query_result.first;
            if (first_id != null) {
                if (seen_cursor_ids.contains(first_id)) return WindowResult.Failed;
                if (!mam_times[account].has_key(first_id)) return WindowResult.Failed;
                DateTime first_time = mam_times[account][first_id];
                set_account_setting(account, RETAINED_REPLAY_CURSOR, DateTimeProfiles.format_time(first_time) + "\n" + first_id);
                cursor_id = first_id;
                cursor_time = first_time;
                seen_cursor_ids.add(first_id);
                used_time_fallback = false;
            }
            if (page_result.page_result == PageResult.TargetReached ||
                    page_result.page_result == PageResult.TargetNotReached ||
                    page_result.page_result == PageResult.NoMoreMessages) {
                return WindowResult.Complete;
            }
            if (page_result.page_result != PageResult.MorePagesAvailable ||
                    page_result.query_result.first == null) {
                return WindowResult.Failed;
            }
            Idle.add(replay_retained_archive.callback, Priority.LOW);
            yield;
        } while (true);
    }

    private void set_account_setting(Account account, string key, string value) {
        db.account_settings.upsert()
                .value(db.account_settings.key, key, true)
                .value(db.account_settings.account_id, account.id, true)
                .value(db.account_settings.value, value)
                .perform();
    }

    private bool retained_replay_pending(Account account) {
        return db.account_settings.get_value(account.id, RETAINED_REPLAY_SETTING) == "pending";
    }

    private void start_retained_replay(Account account, BulkWindowState state, XmppStream stream) {
        Cancellable cancellable = new Cancellable();
        state.wake_requested = false;
        state.cancellable = cancellable;
        replay_retained_archive.begin(account, stream, cancellable, (_, res) => {
            WindowResult result = replay_retained_archive.end(res);
            if (state.cancellable != cancellable) return;

            state.cancellable = null;
            if (result == WindowResult.Complete) {
                state.live_retry_consumed = false;
                set_account_setting(account, RETAINED_REPLAY_SETTING, "done");
                dispatch_bulk_window(account, state);
            } else if (state.stream != stream || state.wake_requested) {
                dispatch_bulk_window(account, state);
            }
        });
    }

    private void start_backward_catchup(Account account, BulkWindowState state, XmppStream stream) {
        state.backward_catchup_pending = false;
        Cancellable cancellable = new Cancellable();
        state.wake_requested = false;
        state.cancellable = cancellable;
        fetch_everything.begin(account, account.bare_jid, cancellable, new DateTime.from_unix_utc(0), (_, res) => {
            fetch_everything.end(res);
            if (state.cancellable != cancellable) return;

            state.cancellable = null;
            dispatch_bulk_window(account, state);
        });
    }

    private void start_reconnect_tail(Account account, BulkWindowState state, XmppStream stream) {
        Cancellable cancellable = new Cancellable();
        state.wake_requested = false;
        state.cancellable = cancellable;
        fetch_reconnect_tail.begin(account, stream, cancellable, (_, res) => {
            TailRequestResult result = fetch_reconnect_tail.end(res);
            if (state.cancellable != cancellable) return;

            state.cancellable = null;
            if (result.result == WindowResult.Complete && state.stream == stream &&
                    state.reconnect_stage == ReconnectStage.Drain) {
                state.live_retry_consumed = false;
                state.reconnect_tail_known = true;
                state.reconnect_tail = result.target_id;
                dispatch_bulk_window(account, state);
            } else if (state.stream != stream || state.wake_requested) {
                dispatch_bulk_window(account, state);
            }
        });
    }

    private void start_forward_window(Account account, BulkWindowState state, XmppStream stream, string? target_id) {
        Cancellable cancellable = new Cancellable();
        state.wake_requested = false;
        state.cancellable = cancellable;
        fetch_forward_window.begin(account, state, stream, target_id, cancellable, (_, res) => {
            ForwardWindowResult result = fetch_forward_window.end(res);
            if (state.cancellable != cancellable) return;

            bool targeted_active_window = target_id != null && state.active_target == target_id;
            state.cancellable = null;
            remove_covered_window_ids(state, result.covered_ids);
            if (state.stream != stream) {
                dispatch_bulk_window(account, state);
                return;
            }
            if (result.result == WindowResult.Complete) {
                state.backward_catchup_attempted = false;
                state.live_retry_consumed = false;
                if (target_id != null && state.reconnect_stage == ReconnectStage.Drain &&
                        state.reconnect_tail_known && state.reconnect_tail == target_id) {
                    state.reconnect_tail_known = false;
                    state.reconnect_tail = null;
                    state.reconnect_stage = ReconnectStage.CloseSuccessor;
                } else if (targeted_active_window && result.target_exhausted) {
                    retire_active_window(state);
                }
                dispatch_bulk_window(account, state);
            } else if (result.result == WindowResult.NeedsCatchup) {
                if (!state.backward_catchup_attempted) {
                    state.backward_catchup_attempted = true;
                    state.backward_catchup_pending = true;
                    dispatch_bulk_window(account, state);
                }
            } else if (state.wake_requested) {
                dispatch_bulk_window(account, state);
            }
        });
    }

    private void dispatch_bulk_window(Account account, BulkWindowState state) {
        if (state.cancellable != null) return;

        XmppStream? stream = state.stream;
        if (stream == null || stream_interactor.get_stream(account) != stream || !sync_streams.has(account, (!)stream)) return;
        if (retained_replay_pending(account)) {
            start_retained_replay(account, state, (!)stream);
            return;
        }
        if (state.backward_catchup_pending) {
            start_backward_catchup(account, state, (!)stream);
            return;
        }
        if (state.active_target != null) {
            start_forward_window(account, state, (!)stream, state.active_target);
            return;
        }

        if (state.reconnect_stage == ReconnectStage.CloseWindow) {
            bool captured = capture_pending_window(state, true);
            state.reconnect_stage = ReconnectStage.Drain;
            if (captured) {
                start_forward_window(account, state, (!)stream, state.active_target);
                return;
            }
        }
        if (state.reconnect_stage == ReconnectStage.Drain) {
            if (!state.reconnect_tail_known) {
                start_reconnect_tail(account, state, (!)stream);
                return;
            }
            if (state.reconnect_tail == null) {
                state.reconnect_tail_known = false;
                state.reconnect_stage = ReconnectStage.CloseSuccessor;
            } else {
                start_forward_window(account, state, (!)stream, state.reconnect_tail);
                return;
            }
        }
        if (state.reconnect_stage == ReconnectStage.CloseSuccessor) {
            bool captured = capture_pending_window(state, true);
            state.reconnect_stage = ReconnectStage.None;
            if (captured) {
                start_forward_window(account, state, (!)stream, state.active_target);
                return;
            }
        }
        if (capture_pending_window(state, false)) {
            start_forward_window(account, state, (!)stream, state.active_target);
        }
    }

    private void consider_fetch_everything(Account account, XmppStream stream) {
        if (sync_streams.has(account, stream)) return;

        debug("[%s] MAM available", account.bare_jid.to_string());
        sync_streams[account] = stream;
        BulkWindowState state = get_bulk_window_state(account);
        state.stream = stream;
        state.reconnect_stage = ReconnectStage.CloseWindow;
        state.reconnect_tail_known = false;
        state.reconnect_tail = null;
        state.backward_catchup_attempted = false;
        state.live_retry_consumed = false;

        if (state.cancellable != null) {
            ((!)state.cancellable).cancel();
            return;
        }
        dispatch_bulk_window(account, state);
    }

    public static void cleanup_db_ranges(Database db, Account account) {
        var ranges = new HashMap<Jid, ArrayList<MamRange>>(Jid.hash_func, Jid.equals_func);
        foreach (Row row in db.mam_catchup.select().with(db.mam_catchup.account_id, "=", account.id)) {
            var mam_range = new MamRange();
            mam_range.id = row[db.mam_catchup.id];
            mam_range.server_jid = Jid.from_string(row[db.mam_catchup.server_jid]);
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
        public HashSet<string> result_ids { get; set; }

        public PageRequestResult(PageResult page_result, Xmpp.MessageArchiveManagement.QueryResult query_result, Gee.List<MessageStanza>? stanzas, HashSet<string>? result_ids = null) {
            this.page_result = page_result;
            this.query_result = query_result;
            this.stanzas = stanzas;
            this.result_ids = result_ids ?? new HashSet<string>();
        }
    }

    class TailRequestResult {
        public WindowResult result { get; set; }
        public string? target_id { get; set; }

        public TailRequestResult(WindowResult result, string? target_id) {
            this.result = result;
            this.target_id = target_id;
        }
    }

    class ForwardWindowResult {
        public WindowResult result { get; set; }
        public HashSet<string> covered_ids { get; set; }
        public bool target_exhausted { get; set; }

        public ForwardWindowResult(WindowResult result, HashSet<string> covered_ids, bool target_exhausted = false) {
            this.result = result;
            this.covered_ids = covered_ids;
            this.target_exhausted = target_exhausted;
        }
    }

    enum WindowResult {
        Complete,
        NeedsCatchup,
        Failed,
        Cancelled
    }

    enum ReconnectStage {
        None,
        CloseWindow,
        Drain,
        CloseSuccessor
    }

    class BulkWindowState {
        public HashSet<string> pending_ids = new HashSet<string>();
        public ArrayList<string> pending_order = new ArrayList<string>();
        public string? pending_target;
        public HashSet<string> active_ids = new HashSet<string>();
        public ArrayList<string> active_order = new ArrayList<string>();
        public string? active_target;
        public XmppStream? stream;
        public Cancellable? cancellable;
        public bool backward_catchup_pending = false;
        public bool backward_catchup_attempted = false;
        public bool live_retry_consumed = false;
        public bool wake_requested = false;
        public bool reconnect_tail_known = false;
        public string? reconnect_tail;
        public ReconnectStage reconnect_stage = ReconnectStage.None;
    }

}
