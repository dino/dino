using Gee;
using Xmpp;
using Dino.Entities;

namespace Dino {

/**
 * TuneManager manages XEP-0118: User Tune by monitoring MPRIS
 */
public class TuneManager : StreamInteractionModule, Object {
    public static ModuleIdentity<TuneManager> IDENTITY = new ModuleIdentity<TuneManager>("tune_manager");
    public string id { get { return IDENTITY.id; } }

    private const string MPRIS_PREFIX = "org.mpris.MediaPlayer2.";
    private const string MPRIS_PATH = "/org/mpris/MediaPlayer2";
    private const int DEBOUNCE_MS = 1000;  // 1 second debounce

    private StreamInteractor stream_interactor;
    private Database db;
    private Entities.Settings settings;

    private FreedesktopDBus? dbus_proxy = null;
    private HashMap<string, MprisPlayerWatcher> player_watchers = new HashMap<string, MprisPlayerWatcher>();
    private string? active_player_name = null;
    private Xep.UserTune.Tune? last_published_tune = null;
    private uint debounce_source = 0;
    private bool initialized = false;


    public signal void contact_tune_changed(Account account, Jid jid, Xep.UserTune.Tune? tune);
    private HashMap<string, Xep.UserTune.Tune?> contact_tunes = new HashMap<string, Xep.UserTune.Tune?>();

    public static void start(StreamInteractor stream_interactor, Database db, Entities.Settings settings) {
        TuneManager m = new TuneManager(stream_interactor, db, settings);
        stream_interactor.add_module(m);
    }

    private TuneManager(StreamInteractor stream_interactor, Database db, Entities.Settings settings) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.settings = settings;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
        stream_interactor.account_removed.connect(on_account_removed);
        stream_interactor.account_added.connect(on_account_added);

        // Watch for setting changes
        settings.notify["publish-tune"].connect(() => {
            if (settings.publish_tune) {
                if (!initialized) {
                    initialize_mpris_watcher.begin();
                }
            } else {
                // Clear tune and stop watching when disabled
                clear_tune_all_accounts();
                shutdown_mpris_watcher();
            }
        });

        // Initialize if already enabled
        if (settings.publish_tune) {
            initialize_mpris_watcher.begin();
        }
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        if (!settings.publish_tune) return;

        // Publish current tune state when account connects
        publish_current_tune_for_account(account);
    }

    private void on_account_added(Account account) {
        // receive tune notifications from contacts
        stream_interactor.module_manager.get_module(account, Xep.UserTune.Module.IDENTITY).tune_received.connect((stream, jid, tune) =>
            on_tune_received(account, jid, tune)
        );
    }

    private void on_tune_received(Account account, Jid jid, Xep.UserTune.Tune? tune) {
        string key = "%s/%s".printf(account.bare_jid.to_string(), jid.bare_jid.to_string());

        if (tune != null && !tune.is_empty()) {
            debug("[TuneManager] Received tune from %s: %s - %s",
                jid.to_string(),
                tune.artist ?? "Unknown Artist", // align with 2000s aesthetic
                tune.title ?? "Unknown Track");
            contact_tunes[key] = tune;
        } else {
            debug("[TuneManager] %s cleared their tune", jid.to_string());
            contact_tunes.unset(key);
        }

        contact_tune_changed(account, jid.bare_jid, tune);
    }

    public Xep.UserTune.Tune? get_contact_tune(Account account, Jid jid) {
        string key = "%s/%s".printf(account.bare_jid.to_string(), jid.bare_jid.to_string());
        if (contact_tunes.has_key(key)) {
            return contact_tunes[key];
        }
        return null;
    }

