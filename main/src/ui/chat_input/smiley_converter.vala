using Gdk;
using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ChatInput {

class SmileyConverter {

    private TextView text_input;
    private static HashMap<string, string> smiley_translations = new HashMap<string, string>();
    private Regex whitespace_regex = /\s/;

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
        smiley_translations["<3"] = "❤️";
    }

    public SmileyConverter(TextView text_input) {
        this.text_input = text_input;

        text_input.key_press_event.connect(on_text_input_key_press);
    }

    public bool on_text_input_key_press(EventKey event) {
        if (event.keyval == Key.space || event.keyval == Key.Return) {
            check_convert();
        }
        return false;
    }

    private void check_convert() {
        if (!Dino.Application.get_default().settings.convert_utf8_smileys) return;

        TextIter? start_iter;
        text_input.buffer.get_start_iter(out start_iter);
        TextIter? cursor_iter;
        text_input.buffer.get_iter_at_mark(out cursor_iter, text_input.buffer.get_insert());
        if (start_iter == null || cursor_iter == null) return;

        string text = text_input.buffer.get_text(start_iter, cursor_iter, true);

        foreach (string smiley in smiley_translations.keys) {
            if (text.has_suffix(smiley)) {
                if (text.length == smiley.length || whitespace_regex.match(text[text.length - smiley.length - 1].to_string())) {
                    TextIter? end_iter;
                    text_input.buffer.get_end_iter(out end_iter);
                    if (end_iter == null) continue;

                    TextIter smiley_start_iter = cursor_iter;
                    smiley_start_iter.backward_chars(smiley.length);
                    text_input.buffer.delete(ref smiley_start_iter, ref cursor_iter);
                    text_input.buffer.insert_text(ref cursor_iter, smiley_translations[smiley], smiley_translations[smiley].length);
                }
            }
        }
    }
}

}
