using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.Util {

private const string[] tango_colors_light = {"FCE94F", "FCAF3E", "E9B96E", "8AE234", "729FCF", "AD7FA8", "EF2929"};
private const string[] tango_colors_medium = {"EDD400", "F57900", "C17D11", "73D216", "3465A4", "75507B", "CC0000"};
private const string[] material_colors_800 = {"D32F2F", "C2185B", "7B1FA2", "512DA8", "303F9F", "1976D2", "0288D1", "0097A7", "00796B", "388E3C", "689F38", "AFB42B", "FFA000", "F57C00", "E64A19", "5D4037"};
private const string[] material_colors_500 = {"F44336", "E91E63", "9C27B0", "673AB7", "3f51B5", "2196F3", "03A9f4", "00BCD4", "009688", "4CAF50", "8BC34a", "CDDC39", "FFC107", "FF9800", "FF5722", "795548"};
private const string[] material_colors_300 = {"E57373", "F06292", "BA68C8", "9575CD", "7986CB", "64B5F6", "4FC3F7", "4DD0E1", "4DB6AC", "81C784", "AED581", "DCE775", "FFD54F", "FFB74D", "FF8A65", "A1887F"};
private const string[] material_colors_200 = {"EF9A9A", "F48FB1", "CE93D8", "B39DDB", "9FA8DA", "90CAF9", "81D4FA", "80DEEA", "80CBC4", "A5D6A7", "C5E1A5", "E6EE9C", "FFE082", "FFCC80", "FFAB91", "BCAAA4"};

public static string get_avatar_hex_color(StreamInteractor stream_interactor, Account account, Jid jid) {
    uint hash = get_relevant_jid(stream_interactor, account, jid).to_string().hash();
    return material_colors_300[hash % material_colors_300.length];
//    return tango_colors_light[name.hash() % tango_colors_light.length];
}

public static string get_name_hex_color(StreamInteractor stream_interactor, Account account, Jid jid, bool dark_theme = false) {
    uint hash = get_relevant_jid(stream_interactor, account, jid).to_string().hash();
    if (dark_theme) {
        return material_colors_300[hash % material_colors_300.length];
    } else {
        return material_colors_500[hash % material_colors_500.length];
    }
//    return tango_colors_medium[name.hash() % tango_colors_medium.length];
}

private static Jid get_relevant_jid(StreamInteractor stream_interactor, Account account, Jid jid) {
    if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(jid.bare_jid, account)) {
        Jid? real_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(jid, account);
        if (real_jid != null) {
            return real_jid.bare_jid;
        }
    } else {
        return jid.bare_jid;
    }
    return jid;
}

public static string color_for_show(string show) {
    switch(show) {
        case "online": return "#9CCC65";
        case "away": return "#FFCA28";
        case "chat": return "#66BB6A";
        case "xa": return "#EF5350";
        case "dnd": return "#EF5350";
        default: return "#BDBDBD";
    }
}

public static string get_conversation_display_name(StreamInteractor stream_interactor, Conversation conversation) {
    if (conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
        return conversation.counterpart.resourcepart + " from " + get_display_name(stream_interactor, conversation.counterpart.bare_jid, conversation.account);
    }
    return get_display_name(stream_interactor, conversation.counterpart, conversation.account);
}

public static string get_display_name(StreamInteractor stream_interactor, Jid jid, Account account) {
    if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid, account)) {
        return jid.resourcepart;
    } else {
        if (jid.equals_bare(account.bare_jid)) {
            if (account.alias == null || account.alias == "") {
                return account.bare_jid.to_string();
            } else {
                return account.alias;
            }
        }
        Roster.Item roster_item = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, jid);
        if (roster_item != null && roster_item.name != null && roster_item.name != "") {
            return roster_item.name;
        }
        return jid.bare_jid.to_string();
    }
}

public static string get_message_display_name(StreamInteractor stream_interactor, Entities.Message message, Account account) {
    return get_display_name(stream_interactor, message.from, account);
}

