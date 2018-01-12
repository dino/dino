using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ChatInput {

[GtkTemplate (ui = "/im/dino/Dino/chat_input.ui")]
public class View : Box {

    [GtkChild] private ScrolledWindow scrolled;
    [GtkChild] private TextView text_input;
    [GtkChild] private Box box;

    public string text {
        owned get { return text_input.buffer.text; }
        set { text_input.buffer.text = value; }
    }

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private HashMap<Conversation, string> entry_cache = new HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);
    private int vscrollbar_min_height;
    private OccupantsTabCompletor occupants_tab_completor;
    private SmileyConverter smiley_converter;
    private EditHistory edit_history;
    private EncryptionButton encryption_widget = new EncryptionButton() { yalign=0, visible=true };

    public View(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        occupants_tab_completor = new OccupantsTabCompletor(stream_interactor, text_input);
        smiley_converter = new SmileyConverter(stream_interactor, text_input);
        edit_history = new EditHistory(text_input, GLib.Application.get_default());

        box.add(encryption_widget);
        encryption_widget.get_style_context().add_class("dino-chatinput-button");
        scrolled.get_vscrollbar().get_preferred_height(out vscrollbar_min_height, null);
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        text_input.key_press_event.connect(on_text_input_key_press);
        text_input.buffer.changed.connect(on_text_input_changed);
    }

    public void initialize_for_conversation(Conversation conversation) {
        occupants_tab_completor.initialize_for_conversation(conversation);
        edit_history.initialize_for_conversation(conversation);
        encryption_widget.set_conversation(conversation);

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
        text_input.buffer.text = "";
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
                    string[] user_role = token[1].split(" ", 2);
                    stream_interactor.get_module(MucManager.IDENTITY).change_affiliation(conversation.account, conversation.counterpart, user_role[0].strip(), user_role[1].strip());
                    return;
                case "/nick":
                    stream_interactor.get_module(MucManager.IDENTITY).change_nick(conversation.account, conversation.counterpart, token[1]);
                    return;
                case "/ping":
                    Xmpp.XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    stream.get_module(Xmpp.Xep.Ping.Module.IDENTITY).send_ping(stream, conversation.counterpart.with_resource(token[1]), null);
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
        stream_interactor.get_module(MessageProcessor.IDENTITY).send_message(text, conversation);
    }

    private bool on_text_input_key_press(EventKey event) {
        if (event.keyval in new uint[]{Key.Return, Key.KP_Enter}) {
            if ((event.state & ModifierType.SHIFT_MASK) > 0) {
                text_input.buffer.insert_at_cursor("\n", 1);
            } else if (text_input.buffer.text != ""){
                send_text();
                edit_history.reset_history();
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

    private void on_text_input_changed() {
        if (text_input.buffer.text != "") {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_message_entered(conversation);
        } else {
            stream_interactor.get_module(ChatInteraction.IDENTITY).on_message_cleared(conversation);
        }
    }
}

}
