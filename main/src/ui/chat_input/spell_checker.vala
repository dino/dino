using Gdk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class SpellChecker {

    private Conversation? conversation;
    private Gtk.TextView text_input;

    public SpellChecker(Gtk.TextView text_input) {
        this.text_input = text_input;

        // We can't keep a reference to GspellTextView/Buffer around, otherwise they'd get freed twice
        Gspell.TextView text_view = Gspell.TextView.get_from_gtk_text_view(text_input);
        Gspell.TextBuffer text_buffer = Gspell.TextBuffer.get_from_gtk_text_buffer(text_view.view.buffer);

        text_view.basic_setup();
        text_buffer.spell_checker.notify["language"].connect(lang_changed);

        // Enable/Disable spell checking live
        Dino.Application.get_default().settings.notify["check-spelling"].connect((obj, _) => {
            if (((Dino.Entities.Settings) obj).check_spelling) {
                initialize_for_conversation(this.conversation);
            } else {
                text_buffer.set_spell_checker(null);
            }
        });
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;

        Gspell.TextView text_view = Gspell.TextView.get_from_gtk_text_view(text_input);
        Gspell.TextBuffer text_buffer = Gspell.TextBuffer.get_from_gtk_text_buffer(text_view.view.buffer);

        if (!Dino.Application.get_default().settings.check_spelling) {
            text_buffer.set_spell_checker(null);
            return;
        }
        if (text_buffer.spell_checker == null) text_buffer.spell_checker = new Gspell.Checker(null);

        // Set the conversation language (from cache or db)
        text_buffer.spell_checker.notify["language"].disconnect(lang_changed);

        var db = Dino.Application.get_default().db;
        Qlite.RowOption row_option = db.conversation_settings.select()
                .with(db.conversation_settings.conversation_id, "=", conversation.id)
                .with(db.conversation_settings.key, "=", "lang")
                .single().row();
        if (row_option.is_present()) {
            string lang_code = row_option.inner[db.conversation_settings.value];
            Gspell.Language? lang = Gspell.Language.lookup(lang_code);
            text_buffer.spell_checker.language = lang;
        } else {
            text_buffer.spell_checker.language = null;
        }

        text_buffer.spell_checker.notify["language"].connect(lang_changed);
    }

    private void lang_changed() {
        var db = Dino.Application.get_default().db;

        Gspell.TextView text_view = Gspell.TextView.get_from_gtk_text_view(text_input);
        Gspell.TextBuffer text_buffer = Gspell.TextBuffer.get_from_gtk_text_buffer(text_view.view.buffer);
        Gspell.Checker spell_checker = text_buffer.spell_checker;
        if (spell_checker.language.get_code() == null) return;

        db.conversation_settings.upsert()
                .value(db.conversation_settings.conversation_id, conversation.id, true)
                .value(db.conversation_settings.key, "lang", true)
                .value(db.conversation_settings.value, spell_checker.language.get_code())
                .perform();
    }
}

}