public static void image_set_from_scaled_pixbuf(Image image, Gdk.Pixbuf pixbuf, int scale = 0, int width = 0, int height = 0) {
    if (scale == 0) scale = image.scale_factor;
    Cairo.Surface surface = Gdk.cairo_surface_create_from_pixbuf(pixbuf, scale, image.get_window());
    if (height == 0 && width != 0) {
        height = (int) ((double) width / pixbuf.width * pixbuf.height);
    } else if (height != 0 && width == 0) {
        width = (int) ((double) height / pixbuf.height * pixbuf.width);
    }
    if (width != 0) {
        Cairo.Surface surface_new = new Cairo.Surface.similar_image(surface, Cairo.Format.ARGB32, width, height);
        Cairo.Context context = new Cairo.Context(surface_new);
        context.scale((double) width * scale / pixbuf.width, (double) height * scale / pixbuf.height);
        context.set_source_surface(surface, 0, 0);
        context.get_source().set_filter(Cairo.Filter.BEST);
        context.paint();
        surface = surface_new;
    }
    image.set_from_surface(surface);
}

private const string force_background_css = "%s { background-color: %s; }";
private const string force_color_css = "%s { color: %s; }";

private static void force_css(Gtk.Widget widget, string css) {
    var p = new Gtk.CssProvider();
    try {
        p.load_from_data(css);
        widget.get_style_context().add_provider(p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    } catch (GLib.Error err) {
        // handle err
    }
}

public static void force_background(Gtk.Widget widget, string color, string selector = "*") {
    force_css(widget, force_background_css.printf(selector, color));
}

public static void force_color(Gtk.Widget widget, string color, string selector = "*") {
    force_css(widget, force_color_css.printf(selector, color));
}

public static void force_error_color(Gtk.Widget widget, string selector = "*") {
    force_color(widget, "@error_color", selector);
}

public static bool is_dark_theme(Gtk.Widget widget) {
    Gdk.RGBA bg = widget.get_style_context().get_color(StateFlags.NORMAL);
    return (bg.red > 0.5 && bg.green > 0.5 && bg.blue > 0.5);
}

public static bool is_24h_format() {
    GLib.Settings settings = new GLib.Settings("org.gnome.desktop.interface");
    string settings_format = settings.get_string("clock-format");
    string p_format = (new DateTime.now_utc()).format("%p");
    return settings_format == "24h" || p_format == " ";
}

public static string make_word_bold_markup(string s, string word) {
    string ret = s;
    int elongated_by = 0;
    Regex highlight_regex = new Regex("\\b" + Regex.escape_string(word.down()) + "\\b");
    MatchInfo match_info;
    string markup_text_bak = s.down();
    highlight_regex.match(markup_text_bak, 0, out match_info);
    for (; match_info.matches(); match_info.next()) {
        int start, end;
        match_info.fetch_pos(0, out start, out end);
        ret = ret[0:start+elongated_by] + "<b>" + ret[start+elongated_by:end+elongated_by] + "</b>" + ret[end+elongated_by:ret.length];
        elongated_by += 7;
    }
    markup_text_bak += ""; // We need markup_text_bak to live until here because url_regex.match does not copy the string
    return ret;
}

public static string make_link_markup(string s) {
    string ret = s;
    Regex url_regex = new Regex("""(?i)\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))""");
    int elongated_by = 0;
    MatchInfo match_info;
    string markup_text_bak = ret.down();
    url_regex.match(markup_text_bak, 0, out match_info);
    for (; match_info.matches(); match_info.next()) {
        int start, end;
        match_info.fetch_pos(0, out start, out end);
        string link = ret[start+elongated_by:end+elongated_by];
        ret = ret[0:start+elongated_by] + "<a href=\"" + link + "\">" + link + "</a>" + ret[end+elongated_by:ret.length];
        elongated_by += 15 + link.length;
    }
    markup_text_bak += ""; // We need markup_text_bak to live until here because url_regex.match does not copy the string
    return ret;
}

}
