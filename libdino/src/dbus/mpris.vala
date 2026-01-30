namespace Dino {

// DBus interface for org.freedesktop.DBus to enumerate available services.

[DBus (name = "org.freedesktop.DBus")]
public interface FreedesktopDBus : Object {
    public abstract string[] list_names() throws Error;
    public signal void name_owner_changed(string name, string old_owner, string new_owner);
}

// DBus interface for org.mpris.MediaPlayer2
[DBus (name = "org.mpris.MediaPlayer2")]
public interface MprisMediaPlayer2 : Object {
    public abstract string identity { owned get; }
    public abstract string desktop_entry { owned get; }
    public abstract void quit() throws Error;
}

// DBus interface for org.mpris.MediaPlayer2.Player

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public interface MprisPlayer : Object {
    public abstract HashTable<string, Variant> metadata { owned get; }
    public abstract string playback_status { owned get; }
    public abstract void play() throws Error;
    public abstract void pause() throws Error;
    public abstract void play_pause() throws Error;
    public abstract void stop() throws Error;
    public abstract void next() throws Error;
    public abstract void previous() throws Error;
}

// DBus interface for org.freedesktop.DBus.Properties
[DBus (name = "org.freedesktop.DBus.Properties")]
public interface DBusProperties : Object {
    public signal void properties_changed(string interface_name, HashTable<string, Variant> changed_properties, string[] invalidated_properties);
}

public class MprisMetadata : Object {
    public string? title { get; set; default = null; }
    public string? artist { get; set; default = null; }
    public string? album { get; set; default = null; }
    public int64 length_us { get; set; default = -1; }  // microseconds
    public int track_number { get; set; default = -1; }
    public string? url { get; set; default = null; }
    public string? playback_status { get; set; default = null; }

    public MprisMetadata() {}

    public static MprisMetadata from_hashtable(HashTable<string, Variant> metadata) {
        MprisMetadata m = new MprisMetadata();

        Variant? title_v = metadata.lookup("xesam:title");
        if (title_v != null && title_v.is_of_type(VariantType.STRING)) {
            m.title = title_v.get_string();
        }

        Variant? artist_v = metadata.lookup("xesam:artist");
        if (artist_v != null) {
            if (artist_v.is_of_type(VariantType.STRING_ARRAY)) {
                string[] artists = artist_v.get_strv();
                if (artists.length > 0) {
                    m.artist = string.joinv(", ", artists);
                }
            } else if (artist_v.is_of_type(VariantType.STRING)) {
                m.artist = artist_v.get_string();
            }
        }

        Variant? album_v = metadata.lookup("xesam:album");
        if (album_v != null && album_v.is_of_type(VariantType.STRING)) {
            m.album = album_v.get_string();
        }

        Variant? length_v = metadata.lookup("mpris:length");
        if (length_v != null) {
            if (length_v.is_of_type(VariantType.INT64)) {
                m.length_us = length_v.get_int64();
            } else if (length_v.is_of_type(VariantType.UINT64)) {
                m.length_us = (int64) length_v.get_uint64();
            }
        }

        Variant? track_v = metadata.lookup("xesam:trackNumber");
        if (track_v != null) {
            if (track_v.is_of_type(VariantType.INT32)) {
                m.track_number = track_v.get_int32();
            } else if (track_v.is_of_type(VariantType.INT64)) {
                m.track_number = (int) track_v.get_int64();
            }
        }

        Variant? url_v = metadata.lookup("xesam:url");
        if (url_v != null && url_v.is_of_type(VariantType.STRING)) {
            m.url = url_v.get_string();
        }

        return m;
    }

    // length in seconds (XEP-0118 uses seconds)
    public int get_length_seconds() {
        if (length_us < 0) return -1;
        return (int) (length_us / 1000000);
    }

    public string? get_track_string() {
        if (track_number < 0) return null;
        return track_number.to_string();
    }

    public bool is_empty() {
        return title == null && artist == null && album == null;
    }
}

}

