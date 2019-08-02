using Gdk;
using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ChatInput {

public class EditHistory {

    private Conversation? conversation;
    private TextView text_input;

    private HashMap<Conversation, Gee.List<string>> histories = new HashMap<Conversation, Gee.List<string>>(Conversation.hash_func, Conversation.equals_func);
    private HashMap<Conversation, int> indices = new HashMap<Conversation, int>(Conversation.hash_func, Conversation.equals_func);

    public EditHistory(TextView text_input, GLib.Application application) {
        this.text_input = text_input;

        text_input.key_press_event.connect(on_text_input_key_press);
        text_input.cut_clipboard.connect_after(save_state);
        text_input.paste_clipboard.connect_after(save_state);
        text_input.move_cursor.connect_after(save_state);
        text_input.button_release_event.connect_after(() => { save_state(); return false; });
    }

    public void initialize_for_conversation(Conversation conversation) {
        this.conversation = conversation;
        if (!histories.has_key(conversation)) {
            reset_history();
        }
    }

    public bool on_text_input_key_press(EventKey event) {
        bool ctrl_pressed = (event.state & ModifierType.CONTROL_MASK) > 0;
        if (ctrl_pressed && event.keyval == Key.z) {
            undo();
        } else if (ctrl_pressed && (event.keyval in new uint[]{ Key.Z, Key.y } )) {
            redo();
        } else if (event.keyval in new uint[]{ Key.space, Key.Tab, Key.ISO_Left_Tab }) {
            save_state();
        }
        return false;
    }

    private void undo() {
        save_state();
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
        if (histories[conversation][indices[conversation]] == text_input.buffer.text) return;
        if (indices[conversation] < histories[conversation].size - 1) {
            histories[conversation] = histories[conversation].slice(0, indices[conversation] + 1);
        }
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
