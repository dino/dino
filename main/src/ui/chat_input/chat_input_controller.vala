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

    private ContentItem? quoted_content_item = null;

    public ChatInputController(ChatInput.View chat_input, StreamInteractor stream_interactor) {
        this.chat_input = chat_input;
        this.status_description_label = chat_input.chat_input_status;
        this.stream_interactor = stream_interactor;
        this.chat_text_view_controller = new ChatTextViewController(chat_input.chat_text_view, stream_interactor);

        chat_input.init(stream_interactor);

        reset_input_field_status();

        var text_input_key_events = new EventControllerKey() { name = "dino-text-input-controller-key-events" };
        text_input_key_events.key_pressed.connect(on_text_input_key_press);
        chat_input.chat_text_view.text_view.add_controller(text_input_key_events);

        chat_input.chat_text_view.text_view.paste_clipboard.connect(() => clipboard_pasted());
        chat_input.chat_text_view.text_view.buffer.changed.connect(on_text_input_changed);

        chat_text_view_controller.send_text.connect(send_text);

        chat_input.encryption_widget.encryption_changed.connect(on_encryption_changed);

        chat_input.file_button.clicked.connect(() => file_picker_selected());

        stream_interactor.get_module(MucManager.IDENTITY).received_occupant_role.connect(update_moderated_input_status);
        stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect(update_moderated_input_status);

        status_description_label.activate_link.connect((uri) => {
            if (uri == OPEN_CONVERSATION_DETAILS_URI){
                var conversation_details = ConversationDetails.setup_dialog(conversation, stream_interactor, (Window)chat_input.get_root());
                conversation_details.present();
            }
            return true;
        });

        SimpleAction quote_action = new SimpleAction("quote", new VariantType.tuple(new VariantType[]{VariantType.INT32, VariantType.INT32}));
        quote_action.activate.connect((variant) => {
            int conversation_id = variant.get_child_value(0).get_int32();
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_by_id(conversation_id);
            if (conversation == null || !this.conversation.equals(conversation)) return;

            int content_item_id = variant.get_child_value(1).get_int32();
            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(conversation, content_item_id);
            if (content_item == null) return;

            quoted_content_item = content_item;
            var quote_model = new Quote.Model.from_content_item(content_item, conversation, stream_interactor) { can_abort = true };
            quote_model.aborted.connect(() => {
                quoted_content_item = null;
                chat_input.unset_quoted_message();
            });
            chat_input.set_quoted_message(Quote.get_widget(quote_model));
        });
        GLib.Application.get_default().add_action(quote_action);
    }

    public void set_conversation(Conversation conversation) {
        reset_input_field_status();
        this.quoted_content_item = null;
        chat_input.unset_quoted_message();

        this.conversation = conversation;

        chat_input.encryption_widget.set_conversation(conversation);

        chat_input.initialize_for_conversation(conversation);
        chat_text_view_controller.initialize_for_conversation(conversation);

        update_moderated_input_status(conversation.account);
    }

    public void set_file_upload_active(bool active) {
        chat_input.set_file_upload_active(active);
    }

    private void on_encryption_changed(Encryption encryption) {
        reset_input_field_status();

        if (encryption == Encryption.NONE || encryption == Encryption.UNKNOWN) return;

        Application app = GLib.Application.get_default() as Application;
        var encryption_entry = app.plugin_registry.encryption_list_entries[encryption];
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
        ContentItem? quoted_content_item_bak = quoted_content_item;

        // Reset input state. Has do be done before parsing commands, because those directly return.
        chat_input.chat_text_view.text_view.buffer.text = "";
        chat_input.unset_quoted_message();
        quoted_content_item = null;

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
                        string[] user_role = token[1].split(" ");
                        if (user_role.length >= 2) {
                            string nick = string.joinv(" ", user_role[0:user_role.length - 1]).strip();
                            string role = user_role[user_role.length - 1].strip();
                            stream_interactor.get_module(MucManager.IDENTITY).change_affiliation(conversation.account, conversation.counterpart, nick, role);
                        }
                    }
                    return;
                case "/nick":
                    stream_interactor.get_module(MucManager.IDENTITY).change_nick.begin(conversation, token[1]);
                    return;
                case "/ping":
                    Xmpp.XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    try {
                        stream.get_module(Xmpp.Xep.Ping.Module.IDENTITY).send_ping.begin(stream, conversation.counterpart.with_resource(token[1]));
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
        Message out_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(text, conversation);
        if (quoted_content_item_bak != null) {
            stream_interactor.get_module(Replies.IDENTITY).set_message_is_reply_to(out_message, quoted_content_item_bak);
        }
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(out_message, conversation);
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

    private bool on_text_input_key_press(uint keyval, uint keycode, Gdk.ModifierType state) {
        if (keyval == Gdk.Key.Up && chat_input.chat_text_view.text_view.buffer.text == "") {
            activate_last_message_correction();
            return true;
        } else {
            chat_input.do_focus();
        }
        return false;
    }
}

}
