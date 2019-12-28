using Gdk;
using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ChatInput {

class SmileyConverter {

    private TextView text_input;
    private GLib.Regex colon_regex;
    private static HashMap<string, string> smiley_translations = new HashMap<string, string>();
    private HashMap<string, unichar> emoji_translations = new HashMap<string, unichar>();

    static construct {
        smiley_translations[":)"] = "🙂";
        smiley_translations[":D"] = "😀";
        smiley_translations[";)"] = "😉";
        smiley_translations["O:)"] = "😇";
        smiley_translations["O:-)"] = "😇";
        smiley_translations["]:>"] = "😈";
        smiley_translations[":o"] = "😮";
        smiley_translations[":P"] = "😛";
        smiley_translations[";P"] = "😜";
        smiley_translations[":("] = "🙁";
        smiley_translations[":'("] = "😢";
        smiley_translations[":/"] = "😕";
    }

    /* Emoji record defined for GTK's emoji.data */

    struct EmojiRecord {
        public uint[] codepoints;
        string character;
        string shortname;
    }

    public SmileyConverter(TextView text_input) {
        this.text_input = text_input;

        text_input.key_press_event.connect(on_text_input_key_press);

        /* Regex to match colon-style emojis like :tada:, :+1:, or
         * :rainbow_flag: matching to the end of the line to avoid disrupting
         * text edited earlier in a line. We do not match the second colon
         * since we match right before it's typed at the end of a line. */

        try {
            colon_regex = new GLib.Regex(":([a-zA-Z0-9+_-]+)$");
        } catch (RegexError e) {
            assert_not_reached();
        }

        /* Load GTK's emoji database to extract a mapping from shortcodes to
         * codepoints. We load ahead of time since dictionary access is
         * effectively O(1) whereas iterating the emoji database as presented
         * is O(n), and there are a lot of emojis. Since we need to do
         * replacements frequently, efficiency and low latency matters */

        try {
            Bytes g = resources_lookup_data("/org/gtk/libgtk/emoji/emoji.data", ResourceLookupFlags.NONE);
            Variant v = Variant.new_from_data<EmojiRecord[]>(new VariantType("a(auss)"), g.get_data(), true);

            size_t length = v.n_children();

            for (uint i = 0; i < length; ++i) {
                Variant emoji = v.get_child_value(i);
                Variant points = emoji.get_child_value(0);

                uint codepoint = 0;
                string shortcode = "";

                points.get_child(0, "u", &codepoint);
                emoji.get_child(2, "s", &shortcode);

                /* Strip off the shortcode (should save some memory) */

                if (shortcode.length > 2)
                    emoji_translations[shortcode[1:-1]] = (unichar) codepoint;
            }
        } catch (Error e) {
            assert_not_reached();
        }

        /* Add a few common aliases otherwise missed */

        emoji_translations["+1"] = '👍';
        emoji_translations["-1"] = '👎';
    }

    public bool on_text_input_key_press(EventKey event) {
        if (event.keyval == Key.space || event.keyval == Key.Return) {
            check_convert();
        }

        if (event.keyval == Key.colon) {
            return check_colon_convert();
        }

        return false;
    }

    private void check_convert() {
        if (Dino.Application.get_default().settings.convert_utf8_smileys) {
            foreach (string smiley in smiley_translations.keys) {
                if (text_input.buffer.text.has_suffix(smiley)) {
                    if (text_input.buffer.text.length == smiley.length ||
                            text_input.buffer.text[text_input.buffer.text.length - smiley.length - 1] == ' ') {
                        text_input.buffer.text = text_input.buffer.text.substring(0, text_input.buffer.text.length - smiley.length) + smiley_translations[smiley];
                    }
                }
            }
        }
    }

    /* Tries to convert colon form at the end of a line, returning whether we
     * were successful so the insertion of the colon can be suppressed */

    private bool check_colon_convert() {
        string old = text_input.buffer.text;

        if (colon_regex.match(old)) {
            text_input.buffer.text = translate_colon_emoji(old);
            return true;
        }

        return false;
    }

    private bool translate_colon_match(MatchInfo info, StringBuilder result) {
        string colon_code = info.fetch(1);
        assert(colon_code != null);

        /* Normalize to improve our chances of a hit */
        string normalized = colon_code.ascii_down();

        unichar translation = emoji_translations[normalized];

        if (translation != 0) {
            /* Graphical emoji variant */
            unichar graphical_variant = (unichar) (0xFE0F);
            result.append(translation.to_string() + graphical_variant.to_string());
        } else {
            /* Restore what was there */
            result.append(":" + colon_code + ":");
        }

        return false;
    }

    private string translate_colon_emoji(string text) {
        try {
            return colon_regex.replace_eval(text, text.length, 0, 0, translate_colon_match);
        } catch (RegexError e) {
            assert_not_reached();
        }
    }
}

}
