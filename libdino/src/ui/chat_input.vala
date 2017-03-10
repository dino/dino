using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/org/dino-im/chat_input.ui")]
public class ChatInput : Grid {

    [GtkChild] private TextView text_input;

    private Conversation? conversation;
    private StreamInteractor stream_interactor;
    private HashMap<Conversation, string> entry_cache = new HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);
    private static HashMap<string, string> smiley_translations = new HashMap<string, string>();

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
    }

    public void initialize_for_conversation(Conversation conversation) {
        if (this.conversation != null) {
            if (text_input.buffer.text != "") {
                entry_cache[this.conversation] = text_input.buffer.text;
            } else {
                entry_cache.unset(this.conversation);
            }
        }
        this.conversation = conversation;
        text_input.buffer.text = "";
        if (entry_cache.has_key(conversation)) {
            text_input.buffer.text = entry_cache[conversation];
        }
        text_input.key_press_event.connect(on_text_input_key_press);
        text_input.key_release_event.connect(on_text_input_key_release);
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
                case "/ping": // TODO remove this
                    Xep.Ping.Module.get_module(stream_interactor.get_stream(conversation.account))
                        .send_ping(stream_interactor.get_stream(conversation.account), @"$(conversation.counterpart.bare_jid)/$(token[1])");
                    Xep.Ping.Module.get_module(stream_interactor.get_stream(conversation.account)).get_id();
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

    private bool on_text_input_key_release(EventKey event) {
        if (text_input.buffer.text != "") {
            ChatInteraction.get_instance(stream_interactor).on_message_entered(conversation);
        } else {
            ChatInteraction.get_instance(stream_interactor).on_message_cleared(conversation);
        }
        return false;
    }
}

}