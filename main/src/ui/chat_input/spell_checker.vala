using Gdk;
using Gee;
using Gspell;

using Dino.Entities;

namespace Dino.Ui {

public class SpellChecker {

    private Conversation? conversation;
    private TextView gspell_view;
    private HashMap<Conversation, Language> language_cache = new HashMap<Conversation, Language>(Conversation.hash_func, Conversation.equals_func);

    public SpellChecker(Gtk.TextView text_input) {
        this.gspell_view = TextView.get_from_gtk_text_view(text_input);
        gspell_view.basic_setup();
    }

    public void initialize_for_conversation(Conversation conversation) {
        Checker spell_checker = TextBuffer.get_from_gtk_text_buffer(gspell_view.view.buffer).spell_checker;

        if (this.conversation != null) language_cache[this.conversation] = spell_checker.language;

        this.conversation = conversation;

        if (language_cache.has_key(this.conversation)) {
            spell_checker.language = language_cache[conversation];
        } else {
            spell_checker.language = null;
        }
    }
}

}
