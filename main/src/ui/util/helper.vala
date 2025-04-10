using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

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

public static string get_consistent_hex_color(StreamInteractor stream_interactor, Account account, Jid jid, bool dark_theme = false) {
    uint8[] rgb;
    if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(jid.bare_jid, account) && jid.resourcepart != null) {
        rgb = ConsistentColor.string_to_rgb(jid.resourcepart);
    } else {
        rgb = ConsistentColor.string_to_rgb(jid.bare_jid.to_string());
    }
    return "%.2x%.2x%.2x".printf(rgb[0], rgb[1], rgb[2]);
}

public static string get_avatar_hex_color(StreamInteractor stream_interactor, Account account, Jid jid, Conversation? conversation = null) {
    return get_consistent_hex_color(stream_interactor, account, get_relevant_jid(stream_interactor, account, jid, conversation));
}

public static string get_name_hex_color(StreamInteractor stream_interactor, Account account, Jid jid, bool dark_theme = false, Conversation? conversation = null) {
    return get_consistent_hex_color(stream_interactor, account, get_relevant_jid(stream_interactor, account, jid, conversation), dark_theme);
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

public static string get_conversation_display_name(StreamInteractor stream_interactor, Conversation conversation) {
    return Dino.get_conversation_display_name(stream_interactor, conversation, _("%s from %s"));
}

public static string get_participant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid participant, bool me_is_me = false) {
    return Dino.get_participant_display_name(stream_interactor, conversation, participant, me_is_me ? _("Me") : null);
}

public static string? get_real_display_name(StreamInteractor stream_interactor, Account account, Jid jid, bool me_is_me = false) {
    return Dino.get_real_display_name(stream_interactor, account, jid, me_is_me ? _("Me") : null);
}

public static string get_groupchat_display_name(StreamInteractor stream_interactor, Account account, Jid jid) {
    return Dino.get_groupchat_display_name(stream_interactor, account, jid);
}

public static string get_occupant_display_name(StreamInteractor stream_interactor, Conversation conversation, Jid jid, bool me_is_me = false, bool muc_real_name = false) {
    return Dino.get_occupant_display_name(stream_interactor, conversation, jid, me_is_me ? _("Me") : null);
}

public static Gdk.RGBA get_label_pango_color(Label label, string css_color) {
    Gtk.CssProvider provider = force_color(label, css_color);
    Gdk.RGBA color_rgba = label.get_style_context().get_color();
    label.get_style_context().remove_provider(provider);
    return color_rgba;
}

public static string rgba_to_hex(Gdk.RGBA rgba) {
    return "#%02x%02x%02x%02x".printf(
            (uint8)(Math.round(rgba.red.clamp(0,1)*255)),
            (uint8)(Math.round(rgba.green.clamp(0,1)*255)),
            (uint8)(Math.round(rgba.blue.clamp(0,1)*255)),
            (uint8)(Math.round(rgba.alpha.clamp(0,1)*255)))
            .up();
}

private const string force_background_css = "%s { background-color: %s; }";
private const string force_color_css = "%s { color: %s; }";

