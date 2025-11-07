using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class ConversationViewController : Object {

    public new string? conversation_display_name { get; set; }
    public string? conversation_topic { get; set; }

    private Application app;
    private ConversationView view;
    private Widget? overlay_dialog;
    private ConversationTitlebar titlebar;
    public SearchMenuEntry search_menu_entry = new SearchMenuEntry();
    public ListView list_view = new ListView(null, null);
    private DropTarget drop_event_controller = new DropTarget(typeof(File), DragAction.COPY );

    private ChatInputController chat_input_controller;
    private StreamInteractor stream_interactor;
    private Conversation? conversation;

    private const string[] KEY_COMBINATION_CLOSE_CONVERSATION = {"<Ctrl>W", null};

    public ConversationViewController(ConversationView view, ConversationTitlebar titlebar, StreamInteractor stream_interactor) {
        this.view = view;
        this.titlebar = titlebar;
        this.stream_interactor = stream_interactor;
        this.app = GLib.Application.get_default() as Application;

        this.chat_input_controller = new ChatInputController(view.chat_input, stream_interactor);
        chat_input_controller.activate_last_message_correction.connect(view.conversation_frame.activate_last_message_correction);
        chat_input_controller.file_picker_selected.connect(open_file_picker);
        chat_input_controller.clipboard_pasted.connect(on_clipboard_paste);

        view.conversation_frame.init(stream_interactor);

        // drag 'n drop file upload
        drop_event_controller.on_drop.connect(this.on_drag_data_received);

        // forward key presses
        var key_controller = new EventControllerKey() { name = "dino-forward-to-input-key-events-1" };
        key_controller.key_pressed.connect(forward_key_press_to_chat_input);
        view.conversation_frame.add_controller(key_controller);

        var key_controller2 = new EventControllerKey() { name = "dino-forward-to-input-key-events-2" };
        key_controller2.key_pressed.connect(forward_key_press_to_chat_input);
        view.chat_input.add_controller(key_controller2);

        var key_controller3 = new EventControllerKey() { name = "dino-forward-to-input-key-events-3" };
        key_controller3.key_pressed.connect(forward_key_press_to_chat_input);
        titlebar.get_widget().add_controller(key_controller3);

//      goto-end floating button
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
        stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
            if (conversation != null && conversation.account.equals(account) && conversation.counterpart.equals(jid)) {
                update_conversation_display_name();
            }
        });

        stream_interactor.get_module(FileManager.IDENTITY).upload_available.connect(update_file_upload_status);

        // Headerbar plugins
        app.plugin_registry.register_contact_titlebar_entry(new MenuEntry(stream_interactor));
        app.plugin_registry.register_contact_titlebar_entry(search_menu_entry);
        app.plugin_registry.register_contact_titlebar_entry(new OccupantsEntry(stream_interactor));
        app.plugin_registry.register_contact_titlebar_entry(new CallTitlebarEntry(stream_interactor));
        foreach(var entry in app.plugin_registry.conversation_titlebar_entries) {
            Widget? button = entry.get_widget(Plugins.WidgetType.GTK4) as Widget;
            if (button == null) {
                continue;
            }
            titlebar.insert_button(button);
        }

        Shortcut shortcut = new Shortcut(new KeyvalTrigger(Key.U, ModifierType.CONTROL_MASK), new CallbackAction(() => {
            if (conversation == null) return false;
            stream_interactor.get_module(FileManager.IDENTITY).is_upload_available.begin(conversation, (_, res) => {
                if (stream_interactor.get_module(FileManager.IDENTITY).is_upload_available.end(res)) {
                    open_file_picker();
                }
            });
            return false;
        }));
        ((Gtk.Window)view.get_root()).add_shortcut(shortcut);

        SimpleAction close_conversation_action = new SimpleAction("close-current-conversation", null);
        close_conversation_action.activate.connect(() => {
            stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
        });
        app.add_action(close_conversation_action);
        app.set_accels_for_action("app.close-current-conversation", KEY_COMBINATION_CLOSE_CONVERSATION);
    }

    public void select_conversation(Conversation? conversation, bool default_initialize_conversation) {
        if (this.conversation != null) {
            conversation.notify["encryption"].disconnect(update_file_upload_status);
        }
        if (overlay_dialog != null) {
            overlay_dialog.destroy();
        }

        this.conversation = conversation;

        // Set list model onto list view
//        Dino.Application app = GLib.Application.get_default() as Dino.Application;
//        var map_list_model = get_conversation_content_model(new ContentItemMetaModel(app.db, conversation, stream_interactor), stream_interactor);
//        NoSelection selection_model = new NoSelection(map_list_model);
//        view.list_view.set_model(selection_model);
//        view.at_current_content = true;

        conversation.notify["encryption"].connect(update_file_upload_status);

        chat_input_controller.set_conversation(conversation);

        update_conversation_display_name();
        update_conversation_topic();

        foreach(Plugins.ConversationTitlebarEntry e in this.app.plugin_registry.conversation_titlebar_entries) {
            e.set_conversation(conversation);
        }

        if (default_initialize_conversation) {
            view.conversation_frame.initialize_for_conversation(conversation);
        }

        update_file_upload_status.begin();
    }

    public void unset_conversation() {
        conversation_display_name = null;
        conversation_topic = null;
    }

    private async void update_file_upload_status() {
        if (conversation == null) return;

        bool upload_available = yield stream_interactor.get_module(FileManager.IDENTITY).is_upload_available(conversation);
        chat_input_controller.set_file_upload_active(upload_available);

        if (upload_available && overlay_dialog == null) {
            if (drop_event_controller.widget == null) {
                view.add_controller(drop_event_controller);
            }
        } else {
            if (drop_event_controller.widget != null) {
                view.remove_controller(drop_event_controller);
            }
        }
    }

    private void update_conversation_display_name() {
        conversation_display_name = Util.get_conversation_display_name(stream_interactor, conversation);
    }

    private void update_conversation_topic(string? subtitle = null) {
        if (subtitle != null) {
            string summarized_topic = Util.summarize_whitespaces_to_space(subtitle);
            conversation_topic = Util.parse_add_markup(summarized_topic, null, true, true);
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            string? subject = stream_interactor.get_module(MucManager.IDENTITY).get_groupchat_subject(conversation.counterpart, conversation.account);
            if (subject != null) {
                string summarized_topic = Util.summarize_whitespaces_to_space(subject);
                conversation_topic = Util.parse_add_markup(summarized_topic, null, true, true);
            } else {
                conversation_topic = null;
            }
        } else {
            conversation_topic = null;
        }
    }

    private async void on_clipboard_paste() {
        try {
            Clipboard clipboard = view.get_clipboard();
            Gdk.Texture? texture = yield clipboard.read_texture_async(null); // TODO critical
            var file_name = Path.build_filename(FileManager.get_storage_dir(), Xmpp.random_uuid() + ".png");
            texture.save_to_png(file_name);
            open_send_file_overlay(File.new_for_path(file_name));
        } catch (IOError.NOT_SUPPORTED e) {
            // Format not supported, ignore
        }
    }

    private bool on_drag_data_received(DropTarget target, Value val, double x, double y) {
        if (val.type() == typeof(File)) {
            open_send_file_overlay((File)val);
            return true;
        }
        return false;
    }

    private void open_file_picker() {
        FileChooserNative chooser = new FileChooserNative(_("Select file"), view.get_root() as Gtk.Window, FileChooserAction.OPEN, _("Select"), _("Cancel"));
        chooser.response.connect((response) => {
            if (response == ResponseType.ACCEPT) {
                open_send_file_overlay(File.new_for_path(chooser.get_file().get_path()));
            }
        });
        chooser.show();
    }

    private void open_send_file_overlay(File file) {
        FileInfo file_info;
        try {
            file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        } catch (Error e) { return; }

        FileSendOverlay overlay = new FileSendOverlay(file, file_info);
        overlay.send_file.connect(() => send_file(file));

        stream_interactor.get_module(FileManager.IDENTITY).get_file_size_limits.begin(conversation, (_, res) => {
            HashMap<int, long> limits = stream_interactor.get_module(FileManager.IDENTITY).get_file_size_limits.end(res);
            bool something_works = false;
            foreach (var limit in limits.values) {
                if (limit >= file_info.get_size()) {
                    something_works = true;
                }
            }
            if (!something_works && limits.has_key(0)) {
                if (!something_works && file_info.get_size() > limits[0] && overlay != null) {
                    overlay.set_file_too_large();
                }
            }
        });

        overlay.close.connect(() => {
            // We don't want drag'n'drop to be active while the overlay is active
            view.remove_overlay_dialog();
            overlay_dialog = null;
            update_file_upload_status.begin();
            overlay = null;
        });

        view.add_overlay_dialog(overlay.get_widget());
        overlay_dialog = overlay.get_widget();

        update_file_upload_status.begin();
    }

    private void send_file(File file) {
        stream_interactor.get_module(FileManager.IDENTITY).send_file.begin(file, conversation);
    }

    private bool forward_key_press_to_chat_input(EventControllerKey key_controller, uint keyval, uint keycode, Gdk.ModifierType state) {
        if (view.get_root().get_focus() is TextView) {
            return false;
        }

        // Don't forward / change focus on Control / Alt
        if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R ||
                keyval == Gdk.Key.Alt_L || keyval == Gdk.Key.Alt_R) {
            return false;
        }
        // Don't forward / change focus on Control + ...
        if ((state & ModifierType.CONTROL_MASK) > 0) {
            return false;
        }

        return key_controller.forward(view.chat_input.chat_text_view.text_view);
    }
}
}
