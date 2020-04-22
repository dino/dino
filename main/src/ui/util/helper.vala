using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.Util {

private static Regex URL_REGEX;
private static Regex CODE_BLOCK_REGEX;
private static Map<unichar, unichar> MATCHING_CHARS;
private const unichar[] NON_TRAILING_CHARS = {'\'', '"', ',', '.', ';', '!', '?', '»', '”', '’', '`', '~', '‽', ':', '>', '*', '_'};
private const string[] ALLOWED_SCHEMAS = {"http", "https", "ftp", "ftps", "irc", "ircs", "xmpp", "mailto", "sms", "smsto", "mms", "tel", "geo", "openpgp4fpr", "im", "news", "nntp", "sip", "ssh", "bitcoin", "sftp", "magnet", "vnc"};
private const string[] tango_colors_light = {"FCE94F", "FCAF3E", "E9B96E", "8AE234", "729FCF", "AD7FA8", "EF2929"};
private const string[] tango_colors_medium = {"EDD400", "F57900", "C17D11", "73D216", "3465A4", "75507B", "CC0000"};
private const string[] material_colors_800 = {"D32F2F", "C2185B", "7B1FA2", "512DA8", "303F9F", "1976D2", "0288D1", "0097A7", "00796B", "388E3C", "689F38", "AFB42B", "FFA000", "F57C00", "E64A19", "5D4037"};
private const string[] material_colors_500 = {"F44336", "E91E63", "9C27B0", "673AB7", "3f51B5", "2196F3", "03A9f4", "00BCD4", "009688", "4CAF50", "8BC34a", "CDDC39", "FFC107", "FF9800", "FF5722", "795548"};
private const string[] material_colors_300 = {"E57373", "F06292", "BA68C8", "9575CD", "7986CB", "64B5F6", "4FC3F7", "4DD0E1", "4DB6AC", "81C784", "AED581", "DCE775", "FFD54F", "FFB74D", "FF8A65", "A1887F"};
private const string[] material_colors_200 = {"EF9A9A", "F48FB1", "CE93D8", "B39DDB", "9FA8DA", "90CAF9", "81D4FA", "80DEEA", "80CBC4", "A5D6A7", "C5E1A5", "E6EE9C", "FFE082", "FFCC80", "FFAB91", "BCAAA4"};

public static string get_avatar_hex_color(StreamInteractor stream_interactor, Account account, Jid jid, Conversation? conversation = null) {
    uint hash = get_relevant_jid(stream_interactor, account, jid, conversation).to_string().hash();
    return material_colors_300[hash % material_colors_300.length];
//    return tango_colors_light[name.hash() % tango_colors_light.length];
}

public static string get_name_hex_color(StreamInteractor stream_interactor, Account account, Jid jid, bool dark_theme = false, Conversation? conversation = null) {
    uint hash = get_relevant_jid(stream_interactor, account, jid, conversation).to_string().hash();
    if (dark_theme) {
        return material_colors_300[hash % material_colors_300.length];
    } else {
        return material_colors_500[hash % material_colors_500.length];
    }
//    return tango_colors_medium[name.hash() % tango_colors_medium.length];
}

private static Jid get_relevant_jid(StreamInteractor stream_interactor, Account account, Jid jid, Conversation? conversation = null) {
    Conversation conversation_ = conversation ?? stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid.bare_jid, account);
    if (conversation_ != null && conversation_.type_ == Conversation.Type.GROUPCHAT) {
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

public static async AvatarDrawer get_conversation_avatar_drawer(StreamInteractor stream_interactor, Conversation conversation) {
    return yield get_conversation_participants_avatar_drawer(stream_interactor, conversation, new Jid[0]);
}

public static async AvatarDrawer get_conversation_participants_avatar_drawer(StreamInteractor stream_interactor, Conversation conversation, owned Jid[] jids) {
    AvatarManager avatar_manager = stream_interactor.get_module(AvatarManager.IDENTITY);
    MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
    if (conversation.type_ != Conversation.Type.GROUPCHAT) {
        Jid jid = jids.length == 1 ? jids[0] : conversation.counterpart;
        Jid avatar_jid = jid;
        if (conversation.type_ == Conversation.Type.GROUPCHAT_PM) avatar_jid = muc_manager.get_real_jid(avatar_jid, conversation.account) ?? avatar_jid;
        return new AvatarDrawer().tile(yield avatar_manager.get_avatar(conversation.account, avatar_jid), jids.length == 1 ?
                get_participant_display_name(stream_interactor, conversation, jid) :
                get_conversation_display_name(stream_interactor, conversation),
                    Util.get_avatar_hex_color(stream_interactor, conversation.account, jid, conversation));
    }
    if (jids.length > 0) {
        AvatarDrawer drawer = new AvatarDrawer();
        for (int i = 0; i < (jids.length <= 4 ? jids.length : 3); i++) {
            Jid avatar_jid = jids[i];
            Gdk.Pixbuf? part_avatar = yield avatar_manager.get_avatar(conversation.account, avatar_jid);
            if (part_avatar == null && avatar_jid.equals_bare(conversation.counterpart) && muc_manager.is_private_room(conversation.account, conversation.counterpart)) {
                avatar_jid = muc_manager.get_real_jid(avatar_jid, conversation.account) ?? avatar_jid;
                part_avatar = yield avatar_manager.get_avatar(conversation.account, avatar_jid);
            }
            drawer.tile(part_avatar, get_participant_display_name(stream_interactor, conversation, jids[i]),
                        Util.get_avatar_hex_color(stream_interactor, conversation.account, jids[i], conversation));
        }
        if (jids.length > 4) {
            drawer.plus();
        }
        return drawer;
    }
    Gdk.Pixbuf? room_avatar = yield avatar_manager.get_avatar(conversation.account, conversation.counterpart);
    Gee.List<Jid>? occupants = muc_manager.get_other_offline_members(conversation.counterpart, conversation.account);
    if (room_avatar != null || !muc_manager.is_private_room(conversation.account, conversation.counterpart) || occupants == null || occupants.size == 0) {
        return new AvatarDrawer().tile(room_avatar, "#", Util.get_avatar_hex_color(stream_interactor, conversation.account, conversation.counterpart, conversation));
    }
    AvatarDrawer drawer = new AvatarDrawer();
    for (int i = 0; i < (occupants.size <= 4 ? occupants.size : 3); i++) {
        Jid jid = occupants[i];
        Jid avatar_jid = jid;
        Gdk.Pixbuf? part_avatar = yield avatar_manager.get_avatar(conversation.account, avatar_jid);
        if (part_avatar == null && avatar_jid.equals_bare(conversation.counterpart) && muc_manager.is_private_room(conversation.account, conversation.counterpart)) {
            avatar_jid = muc_manager.get_real_jid(avatar_jid, conversation.account) ?? avatar_jid;
            part_avatar = yield avatar_manager.get_avatar(conversation.account, avatar_jid);
        }
        drawer.tile(part_avatar, get_participant_display_name(stream_interactor, conversation, jid),
                    Util.get_avatar_hex_color(stream_interactor, conversation.account, jid, conversation));
    }
    if (occupants.size > 4) {
        drawer.plus();
    }
    return drawer;
}

public static string get_conversation_display_name(StreamInteractor stream_interactor, Conversation conversation) {
    if (conversation.type_ == Conversation.Type.CHAT) {
        string? display_name = get_real_display_name(stream_interactor, conversation.account, conversation.counterpart);
        if (display_name != null) return display_name;
        return conversation.counterpart.to_string();
    }
    if (conversation.type_ == Conversation.Type.GROUPCHAT) {
        return get_groupchat_display_name(stream_interactor, conversation.account, conversation.counterpart);
    }
    if (conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
        return _("%s from %s").printf(get_occupant_display_name(stream_interactor, conversation.account, conversation.counterpart), get_groupchat_display_name(stream_interactor, conversation.account, conversation.counterpart.bare_jid));
    }
    return conversation.counterpart.to_string();
}

public static string get_participant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid participant, bool me_is_me = false) {
    if (me_is_me) {
        if (conversation.account.bare_jid.equals_bare(participant) ||
                (conversation.type_ == Conversation.Type.GROUPCHAT || conversation.type_ == Conversation.Type.GROUPCHAT_PM) &&
                        conversation.nickname != null && participant.equals_bare(conversation.counterpart) && conversation.nickname == participant.resourcepart) {
            return _("Me");
        }
    }
    if (conversation.type_ == Conversation.Type.CHAT) {
        return get_real_display_name(stream_interactor, conversation.account, participant, me_is_me) ?? participant.bare_jid.to_string();
    }
    if ((conversation.type_ == Conversation.Type.GROUPCHAT || conversation.type_ == Conversation.Type.GROUPCHAT_PM) && conversation.counterpart.equals_bare(participant)) {
        return get_occupant_display_name(stream_interactor, conversation.account, participant);
    }
    return participant.bare_jid.to_string();
}

private static string? get_real_display_name(StreamInteractor stream_interactor, Account account, Jid jid, bool me_is_me = false) {
    if (jid.equals_bare(account.bare_jid)) {
        if (me_is_me || account.alias == null || account.alias.length == 0) {
            return _("Me");
        }
        return account.alias;
    }
    Roster.Item roster_item = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(account, jid);
    if (roster_item != null && roster_item.name != null && roster_item.name != "") {
        return roster_item.name;
    }
    return null;
}

private static string get_groupchat_display_name(StreamInteractor stream_interactor, Account account, Jid jid) {
    MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
    string room_name = muc_manager.get_room_name(account, jid);
    if (room_name != null && room_name != jid.localpart) {
        return room_name;
    }
    if (muc_manager.is_private_room(account, jid)) {
        Gee.List<Jid>? other_occupants = muc_manager.get_other_offline_members(jid, account);
        if (other_occupants != null && other_occupants.size > 0) {
            var builder = new StringBuilder ();
            foreach(Jid occupant in other_occupants) {
                if (builder.len != 0) {
                    builder.append(", ");
                }
                builder.append((get_real_display_name(stream_interactor, account, occupant) ?? occupant.localpart ?? occupant.domainpart).split(" ")[0]);
            }
            return builder.str;
        }
    }
    return jid.to_string();
}

private static string get_occupant_display_name(StreamInteractor stream_interactor, Account account, Jid jid, bool me_is_me = false, bool muc_real_name = false) {
    if (muc_real_name) {
        MucManager muc_manager = stream_interactor.get_module(MucManager.IDENTITY);
        if (muc_manager.is_private_room(account, jid.bare_jid)) {
            Jid? real_jid = muc_manager.get_real_jid(jid, account);
            if (real_jid != null) {
                string? display_name = get_real_display_name(stream_interactor, account, real_jid, me_is_me);
                if (display_name != null) return display_name;
            }
        }
    }
    return jid.resourcepart ?? jid.to_string();
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

public static void force_css(Gtk.Widget widget, string css) {
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

public static Regex get_url_regex() {
    if (URL_REGEX == null) {
        URL_REGEX = /\b(((http|ftp)s?:\/\/|(ircs?|xmpp|mailto|sms|smsto|mms|tel|geo|openpgp4fpr|im|news|nntp|sip|ssh|bitcoin|sftp|magnet|vnc|urn):)\S+)/;
    }
    return URL_REGEX;
}

public static Regex get_code_block_regex() {
    if (CODE_BLOCK_REGEX == null) {
        CODE_BLOCK_REGEX = /(?:^|\n)(```([^\n]*)\n(?:[^\n]|\n[^`]|\n`[^`]|\n``[^`]|\n```[^\n])+\n```)(?:\n|$)/s;
    }
    return CODE_BLOCK_REGEX;
}

public static Map<unichar, unichar> get_matching_chars() {
    if (MATCHING_CHARS == null) {
        MATCHING_CHARS = new HashMap<unichar, unichar>();
        MATCHING_CHARS[")".get_char(0)] = "(".get_char(0);
        MATCHING_CHARS["]".get_char(0)] = "[".get_char(0);
        MATCHING_CHARS["}".get_char(0)] = "{".get_char(0);
    }
    return MATCHING_CHARS;
}

public static string parse_add_markup(string s_, string? highlight_word, bool parse_links, bool parse_text_markup, bool already_escaped_ = false) {
    string s = s_;
    bool already_escaped = already_escaped_;

    if (parse_links && !already_escaped) {
        MatchInfo match_info;
        get_url_regex().match(s.down(), 0, out match_info);
        while (match_info.matches()) {
            int start, end;
            match_info.fetch_pos(0, out start, out end);
            string link = s[start:end];
            if (GLib.Uri.parse_scheme(link) in ALLOWED_SCHEMAS) {
                Map<unichar, unichar> matching_chars = get_matching_chars();
                unichar close_char;
                int last_char_index = link.length;
                while (link.get_prev_char(ref last_char_index, out close_char)) {
                    if (matching_chars.has_key(close_char)) {
                        unichar open_char = matching_chars[close_char];
                        unichar char;
                        int index = 0;
                        int open = 0, close = 0;
                        while (link.get_next_char(ref index, out char)) {
                            if (char == open_char) {
                                open++;
                            } else if (char == close_char) {
                                close++;
                            }
                        }
                        if (close > open) {
                            // Remove last char from url
                            end -= close_char.to_string().length;
                            link = s[start:end];
                        } else {
                            break;
                        }
                    } else if (close_char in NON_TRAILING_CHARS) {
                        // Remove last char from url
                        end -= close_char.to_string().length;
                        link = s[start:end];
                    } else {
                        break;
                    }
                }

                return parse_add_markup(s[0:start], highlight_word, parse_links, parse_text_markup, already_escaped) +
                        "<a href=\"" + Markup.escape_text(link) + "\">" + parse_add_markup(link, highlight_word, false, false, already_escaped) + "</a>" +
                        parse_add_markup(s[end:s.length], highlight_word, parse_links, parse_text_markup, already_escaped);
            }
            match_info.next();
        }
    }

    if (!already_escaped) {
        s = Markup.escape_text(s);
        already_escaped = true;
    }

    if (highlight_word != null) {
        try {
            Regex highlight_regex = new Regex("\\b" + Regex.escape_string(highlight_word.down()) + "\\b");
            MatchInfo match_info;
            highlight_regex.match(s.down(), 0, out match_info);
            if (match_info.matches()) {
                int start, end;
                match_info.fetch_pos(0, out start, out end);
                return parse_add_markup(s[0:start], highlight_word, parse_links, parse_text_markup, already_escaped) +
                    "<b>" + s[start:end] + "</b>" +
                    parse_add_markup(s[end:s.length], highlight_word, parse_links, parse_text_markup, already_escaped);
            }
        } catch (RegexError e) {
            assert_not_reached();
        }
    }

    if (parse_text_markup) {
        // Try to match preformatted code blocks first
        MatchInfo code_block_match_info;
        get_code_block_regex().match(s.down().strip(), 0, out code_block_match_info);
        if (code_block_match_info.matches()) {
            int start, end;
            code_block_match_info.fetch_pos(1, out start, out end);
            return parse_add_markup(s[0:start], highlight_word, parse_links, parse_text_markup, already_escaped) +
                "<tt>" +
                s[start:end] +
                "</tt>" +
                parse_add_markup(s[end:s.length], highlight_word, parse_links, parse_text_markup, already_escaped);
        }

        string[] markup_string = new string[]{"`", "_", "*", "~"};
        string[] convenience_tag = new string[]{"tt", "i", "b", "s"};

        for (int i = 0; i < markup_string.length; i++) {
            string markup_esc = Regex.escape_string(markup_string[i]);
            try {
                Regex regex = new Regex("(^|\\s)" + markup_esc + "(\\S|\\S.*?\\S)" + markup_esc);
                MatchInfo match_info;
                regex.match(s.down(), 0, out match_info);
                if (match_info.matches()) {
                    int start, end;
                    match_info.fetch_pos(2, out start, out end);
                    return parse_add_markup(s[0:start-1], highlight_word, parse_links, parse_text_markup, already_escaped) +
                        s[start-1:start] + @"<$(convenience_tag[i])>" + s[start:end] + @"</$(convenience_tag[i])>" + s[end:end+1] +
                        parse_add_markup(s[end+1:s.length], highlight_word, parse_links, parse_text_markup, already_escaped);
                }
            } catch (RegexError e) {
                assert_not_reached();
            }
        }
    }

    return s;
}

/**
 * This is a heuristic to count emojis in a string {@link http://example.com/}
 *
 * @param markup_text string to search in
 * @return number of emojis, or -1 if text includes non-emojis.
 */
public int get_only_emoji_count(string markup_text) {
    int emoji_no = 0;
    int index_ref = 0;
    unichar curchar = 0, altchar = 0;
    bool last_was_emoji = false, last_was_modifier_base = false, last_was_keycap = false;
    while (markup_text.get_next_char(ref index_ref, out curchar)) {
        if (last_was_emoji && last_was_keycap && curchar == 0x20E3) {
            // keycap sequence
            continue;
        }

        last_was_keycap = false;

        if (last_was_emoji && curchar == 0x200D && markup_text.get_next_char(ref index_ref, out curchar)) {
            // zero width joiner
            last_was_emoji = false;
            emoji_no--;
        }

        if (last_was_emoji && curchar == 0xFE0F) {
            // Variation selector after emoji is useless, ignoring.
        } else if (last_was_emoji && last_was_modifier_base && ICU.has_binary_property(curchar, ICU.Property.EMOJI_MODIFIER)) {
            // still an emoji, but no longer a modifier base
            last_was_modifier_base = false;
        } else if (ICU.has_binary_property(curchar, ICU.Property.EMOJI_PRESENTATION)) {
            if (ICU.has_binary_property(curchar, ICU.Property.EMOJI_MODIFIER_BASE)) {
                last_was_modifier_base = true;
            }
            emoji_no++;
            last_was_emoji = true;
        } else if (curchar == ' ') {
            last_was_emoji = false;
        } else if (markup_text.get_next_char(ref index_ref, out altchar) && altchar == 0xFE0F) {
            // U+FE0F = VARIATION SELECTOR-16
            emoji_no++;
            last_was_emoji = true;
            last_was_keycap = (curchar >= 0x30 && curchar <= 0x39) || curchar == 0x23 || curchar == 0x2A;
        } else {
            return -1;
        }
    }
    return emoji_no;
}

public string summarize_whitespaces_to_space(string s) {
    try {
        return (/\s+/).replace_literal(s, -1, 0, " ");
    } catch (RegexError e) {
        assert_not_reached();
    }
}

public bool use_csd() {
    return (GLib.Application.get_default() as Application).use_csd();
}

}
