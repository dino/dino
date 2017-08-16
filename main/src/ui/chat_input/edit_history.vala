using Gdk;
using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ChatInput {

class EditHistory {

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private TextView text_input;

    private HashMap<Conversation, Gee.List<string>> histories = new HashMap<Conversation, Gee.List<string>>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<Conversation, int> indices = new HashMap<Conversation, int>(Conversation.hash_func, Conversation.equals_func);

    public EditHistory(TextView text_input, GLib.Application application) {
        this.stream_interactor = stream_interactor;
        this.text_input = text_input;

        text_input.key_press_event.connect(on_text_input_key_press);
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;
        if (!histories.has_key(conversation)) {
            reset_history();
        }
    }

    public bool on_text_input_key_press(EventKey event) {
        if ((event.state & ModifierType.CONTROL_MASK) > 0) {
            if (event.keyval == Key.z) {
                undo();
            } else if (event.keyval == Key.Z) {
                redo();
            }
        } else if (event.keyval in new uint[]{ Key.space, Key.Tab, Key.ISO_Left_Tab }) {
            if (indices[conversation] < histories[conversation].size - 1) {
                histories[conversation] = histories[conversation].slice(0, indices[conversation] + 1);
            }
            save_state();
        }
        return false;
    }

    private void undo() {
        if (histories[conversation][indices[conversation]] != text_input.buffer.text) {
            save_state();
        }
        if (indices[conversation] > 0) {
            indices[conversation] = indices[conversation] - 1;
            text_input.buffer.text = histories[conversation][indices[conversation]];
        }
    }

    private void redo() {
        if (indices[conversation] < histories[conversation].size - 1) {
            indices[conversation] = indices[conversation] + 1;
            text_input.buffer.text = histories[conversation][indices[conversation]];
        }
    }

    private void save_state() {
        histories[conversation].add(text_input.buffer.text);
        indices[conversation] = indices[conversation] + 1;
    }

    public void reset_history() {
        histories[conversation] = new ArrayList<string>();
        histories[conversation].add("");
        indices[conversation] = 0;
    }
}

}
