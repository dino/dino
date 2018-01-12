using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ChatInput {

/**
 * - With given prefix: Complete from occupant list (sorted lexicographically)
 * - W/o prefix: Complete from received messages (most recent first)
 * - At the start (with ",") and in the middle of a text
 * - Backwards tabbing
 */
class OccupantsTabCompletor {

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private TextView text_input;

    private Gee.List<string> completions = new ArrayList<string>();
    private bool active = false;
    private int index = -1;

    public OccupantsTabCompletor(StreamInteractor stream_interactor, TextView text_input) {
        this.stream_interactor = stream_interactor;
        this.text_input = text_input;

        text_input.key_press_event.connect(on_text_input_key_press);
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;
    }

    public bool on_text_input_key_press(EventKey event) {
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            if (event.keyval == Key.Tab || event.keyval == Key.ISO_Left_Tab) {
                string text = text_input.buffer.text;
                int start_index = int.max(text.last_index_of(" "), text.last_index_of("\n")) + 1;
                string word = text.substring(start_index);
                if (!active) {
                    if (word == "") {
                        completions = generate_completions_from_messages();
                    } else {
                        completions = generate_completions_from_occupants(word);
                    }
                    if (completions.size > 0) {
                        active = true;
                        index = -1;
                    }
                }
                if (event.keyval != Key.ISO_Group_Shift && active) {
                    text_input.buffer.text = next_completion(event.keyval == Key.ISO_Left_Tab);
                    return true;
                }
            } else if (event.keyval != Key.Shift_L && active) {
                active = false;
            }
        }
        return false;
    }

    private string next_completion(bool backwards) {
        string text = text_input.buffer.text;
        int start_index = int.max(text.last_index_of(" "), text.last_index_of("\n")) + 1;
        string prev_completion = text.substring(start_index);
        if (index > -1) {
            start_index = int.max(
                text.last_index_of(completions[index]),
                text.substring(0, text.length - 1).last_index_of("\n")
            );
            prev_completion = text.substring(start_index);
        }
        if (backwards) {
            index = int.max(index, 0) - 1;
            if (index < 0) index = completions.size - 1;
        } else {
            index = (index + 1) % (completions.size);
        }
        if (start_index == 0) {
            return completions[index] + ", ";
        } else {
            return text.substring(0, text.length - prev_completion.length) + completions[index] + " ";
        }
    }

    private Gee.List<string> generate_completions_from_messages() {
        Gee.List<string> ret = new ArrayList<string>();
        Gee.List<Message> messages = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages(conversation, 10);
        for (int i = messages.size - 1; i > 0; i--) {
            string resourcepart = messages[i].from.resourcepart;
            Jid? own_nick = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
            if (resourcepart != null && resourcepart != "" && resourcepart != own_nick.resourcepart && !ret.contains(resourcepart)) {
                ret.add(resourcepart);
            }
        }
        return ret;
    }

    private Gee.List<string> generate_completions_from_occupants(string prefix) {
        Gee.List<string> ret = new ArrayList<string>();
        Gee.List<Jid>? occupants = stream_interactor.get_module(MucManager.IDENTITY).get_other_occupants(conversation.counterpart, conversation.account);
        if (occupants != null) {
            foreach (Jid jid in occupants) {
                if (jid.resourcepart.to_string().down().has_prefix(prefix.down())) {
                    ret.add(jid.resourcepart.to_string());
                }
            }
        }
        ret.sort();
        return ret;
    }
}

}
