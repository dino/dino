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

public class ConversationViewController : Object {

    public new string? conversation_display_name { get; set; }
    public string? conversation_topic { get; set; }

    private Application app;
    private ConversationView view;
    private ConversationTitlebar titlebar;
    public SearchMenuEntry search_menu_entry = new SearchMenuEntry();

    private ChatInputController chat_input_controller;
    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    public ConversationViewController(ConversationView view, ConversationTitlebar titlebar, StreamInteractor stream_interactor) {
        this.view = view;
        this.titlebar = titlebar;
        this.stream_interactor = stream_interactor;
        this.app = GLib.Application.get_default() as Application;

        this.chat_input_controller = new ChatInputController(view.chat_input, stream_interactor);

        view.conversation_frame.init(stream_interactor);

        // drag 'n drop file upload
        Gtk.drag_dest_set(view, DestDefaults.ALL, target_list, Gdk.DragAction.COPY);
        view.drag_data_received.connect(this.on_drag_data_received);

        // forward key presses
        chat_input_controller.activate_last_message_correction.connect(() => view.conversation_frame.activate_last_message_correction());
        view.chat_input.key_press_event.connect(forward_key_press_to_chat_input);
        view.conversation_frame.key_press_event.connect(forward_key_press_to_chat_input);
        titlebar.key_press_event.connect(forward_key_press_to_chat_input);

        // goto-end floating button
        var vadjustment = view.conversation_frame.scrolled.vadjustment;
        vadjustment.notify["value"].connect(() => {
            bool button_active = vadjustment.value <  vadjustment.upper - vadjustment.page_size;
            view.goto_end_revealer.reveal_child = button_active;
            view.goto_end_revealer.visible = button_active;
        });
        view.goto_end_button.clicked.connect(() => {
            view.conversation_frame.initialize_for_conversation(conversation);
        });

        // Update conversation display name & topic
        this.bind_property("conversation-display-name", titlebar, "title");
        this.bind_property("conversation-topic", titlebar, "subtitle");
        stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect((account, jid) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_conversation_display_name();
            }
        });
        stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.connect((account, room, occupant) => {
            if (conversation != null && conversation.counterpart.equals_bare(room.bare_jid) && conversation.account.equals(account)) {
                update_conversation_display_name();
            }
        });
        stream_interactor.get_module(MucManager.IDENTITY).subject_set.connect((account, jid, subject) => {
            if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                update_conversation_topic(subject);
            }
        });

        // Headerbar plugins
        app.plugin_registry.register_contact_titlebar_entry(new MenuEntry(stream_interactor));
        app.plugin_registry.register_contact_titlebar_entry(search_menu_entry);
        app.plugin_registry.register_contact_titlebar_entry(new OccupantsEntry(stream_interactor));
        foreach(var entry in app.plugin_registry.conversation_titlebar_entries) {
            titlebar.insert_entry(entry);
        }
    }

    public void select_conversation(Conversation? conversation, bool default_initialize_conversation) {
        this.conversation = conversation;

        chat_input_controller.set_conversation(conversation);

        update_conversation_display_name();
        update_conversation_topic();

        foreach(var e in this.app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget view = e.get_widget(Plugins.WidgetType.GTK);
            if (view != null) {
                view.set_conversation(conversation);
            }
        }

        if (default_initialize_conversation) {
            view.conversation_frame.initialize_for_conversation(conversation);
        }
    }

    public void unset_conversation() {
        conversation_display_name = null;
        conversation_topic = null;
    }

    private void update_conversation_display_name() {
        conversation_display_name = Util.get_conversation_display_name(stream_interactor, conversation);
    }

    private void update_conversation_topic(string? subtitle = null) {
        if (subtitle != null) {
            conversation_topic = Util.summarize_whitespaces_to_space(subtitle);
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            string? subject = stream_interactor.get_module(MucManager.IDENTITY).get_groupchat_subject(conversation.counterpart, conversation.account);
            if (subject != null) {
                conversation_topic = Util.summarize_whitespaces_to_space(subject);
            } else {
                conversation_topic = null;
            }
        } else {
            conversation_topic = null;
        }
    }

    private void on_drag_data_received(Widget widget, Gdk.DragContext context, int x, int y, SelectionData selection_data, uint target_type, uint time) {
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

    private bool forward_key_press_to_chat_input(EventKey event) {
        if (((Gtk.Window)view.get_toplevel()).get_focus() is TextView) {
            return false;
        }

        // Don't forward / change focus on Control / Alt
        if (event.keyval == Gdk.Key.Control_L || event.keyval == Gdk.Key.Control_R ||
                event.keyval == Gdk.Key.Alt_L || event.keyval == Gdk.Key.Alt_R) {
            return false;
        }
        // Don't forward / change focus on Control + ...
        if ((event.state & ModifierType.CONTROL_MASK) > 0) {
            return false;
        }
        if (view.chat_input.chat_text_view.text_view.key_press_event(event)) {
            return true;
        }
        return false;
    }
}
}