public static Gtk.CssProvider force_css(Gtk.Widget widget, string css) {
    var p = new Gtk.CssProvider();
    try {
#if GTK_4_12 && (VALA_0_56_GREATER_11 || VALA_0_58)
        p.load_from_string(css);
#elif (VALA_0_56_11 || VALA_0_56_12)
        p.load_from_data(css, css.length);
#else
        p.load_from_data(css.data);
#endif
        widget.get_style_context().add_provider(p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    } catch (GLib.Error err) {
        // handle err
    }
    return p;
}

public static void force_background(Gtk.Widget widget, string color, string selector = "*") {
    force_css(widget, force_background_css.printf(selector, color));
}

public static Gtk.CssProvider force_color(Gtk.Widget widget, string color, string selector = "*") {
    return force_css(widget, force_color_css.printf(selector, color));
}

public static void force_error_color(Gtk.Widget widget, string selector = "*") {
    force_color(widget, "@error_color", selector);
}

public static bool is_dark_theme(Gtk.Widget widget) {
    Gdk.RGBA bg = widget.get_style_context().get_color();
    return (bg.red > 0.5 && bg.green > 0.5 && bg.blue > 0.5);
}

private static int8 is24h = 0;
public static bool is_24h_format() {
    if (is24h == 0) {
        Regex has_ampm = /(^|[^%])%[pP]/;
        Regex has_t_fmt_ampm = /(^|[^%])%r/;
        unowned string t_fmt = Posix.nl_langinfo(Posix.NLItem.T_FMT);
        unowned string t_fmt_ampm = Posix.nl_langinfo(Posix.NLItem.T_FMT_AMPM);
        bool has_am_str = Posix.nl_langinfo(Posix.NLItem.AM_STR).strip() != "";
        bool has_pm_str = Posix.nl_langinfo(Posix.NLItem.PM_STR).strip() != "";
        is24h = ((has_ampm.match(t_fmt) || has_t_fmt_ampm.match(t_fmt) && has_ampm.match(t_fmt_ampm)) && (has_am_str || has_pm_str)) ? -1 : 1;
    }
    return is24h == 1;
}

public static string format_time(DateTime datetime, string format_24h, string format_12h) {
    string format = Util.is_24h_format() ? format_24h : format_12h;
    if (!get_charset(null)) {
        // No UTF-8 support, use simple colon for time instead
        format = format.replace("∶", ":");
    }
    return datetime.format(format);
}

public static Regex get_url_regex() {
    if (URL_REGEX == null) {
        URL_REGEX = /\b(((http|ftp)s?:\/\/|(ircs?|xmpp|mailto|sms|smsto|mms|tel|geo|openpgp4fpr|im|news|nntp|sip|ssh|bitcoin|sftp|magnet|vnc|urn):)\S+)/;
    }
    return URL_REGEX;
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

/**
 * This replaces spaces with non-breaking spaces when they are adjacent to a non-spacing mark.
 *
 * We do this to work-around a bug in Pango. See https://gitlab.gnome.org/GNOME/pango/-/issues/798 and
 * https://gitlab.gnome.org/GNOME/pango/-/issues/832
 *
 * This is zero-copy iff no space is adjacent to a non-spacing mark, otherwise the provided string will be destroyed
 * and the returned string should be used instead.
 */
public static string unbreak_space_around_non_spacing_mark(owned string s) {
    int current_index = 0;
    unichar current_char = 0;
    int prev_index = 0;
    unichar prev_char = 0;
    bool is_non_spacing_mark = false;
    while (s.get_next_char(ref current_index, out current_char)) {
        int replace_index = -1;
        if (is_non_spacing_mark && current_char == ' ') {
            replace_index = prev_index;
            current_char = ' ';
        }
        is_non_spacing_mark = ICU.get_int_property_value(current_char, ICU.Property.BIDI_CLASS) == ICU.CharDirection.DIR_NON_SPACING_MARK;
        if (prev_char == ' ' && is_non_spacing_mark) {
            replace_index = prev_index - 1;
        }
        if (replace_index != -1) {
            s = s[0:replace_index] + " " + s[(replace_index + 1):s.length];
            current_index += 1;
        }
        prev_index = current_index;
        prev_char = current_char;
    }
    return (owned) s;
}

public static string parse_add_markup(string s_, string? highlight_word, bool parse_links, bool parse_text_markup) {
    bool ignore_out_var = false;
    return parse_add_markup_theme(s_, highlight_word, parse_links, parse_text_markup, parse_text_markup, false, ref ignore_out_var);
}

public static string parse_add_markup_theme(string s_, string? highlight_word, bool parse_links, bool parse_text_markup, bool parse_quotes, bool dark_theme, ref bool theme_dependent, bool already_escaped_ = false) {
    string s = s_;
    bool already_escaped = already_escaped_;

    if (parse_quotes) {
        string gt = already_escaped ? "&gt;" : ">";
        Regex quote_regex = new Regex("((?<=\n)" + gt + ".*(\n|$))|(^" + gt + ".*(\n|$))");
        MatchInfo quote_match_info;
        quote_regex.match(s.down(), 0, out quote_match_info);
        if (quote_match_info.matches()) {
            int start, end;

            string dim_color = dark_theme ? "#BDBDBD": "#707070";

            theme_dependent = true;
            quote_match_info.fetch_pos(0, out start, out end);
            return parse_add_markup_theme(s[0:start], highlight_word, parse_links, parse_text_markup, parse_quotes, dark_theme, ref theme_dependent, already_escaped) +
                    @"<span color='$dim_color'>$gt" + parse_add_markup_theme(s[start + gt.length:end], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped) + "</span>" +
                    parse_add_markup_theme(s[end:s.length], highlight_word, parse_links, parse_text_markup, parse_quotes, dark_theme, ref theme_dependent, already_escaped);
        }
    }

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

                return parse_add_markup_theme(s[0:start], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped) +
                        "<a href=\"" + Markup.escape_text(link) + "\">" +
                        parse_add_markup_theme(link, highlight_word, false, false, false, dark_theme, ref theme_dependent, already_escaped) +
                        "</a>" +
                        parse_add_markup_theme(s[end:s.length], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped);
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
                return parse_add_markup_theme(s[0:start], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped) +
                    "<b>" + s[start:end] + "</b>" +
                    parse_add_markup_theme(s[end:s.length], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped);
            }
        } catch (RegexError e) {
            assert_not_reached();
        }
    }

    if (parse_text_markup) {
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
                    return parse_add_markup_theme(s[0:start-1], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped) +
                        "<span color='#9E9E9E'>" +  s[start-1:start] + "</span>" +
                        @"<$(convenience_tag[i])>" + s[start:end] + @"</$(convenience_tag[i])>" +
                        "<span color='#9E9E9E'>" + s[end:end+1] + "</span>" +
                        parse_add_markup_theme(s[end+1:s.length], highlight_word, parse_links, parse_text_markup, false, dark_theme, ref theme_dependent, already_escaped);
                }
            } catch (RegexError e) {
                assert_not_reached();
            }
        }
    }

    return s;
}

    // Modifies `markups`.
    public string remove_fallbacks_adjust_markups(string text, bool contains_quote, Gee.List<Xep.FallbackIndication.Fallback> fallbacks, Gee.List<Xep.MessageMarkup.Span> markups) {
        string processed_text = text;

        foreach (var fallback in fallbacks) {
            if (fallback.ns_uri == Xep.Replies.NS_URI && contains_quote) {
                foreach (var fallback_location in fallback.locations) {
                    processed_text = processed_text[0:processed_text.index_of_nth_char(fallback_location.from_char)] +
                            processed_text[processed_text.index_of_nth_char(fallback_location.to_char):processed_text.length];

                    int length = fallback_location.to_char - fallback_location.from_char;
                    foreach (Xep.MessageMarkup.Span span in markups) {
                        if (span.start_char > fallback_location.to_char) {
                            span.start_char -= length;
                        }
                        if (span.end_char > fallback_location.to_char) {
                            span.end_char -= length;
                        }
                    }
                }
            }
        }
        return processed_text;
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
        critical("RegexError when summarizing whitespaces in '%s': %s", s, e.message);
        return s;
    }
}

public void present_window(Window window) {
#if GDK3_WITH_X11
        Gdk.X11.Window x11window = window.get_window() as Gdk.X11.Window;
    if (x11window != null) {
        window.present_with_time(Gdk.X11.get_server_time(x11window));
    } else {
        window.present();
    }
#else
    window.present();
#endif
}

public Widget? widget_if_tooltips_active(Widget w) {
    return use_tooltips() ? w : null;
}

public string? string_if_tooltips_active(string? s) {
    return use_tooltips() ? s : null;
}

public bool use_tooltips() {
    return Gtk.MINOR_VERSION != 6 || (Gtk.MICRO_VERSION < 4 || Gtk.MICRO_VERSION > 6);
}

public static void menu_button_set_icon_with_size(MenuButton menu_button, string icon_name, int pixel_size) {
#if GTK_4_6 && VALA_0_52
    menu_button.set_child(new Image.from_icon_name(icon_name) { pixel_size=pixel_size });
#else
    menu_button.set_icon_name(icon_name);
    var button = menu_button.get_first_child() as Button;
    if (button == null) return;
    var box = button.child as Box;
    if (box == null) return;
    var image = box.get_first_child() as Image;
    if (image == null) return;
    image.pixel_size = pixel_size;
#endif
}

}