    private void on_account_removed(Account account) {
        // clear tune when account disconnects
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream != null) {
            Xep.UserTune.clear_tune.begin(stream);
        }
        clear_contact_tunes_for_account(account);
    }

    private async void initialize_mpris_watcher() {
        if (initialized) return;

        debug("[TuneManager] Initializing MPRIS watcher");

        try {
            dbus_proxy = yield Bus.get_proxy(BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");
            dbus_proxy.name_owner_changed.connect(on_dbus_name_changed);

            // Discover existing players
            string[] names = dbus_proxy.list_names();
            foreach (string name in names) {
                if (name.has_prefix(MPRIS_PREFIX)) {
                    debug("[TuneManager] Found existing player: %s", name);
                    yield add_player_watcher(name);
                }
            }

            initialized = true;
            debug("[TuneManager] MPRIS watcher initialized with %d players", player_watchers.size);

        } catch (Error e) {
            warning("[TuneManager] Failed to initialize MPRIS watcher: %s", e.message);
        }
    }

    private void shutdown_mpris_watcher() {
        debug("[TuneManager] Shutting down MPRIS watcher");

        // Cancel pending debounce
        if (debounce_source != 0) {
            Source.remove(debounce_source);
            debounce_source = 0;
        }

        // Clear all watchers
        player_watchers.clear();
        active_player_name = null;
        last_published_tune = null;
        initialized = false;
    }

    /**
     * Handle DBus name ownership changes (player appearing/disappearing).
     */
    private void on_dbus_name_changed(string name, string old_owner, string new_owner) {
        if (!name.has_prefix(MPRIS_PREFIX)) return;

        if (new_owner != "" && old_owner == "") {
            // New player appeared
            debug("[TuneManager] Player appeared: %s", name);
            add_player_watcher.begin(name);
        } else if (new_owner == "" && old_owner != "") {
            // Player disappeared
            debug("[TuneManager] Player disappeared: %s", name);
            remove_player_watcher(name);
        }
    }

    /**
     * Add a watcher for a specific MPRIS player.
     */
    private async void add_player_watcher(string bus_name) {
        if (player_watchers.has_key(bus_name)) return;

        try {
            MprisPlayer player = yield Bus.get_proxy(BusType.SESSION, bus_name, MPRIS_PATH);
            DBusProperties props = yield Bus.get_proxy(BusType.SESSION, bus_name, MPRIS_PATH);

            MprisPlayerWatcher watcher = new MprisPlayerWatcher(bus_name, player, props);
            watcher.state_changed.connect(on_player_state_changed);
            player_watchers[bus_name] = watcher;

            // Check if this player is playing
            update_active_player();

        } catch (Error e) {
            warning("[TuneManager] Failed to watch player %s: %s", bus_name, e.message);
        }
    }

    /**
     * Remove a player watcher.
     */
    private void remove_player_watcher(string bus_name) {
        if (player_watchers.has_key(bus_name)) {
            player_watchers.unset(bus_name);

            if (active_player_name == bus_name) {
                active_player_name = null;
                update_active_player();
            }
        }
    }

    /**
     * Handle player state changes.
     */
    private void on_player_state_changed(MprisPlayerWatcher watcher) {
        if (watcher.is_playing()) {
            active_player_name = watcher.get_bus_name();
            schedule_tune_publish();
            return;
        }
        update_active_player();
    }

    /**
     * Find the active player (one that is playing) and schedule tune publish.
     */
    private void update_active_player() {
        if (active_player_name != null &&
            player_watchers.has_key(active_player_name) &&
            player_watchers[active_player_name].is_playing()) {
            schedule_tune_publish();
            return;
        }

        // Find any playing player
        active_player_name = null;
        foreach (var entry in player_watchers.entries) {
            if (entry.value.is_playing()) {
                active_player_name = entry.key;
                break;
            }
        }

        schedule_tune_publish();
    }

    /**
     * Schedule a debounced tune publish.
     */
    private void schedule_tune_publish() {
        // Cancel any pending publish
        if (debounce_source != 0) {
            Source.remove(debounce_source);
        }

        debounce_source = Timeout.add(DEBOUNCE_MS, () => {
            debounce_source = 0;
            publish_tune_now();
            return false;
        });
    }

    /**
     * Build tune from current active player state.
     */
    private Xep.UserTune.Tune? get_current_tune() {
        if (active_player_name == null || !player_watchers.has_key(active_player_name)) {
            return null;
        }

        MprisPlayerWatcher watcher = player_watchers[active_player_name];
        if (!watcher.is_playing()) {
            return null;
        }

        MprisMetadata? metadata = watcher.get_metadata();
        if (metadata == null || metadata.is_empty()) {
            return null;
        }

        Xep.UserTune.Tune tune = new Xep.UserTune.Tune();
        tune.artist = metadata.artist;
        tune.title = metadata.title;
        tune.source = metadata.album;
        tune.length = metadata.get_length_seconds();
        tune.track = metadata.get_track_string();
        tune.uri = metadata.url;

        return tune;
    }

    /**
     * Publish current tune to all connected accounts.
     */
    private void publish_tune_now() {
        if (!settings.publish_tune) return;

        Xep.UserTune.Tune? tune = get_current_tune();

        // Check if tune actually changed
        if (last_published_tune != null && tune != null && last_published_tune.equals(tune)) {
            return;
        }
        if (last_published_tune == null && tune == null) {
            return;
        }

        last_published_tune = tune;

        string tune_info = tune != null ?
            "%s - %s".printf(tune.artist ?? "Unknown", tune.title ?? "Unknown") :
            "(empty)";
        debug("[TuneManager] Publishing tune: %s", tune_info);

        foreach (Account account in stream_interactor.get_accounts()) {
            publish_tune_for_account.begin(account, tune);
        }
    }

    /**
     * Publish tune for a specific account.
     */
    private async void publish_tune_for_account(Account account, Xep.UserTune.Tune? tune) {
        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null || !stream.negotiation_complete) return;

        try {
            yield Xep.UserTune.publish_tune(stream, tune);
        } catch (Error e) {
            warning("[TuneManager] Failed to publish tune for %s: %s", account.bare_jid.to_string(), e.message);
        }
    }

    /**
     * Publish current tune state for a newly connected account.
     */
    private void publish_current_tune_for_account(Account account) {
        if (!settings.publish_tune) return;

        Xep.UserTune.Tune? tune = get_current_tune();
        publish_tune_for_account.begin(account, tune);
    }

    /**
     * Clear tune for all accounts.
     */
    private void clear_tune_all_accounts() {
        last_published_tune = null;
        foreach (Account account in stream_interactor.get_accounts()) {
            XmppStream? stream = stream_interactor.get_stream(account);
            if (stream != null && stream.negotiation_complete) {
                Xep.UserTune.clear_tune.begin(stream);
            }
        }
    }

    private void clear_contact_tunes_for_account(Account account) {
        string account_prefix = "%s/".printf(account.bare_jid.to_string());
        ArrayList<string> keys_to_remove = new ArrayList<string>();

        foreach (string key in contact_tunes.keys) {
            if (key.has_prefix(account_prefix)) {
                keys_to_remove.add(key);
            }
        }

        foreach (string key in keys_to_remove) {
            contact_tunes.unset(key);
            string jid_str = key.substring(account_prefix.length);
            Jid jid = new Jid(jid_str);
            contact_tune_changed(account, jid, null);
        }
    }
}

