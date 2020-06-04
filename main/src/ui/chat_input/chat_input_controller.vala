using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {
private const string OPEN_CONVERSATION_DETAILS_URI = "x-dino:open-conversation-details";

public class ChatInputController : Object {

    public signal void activate_last_message_correction();
    public signal void file_picker_selected();
    public signal void clipboard_pasted();

    public new string? conversation_display_name { get; set; }
    public string? conversation_topic { get; set; }

    private Conversation? conversation;
    private ChatInput.View chat_input;
    private Label status_description_label;

    private StreamInteractor stream_interactor;
    private Plugins.InputFieldStatus input_field_status;
    private ChatTextViewController chat_text_view_controller;

    public ChatInputController(ChatInput.View chat_input, StreamInteractor stream_interactor) {
        this.chat_input = chat_input;
        this.status_description_label = chat_input.chat_input_status;
        this.stream_interactor = stream_interactor;
        this.chat_text_view_controller = new ChatTextViewController(chat_input.chat_text_view, stream_interactor);

        chat_input.init(stream_interactor);

        reset_input_field_status();

        chat_input.chat_text_view.text_view.buffer.changed.connect(on_text_input_changed);
        chat_input.chat_text_view.text_view.key_press_event.connect(on_text_input_key_press);
        chat_input.chat_text_view.text_view.paste_clipboard.connect(() => clipboard_pasted());

        chat_text_view_controller.send_text.connect(send_text);

        chat_input.encryption_widget.encryption_changed.connect(on_encryption_changed);

        chat_input.file_button.clicked.connect(() => file_picker_selected());

        stream_interactor.get_module(MucManager.IDENTITY).received_occupant_role.connect(update_moderated_input_status);
        stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect(update_moderated_input_status);

        status_description_label.activate_link.connect((uri) => {
            if (uri == OPEN_CONVERSATION_DETAILS_URI){
                ContactDetails.Dialog contact_details_dialog = new ContactDetails.Dialog(stream_interactor, conversation);
                contact_details_dialog.set_transient_for((Gtk.Window) chat_input.get_toplevel());
                contact_details_dialog.present();
            }
            return true;
        });
    }

    public void set_conversation(Conversation conversation) {
        this.conversation = conversation;

        reset_input_field_status();

        chat_input.encryption_widget.set_conversation(conversation);

        chat_input.initialize_for_conversation(conversation);
        chat_text_view_controller.initialize_for_conversation(conversation);

        update_moderated_input_status(conversation.account);
    }

    public void set_file_upload_active(bool active) {
        chat_input.set_file_upload_active(active);
    }

    private void on_encryption_changed(Plugins.EncryptionListEntry? encryption_entry) {
        reset_input_field_status();

        if (encryption_entry == null) return;

        encryption_entry.encryption_activated(conversation, set_input_field_status);
    }

    private void set_input_field_status(Plugins.InputFieldStatus? status) {
        input_field_status = status;

        chat_input.set_input_state(status.message_type);

        status_description_label.use_markup = status.contains_markup;

        status_description_label.label = status.message;

        chat_input.file_button.sensitive = status.input_state == Plugins.InputFieldStatus.InputState.NORMAL;
    }

    private void reset_input_field_status() {
        set_input_field_status(new Plugins.InputFieldStatus("", Plugins.InputFieldStatus.MessageType.NONE, Plugins.InputFieldStatus.InputState.NORMAL));
    }

    private void send_text() {
        // Don't do anything if we're in a NO_SEND state. Don't clear the chat input, don't send.
        if (input_field_status.input_state == Plugins.InputFieldStatus.InputState.NO_SEND) {
            chat_input.highlight_state_description();
            return;
        }

        string text = chat_input.chat_text_view.text_view.buffer.text;
        chat_input.chat_text_view.text_view.buffer.text = "";
        if (text.has_prefix("/")) {
            string[] token = text.split(" ", 2);
            switch(token[0]) {
                case "/me":
                    // Just send as is.
                    break;
                case "/say":
                    if (token.length == 1) return;
                    text = token[1];
                    break;
                case "/kick":
                    stream_interactor.get_module(MucManager.IDENTITY).kick(conversation.account, conversation.counterpart, token[1]);
                    return;
                case "/affiliate":
                    if (token.length > 1) {
                        string[] user_role = token[1].split(" ", 2);
                        if (user_role.length == 2) {
                            stream_interactor.get_module(MucManager.IDENTITY).change_affiliation(conversation.account, conversation.counterpart, user_role[0].strip(), user_role[1].strip());
                        }
                    }
                    return;
                case "/nick":
                    stream_interactor.get_module(MucManager.IDENTITY).change_nick(conversation, token[1]);
                    return;
                case "/ping":
                    Xmpp.XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    try {
                        stream.get_module(Xmpp.Xep.Ping.Module.IDENTITY).send_ping(stream, conversation.counterpart.with_resource(token[1]), null);
                    } catch (Xmpp.InvalidJidError e) {
                        warning("Could not ping invalid Jid: %s", e.message);
                    }
                    return;
                case "/topic":
                    stream_interactor.get_module(MucManager.IDENTITY).change_subject(conversation.account, conversation.counterpart, token[1]);
                    return;
                default:
                    if (token[0].has_prefix("//")) {
                        text = text.substring(1);
                    } else {
                        string cmd_name = token[0].substring(1);
                        Dino.Application app = GLib.Application.get_default() as Dino.Application;
                        if (app != null && app.plugin_registry.text_commands.has_key(cmd_name)) {
                            string? new_text = app.plugin_registry.text_commands[cmd_name].handle_command(token[1], conversation);
                            if (new_text == null) return;
                            text = (!)new_text;
                        }
                    }
                    break;
            }
        }
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_text(text, conversation);
    }

    private void on_text_input_changed() {
        if (chat_input.chat_text_view.text_view.buffer.text != "") {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_message_entered(conversation);
        } else {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_message_cleared(conversation);
        }
    }

    private void update_moderated_input_status(Account account, Xmpp.Jid? jid = null) {
        if (conversation != null && conversation.type_ == Conversation.Type.GROUPCHAT){
            Xmpp.Jid? own_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
            if (own_jid == null) return;
            if (stream_interactor.get_module(MucManager.IDENTITY).is_moderated_room(conversation.account, conversation.counterpart) &&
                    stream_interactor.get_module(MucManager.IDENTITY).get_role(own_jid, conversation.account) == Xmpp.Xep.Muc.Role.VISITOR) {
                string msg_str = _("This conference does not allow you to send messages.") + " <a href=\"" + OPEN_CONVERSATION_DETAILS_URI + "\">" + _("Request permission") + "</a>";
                set_input_field_status(new Plugins.InputFieldStatus(msg_str, Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND, true));
            } else {
                reset_input_field_status();
            }
        }
    }

    private bool on_text_input_key_press(EventKey event) {
        if (event.keyval == Gdk.Key.Up && chat_input.chat_text_view.text_view.buffer.text == "") {
            activate_last_message_correction();
            return true;
        } else {
            chat_input.chat_text_view.text_view.grab_focus();
        }
        return false;
    }
}

}
