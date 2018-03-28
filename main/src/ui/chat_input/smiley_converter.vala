using Gdk;
using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ChatInput {

class SmileyConverter {

    private StreamInteractor stream_interactor;
    private TextView text_input;
    private static HashMap<string, string> smiley_translations = new HashMap<string, string>();

    static construct {
        smiley_translations[":-D"] = "😁";
        smiley_translations[":D"] = "😁";
        smiley_translations[":3"] = "😁";
        smiley_translations["XD"] = "😁";
        smiley_translations["xD"] = "😁";
        smiley_translations["xd"] = "😁";
        smiley_translations["X-D"] = "😁";
        smiley_translations["x-D"] = "😁";
        smiley_translations["x-d"] = "😁";
        smiley_translations["8)"] = "😎";
        smiley_translations["8-)"] = "😎";
        smiley_translations[";)"] = "😉";
        smiley_translations[";-)"] = "😉";
        smiley_translations["O:)"] = "😇";
        smiley_translations["O:-)"] = "😇";
        smiley_translations["]:>"] = "😈";
        smiley_translations[":o"] = "😮";
        smiley_translations[":O"] = "😮";
        smiley_translations[":-o"] = "😮";
        smiley_translations[":-O"] = "😮";
        smiley_translations[":P"] = "😛";
        smiley_translations[":-P"] = "😛";
        smiley_translations[";P"] = "😜";
        smiley_translations[";-P"] = "😜";
        smiley_translations[":("] = "🙁";
        smiley_translations[":-("] = "🙁";
        smiley_translations[":'("] = "😢";
        smiley_translations[":'-("] = "😢";
        smiley_translations[":|"] = "😐";
        smiley_translations[":-|"] = "😐";
        smiley_translations[":/"] = "😕";
        smiley_translations[":-/"] = "😕";
        smiley_translations[":*"] = "😘";
        smiley_translations[":-*"] = "😘";
        smiley_translations["<3"] = "💓";
    }

    public SmileyConverter(StreamInteractor stream_interactor, TextView text_input) {
        this.stream_interactor = stream_interactor;
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
}

}
