using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

enum Target {
    URI_LIST,
    STRING
}

const TargetEntry[] target_list = {
    { "text/uri-list", 0, Target.URI_LIST }
};

public class ConversationViewController {

    private ConversationView widget;

    private ChatInputController chat_input_controller;
    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    public ConversationViewController(ConversationView widget, StreamInteractor stream_interactor) {
        this.widget = widget;
        this.stream_interactor = stream_interactor;

        this.chat_input_controller = new ChatInputController(widget.chat_input, stream_interactor);

        widget.conversation_frame.init(stream_interactor);

        // drag 'n drop file upload
        Gtk.drag_dest_unset(widget.chat_input.text_input);
        Gtk.drag_dest_set(widget, DestDefaults.ALL, target_list, Gdk.DragAction.COPY);
        widget.drag_data_received.connect(this.on_drag_data_received);

        // forward key presses
        widget.chat_input.key_press_event.connect(forward_key_press_to_chat_input);
        widget.conversation_frame.key_press_event.connect(forward_key_press_to_chat_input);

        // goto-end floating button
        var vadjustment = widget.conversation_frame.scrolled.vadjustment;
        vadjustment.notify["value"].connect(() => {
            widget.goto_end_revealer.reveal_child = vadjustment.value <  vadjustment.upper - vadjustment.page_size;
        });
        widget.goto_end_button.clicked.connect(() => {
            widget.conversation_frame.initialize_for_conversation(conversation);
        });
    }

    public void select_conversation(Conversation? conversation, bool default_initialize_conversation) {
        this.conversation = conversation;

        chat_input_controller.set_conversation(conversation);

        if (default_initialize_conversation) {
            widget.conversation_frame.initialize_for_conversation(conversation);
        }
    }

    public void on_drag_data_received(Widget widget, Gdk.DragContext context, int x, int y, SelectionData selection_data, uint target_type, uint time) {
        if ((selection_data != null) && (selection_data.get_length() >= 0)) {
            switch (target_type) {
                case Target.URI_LIST:
                    string[] uris = selection_data.get_uris();
                    for (int i = 0; i < uris.length; i++) {
                        try {
                            string filename = Filename.from_uri(uris[i]);
                            stream_interactor.get_module(FileManager.IDENTITY).send_file.begin(filename, conversation);
                        } catch (Error err) {}
                    }
                    break;
                default:
                    break;
            }
        }
    }

    public bool forward_key_press_to_chat_input(EventKey event) {
        // Don't forward / change focus on Control / Alt
        if (event.keyval == Gdk.Key.Control_L || event.keyval == Gdk.Key.Control_R ||
                event.keyval == Gdk.Key.Alt_L || event.keyval == Gdk.Key.Alt_R) {
            return false;
        }
        // Don't forward / change focus on Control + ...
        if ((event.state & ModifierType.CONTROL_MASK) > 0) {
            return false;
        }
        widget.chat_input.text_input.key_press_event(event);
        widget.chat_input.text_input.grab_focus();
        return true;
    }
}
}
