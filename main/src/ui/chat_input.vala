using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/org/dino-im/chat_input.ui")]
public class ChatInput : Box {

    [GtkChild] private ScrolledWindow scrolled;
    [GtkChild] private TextView text_input;

    private Conversation? conversation;
    private StreamInteractor stream_interactor;
    private HashMap<Conversation, string> entry_cache = new HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);
    private static HashMap<string, string> smiley_translations = new HashMap<string, string>();
    private int vscrollbar_min_height;

    static construct {
        smiley_translations[":)"] = "🙂";
        smiley_translations[":D"] = "😀";
        smiley_translations[";)"] = "😉";
        smiley_translations["O:)"] = "😇";
        smiley_translations["]:>"] = "😈";
        smiley_translations[":o"] = "😮";
        smiley_translations[":P"] = "😛";
        smiley_translations[";P"] = "😜";
        smiley_translations[":("] = "🙁";
        smiley_translations[":'("] = "😢";
        smiley_translations[":/"] = "😕";
        smiley_translations["-.-"] = "😑";
    }

    public ChatInput(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        scrolled.get_vscrollbar().get_preferred_height(out vscrollbar_min_height, null);
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        text_input.key_press_event.connect(on_text_input_key_press);
        text_input.buffer.changed.connect(on_text_input_changed);
    }

    public void initialize_for_conversation(Conversation conversation) {
        if (this.conversation != null) entry_cache[this.conversation] = text_input.buffer.text;
        this.conversation = conversation;

        text_input.buffer.changed.disconnect(on_text_input_changed);
        text_input.buffer.text = "";
        if (entry_cache.has_key(conversation)) {
            text_input.buffer.text = entry_cache[conversation];
        }
        text_input.buffer.changed.connect(on_text_input_changed);

        text_input.grab_focus();
    }

    private void send_text() {
        string text = text_input.buffer.text;
        if (text.has_prefix("/")) {
            string[] token = text.split(" ", 2);
            switch(token[0]) {
                case "/kick":
                    MucManager.get_instance(stream_interactor).kick(conversation.account, conversation.counterpart, token[1]);
                    break;
                case "/me":
                    MessageManager.get_instance(stream_interactor).send_message(text, conversation);
                    break;
                case "/nick":
                    MucManager.get_instance(stream_interactor).change_nick(conversation.account, conversation.counterpart, token[1]);
                    break;
                case "/topic":
                    MucManager.get_instance(stream_interactor).change_subject(conversation.account, conversation.counterpart, token[1]);
                    break;
            }
        } else {
            MessageManager.get_instance(stream_interactor).send_message(text, conversation);
        }
        text_input.buffer.text = "";
    }

    private bool on_text_input_key_press(EventKey event) {
        if (event.keyval == Key.space || event.keyval == Key.Return) {
            check_convert_smiley();
        }
        if (event.keyval == Key.Return) {
            if (event.state == ModifierType.SHIFT_MASK) {
                text_input.buffer.insert_at_cursor("\n", 1);
            } else if (text_input.buffer.text != ""){
                send_text();
            }
            return true;
        }
        return false;
    }

    private void on_upper_notify() {
        scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size;

        // hack for vscrollbar not requiring space and making textview higher //TODO doesn't resize immediately
        scrolled.get_vscrollbar().visible = (scrolled.vadjustment.upper > scrolled.max_content_height - 2 * vscrollbar_min_height);
    }

    private void check_convert_smiley() {
        if (Dino.Settings.instance().convert_utf8_smileys) {
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

    private void on_text_input_changed() {
        if (text_input.buffer.text != "") {
            ChatInteraction.get_instance(stream_interactor).on_message_entered(conversation);
        } else {
            ChatInteraction.get_instance(stream_interactor).on_message_cleared(conversation);
        }
    }
}

}