/**
 * Watches a single MPRIS player for state changes.
 */
private class MprisPlayerWatcher : Object {
    public signal void state_changed(MprisPlayerWatcher watcher);

    private string bus_name;
    private MprisPlayer player;
    private DBusProperties props;
    private MprisMetadata? current_metadata = null;
    private string? playback_status = null;

    public MprisPlayerWatcher(string bus_name, MprisPlayer player, DBusProperties props) {
        this.bus_name = bus_name;
        this.player = player;
        this.props = props;

        // Get initial state
        refresh_state();

        // Listen for property changes
        props.properties_changed.connect(on_properties_changed);
    }

    private void on_properties_changed(string interface_name, HashTable<string, Variant> changed, string[] invalidated) {
        if (interface_name != "org.mpris.MediaPlayer2.Player") return;

        bool changed_state = false;

        Variant? status_v = changed.lookup("PlaybackStatus");
        if (status_v != null && status_v.is_of_type(VariantType.STRING)) {
            playback_status = status_v.get_string();
            changed_state = true;
        }

        Variant? metadata_v = changed.lookup("Metadata");
        if (metadata_v != null) {
            // Need to re-fetch metadata as the variant type can vary
            refresh_metadata();
            changed_state = true;
        }

        // Check if any relevant property was invalidated
        foreach (string prop in invalidated) {
            if (prop == "PlaybackStatus" || prop == "Metadata") {
                refresh_state();
                changed_state = true;
                break;
            }
        }

        if (changed_state) {
            state_changed(this);
        }
    }

    private void refresh_state() {
        refresh_playback_status();
        refresh_metadata();
    }

    private void refresh_playback_status() {
        try {
            playback_status = player.playback_status;
        } catch (Error e) {
            playback_status = null;
        }
    }

    private void refresh_metadata() {
        try {
            HashTable<string, Variant> metadata = player.metadata;
            current_metadata = MprisMetadata.from_hashtable(metadata);
        } catch (Error e) {
            current_metadata = null;
        }
    }

    public bool is_playing() {
        return playback_status == "Playing";
    }

    public MprisMetadata? get_metadata() {
        return current_metadata;
    }

    public string get_bus_name() {
        return bus_name;
    }
}

}

