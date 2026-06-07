using Gee;
using Gtk;
using Gdk;
using Pango;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/im/dino/Dino/conversation_content_view/view.ui")]
public class ConversationView : Widget, Plugins.ConversationItemCollection, Plugins.NotificationCollection {
    private const int MESSAGE_MENU_BOX_OFFSET = -20;
    private const double SELECTION_DRAG_THRESHOLD = 4;

    public Conversation? conversation { get; private set; }

    [GtkChild] public unowned ScrolledWindow scrolled;
    [GtkChild] private unowned Revealer notification_revealer;
    [GtkChild] private unowned Box message_menu_box;
    [GtkChild] private unowned Box notifications;
    [GtkChild] private unowned Box main;
    [GtkChild] private unowned Widget main_wrap_box;

    private HashMap<string, Widget> action_buttons = new HashMap<string, Widget>();
    private Gee.List<Dino.Plugins.MessageAction>? message_actions = null;

    private StreamInteractor stream_interactor;
    private Gee.TreeSet<ContentMetaItem> content_items = new Gee.TreeSet<ContentMetaItem>(compare_content_meta_items);
    private Gee.TreeSet<ContentMetaItem> selected_content_items = new Gee.TreeSet<ContentMetaItem>(compare_content_meta_items);
    private Gee.TreeSet<Plugins.MetaConversationItem> meta_items = new TreeSet<Plugins.MetaConversationItem>(compare_meta_items);
    private Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton> item_item_skeletons = new Gee.HashMap<Plugins.MetaConversationItem, ConversationItemSkeleton>();
    private Gee.HashMap<Plugins.MetaConversationItem, Widget> widgets = new Gee.HashMap<Plugins.MetaConversationItem, Widget>();
    private Gee.List<Widget> widget_order = new Gee.ArrayList<Widget>();
    private ContentProvider content_populator;
    private SubscriptionNotitication subscription_notification;

    private double? was_value;
    private double? was_upper;
    private double? was_page_size;

    private Mutex reloading_mutex = Mutex();
    private bool firstLoad = true;
    private bool at_current_content = true;
    private bool reload_messages = true;
    Widget currently_highlighted = null;
    ContentMetaItem? current_meta_item = null;
    ContentMetaItem? selection_anchor_item = null;
    ContentMetaItem? selection_drag_anchor_item = null;
    bool selection_drag_active = false;
    double selection_drag_start_x = 0;
    double selection_drag_start_y = 0;
    double last_y = -1;

    private Button create_action_button(string action_name) {
        var button = new Button() { name=action_name };
        button.clicked.connect(on_action_button_clicked);
        action_buttons[action_name] = button;
        message_menu_box.append(button);
        return button;
    }

    construct {
        this.layout_manager = new BinLayout();
        this.focusable = true;
        main_wrap_box.layout_manager = new BinLayout();

        // Setup all message menu buttons
        create_action_button("correction");

        var reaction_button = new MenuButton() { name="reaction" };
        EmojiChooser chooser = new EmojiChooser();
        chooser.emoji_picked.connect((emoji) => {
            invoke_message_action("reaction", new GLib.Variant.string(emoji));
        });
        reaction_button.popover = chooser;
        action_buttons["reaction"] = reaction_button;
        message_menu_box.append(reaction_button);

        create_action_button("reply");
        create_action_button("delete");

        var menu_button = new MenuButton() { name="menu", tooltip_text=_("More actions") };
        action_buttons["menu"] = menu_button;
        message_menu_box.append(menu_button);

        SimpleAction action_action = new SimpleAction("action", VariantType.STRING);
        action_action.activate.connect((parameter) => {
            on_action_selected(parameter.get_string());
        });
        SimpleActionGroup action_group = new SimpleActionGroup();
        action_group.insert(action_action);
        this.insert_action_group("action", action_group);
    }

    public ConversationView init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);
        scrolled.vadjustment.notify["page-size"].connect(on_upper_notify);
        scrolled.vadjustment.notify["value"].connect(on_value_notify);

        content_populator = new ContentProvider(stream_interactor);
        subscription_notification = new SubscriptionNotitication(stream_interactor);

        add_meta_notification.connect(on_add_meta_notification);
        remove_meta_notification.connect(on_remove_meta_notification);

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_conversation_addition_populator(new ChatStatePopulator(stream_interactor));
        app.plugin_registry.register_conversation_addition_populator(new DateSeparatorPopulator(stream_interactor));
        app.plugin_registry.register_conversation_addition_populator(new UnreadIndicatorPopulator(stream_interactor));

        // Rather than connecting to the leave event of the main_event_box directly,
        // we connect to the parent event box that also wraps the overlaying message_menu_box.
        // This eliminates the unwanted leave events emitted on the main_event_box when hovering
        // the overlaying menu buttons.
        EventControllerMotion main_wrap_motion_events = new EventControllerMotion();
        main_wrap_box.add_controller(main_wrap_motion_events);
        main_wrap_motion_events.leave.connect(on_leave_notify_event);
        // The buttons of the overlaying message_menu_box may partially overlap the adjacent
        // conversation items. We connect to the main_event_box directly to avoid emitting
        // the pointer motion events as long as the pointer is above the message menu.
        // This ensures that the currently highlighted item remains unchanged when the pointer
        // reaches the overlapping part of a button.
        EventControllerMotion main_motion_events = new EventControllerMotion();
        main_motion_events.propagation_phase = Gtk.PropagationPhase.CAPTURE;
        main.add_controller(main_motion_events);
        main_motion_events.motion.connect((x, y) => {
            if ((main_motion_events.get_current_event_state() & ModifierType.BUTTON1_MASK) > 0 && selection_drag_anchor_item != null) {
                update_selection_drag(x, y);
            } else {
                update_highlight(x, y);
            }
        });

        // Process touch events and capture phase to allow highlighting a message without cursor
        GestureClick click_controller = new GestureClick();
        click_controller.touch_only = true;
        click_controller.propagation_phase = Gtk.PropagationPhase.CAPTURE;
        main_wrap_box.add_controller(click_controller);
        click_controller.pressed.connect_after((n, x, y) => {
            update_highlight(x, y);
        });

        GestureClick selection_click_controller = new GestureClick();
        selection_click_controller.button = 1;
        selection_click_controller.propagation_phase = Gtk.PropagationPhase.CAPTURE;
        main.add_controller(selection_click_controller);
        selection_click_controller.pressed.connect((n_press, x, y) => {
            on_selection_pressed(selection_click_controller, n_press, x, y);
        });
        selection_click_controller.released.connect((n_press, x, y) => {
            on_selection_released(x, y);
        });

        EventControllerKey key_controller = new EventControllerKey();
        key_controller.propagation_phase = Gtk.PropagationPhase.CAPTURE;
        add_controller(key_controller);
        key_controller.key_pressed.connect(on_key_pressed);

        return this;
    }

    public void activate_last_message_correction() {
        Gee.BidirIterator<Plugins.MetaConversationItem> iter = content_items.bidir_iterator();
        iter.last();
        for (int i = 0; i < 10 && content_items.size > i; i++) {
            Plugins.MetaConversationItem item = iter.get();
            MessageMetaItem message_item = item as MessageMetaItem;
            if (message_item != null) {
                if ((conversation.type_ == Conversation.Type.CHAT && message_item.jid.equals_bare(conversation.account.bare_jid)) ||
                        (conversation.type_ == Conversation.Type.GROUPCHAT &&
                        message_item.jid.equals(stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account)))) {
                    message_item.in_edit_mode = true;
                    break;
                }
            }
            iter.previous();
        }
    }

    private bool is_highlight_fixed() {
        foreach (Widget widget in action_buttons.values) {
            MenuButton? menu_button = widget as MenuButton;
            if (menu_button != null && menu_button.popover != null && menu_button.popover.visible) return true;

            ToggleButton? toggle_button = widget as ToggleButton;
            if (toggle_button != null && toggle_button.active) return true;
        }
        return false;
    }

    private void on_leave_notify_event() {
        if (is_highlight_fixed()) return;

        if (currently_highlighted != null) {
            currently_highlighted.remove_css_class("highlight");
            currently_highlighted = null;
        }
        message_menu_box.visible = false;
    }

    private void update_highlight(double x, double y) {
        if (is_highlight_fixed()) return;

        if (currently_highlighted != null && (last_y - y).abs() <= 2) {
            return;
        }

        last_y = y;

        // Get widget under pointer
        int h = 0;
        Widget? w = null;
        foreach (Plugins.MetaConversationItem item in meta_items) {
            Widget widget = widgets[item];
            h += widget.get_allocated_height() + widget.margin_top + widget.margin_bottom;
            if (h >= y) {
                w = widget;
                break;
            }
        };

        if (currently_highlighted != null) currently_highlighted.remove_css_class("highlight");

        currently_highlighted = null;
        current_meta_item = null;

        if (w == null) {
            update_message_menu();
            return;
        }

        // Get widget coordinates in main
        double widget_x, widget_y;
        w.translate_coordinates(main, 0, 0, out widget_x, out widget_y);

        // Get MessageItem
        foreach (Plugins.MetaConversationItem item in item_item_skeletons.keys) {
            if (item_item_skeletons[item].get_widget() == w) {
                current_meta_item = item as ContentMetaItem;
            }
        }

        update_message_menu();

        if (current_meta_item != null) {
            // Highlight widget
            currently_highlighted = w;
            currently_highlighted.add_css_class("highlight");

            // Move message menu
            message_menu_box.margin_top = (int)(widget_y + MESSAGE_MENU_BOX_OFFSET);
        }
    }

    private void update_message_menu() {
        if (current_meta_item == null) {
            message_menu_box.visible = false;
            return;
        }

        message_actions = current_meta_item.get_item_actions(Plugins.WidgetType.GTK4);
        bool has_selection_action = is_selectable_content_item(current_meta_item);

        if (message_actions != null || has_selection_action) {
            message_menu_box.visible = true;

            Menu menu_model = new Menu();
            ((MenuButton)action_buttons["menu"]).menu_model = menu_model;

            foreach (Widget widget in action_buttons.values) {
                widget.visible = false;
            }

            // Configure as many buttons as we need with the actions for the current meta item
            if (message_actions != null) {
                foreach (var message_action in message_actions) {
                    if (message_action.shortcut_action) {
                        Widget button_widget = action_buttons[message_action.name];
                        button_widget.visible = true;

                        if (message_action.name == "reaction") {
                            MenuButton button = (MenuButton) button_widget;
                            button.sensitive = message_action.sensitive;
                            button.icon_name = message_action.icon_name;
                            button.tooltip_text = Util.string_if_tooltips_active(message_action.tooltip);
                        } else if (message_action.callback != null) {
                            Button button = (Button) button_widget;
                            button.sensitive = message_action.sensitive;
                            button.icon_name = message_action.icon_name;
                            button.tooltip_text = Util.string_if_tooltips_active(message_action.tooltip);
                        }
                    } else {
                        MenuItem item = new MenuItem(message_action.tooltip, null);
                        item.set_action_and_target_value("action.action", new GLib.Variant.string(message_action.name));
                        menu_model.append_item(item);
                        action_buttons["menu"].visible = true;
                    }
                }
            }

            if (has_selection_action) {
                string selection_label = selected_content_items.contains(current_meta_item) ? _("Unselect message") : _("Select message");
                MenuItem item = new MenuItem(selection_label, null);
                item.set_action_and_target_value("action.action", new GLib.Variant.string("toggle-selection"));
                menu_model.append_item(item);
                action_buttons["menu"].visible = true;
            }
        } else {
            message_menu_box.visible = false;
        }
    }

    public void initialize_for_conversation(Conversation? conversation) {
        // Workaround for rendering issues
        if (firstLoad) {
            main.visible = false;
            Idle.add(() => {
                main.visible=true;
                return false;
            });
            firstLoad = false;
        }
        if (conversation == this.conversation && at_current_content) {
            // Just make sure we are scrolled down
            if (scrolled.vadjustment.value != scrolled.vadjustment.upper) {
                scroll_animation(scrolled.vadjustment.upper).play();
            }
            return;
        }
        clear();
        initialize_for_conversation_(conversation);
        display_latest();
        at_current_content = true;
        // Scroll to end
        scrolled.vadjustment.value = scrolled.vadjustment.upper;
    }

    private void scroll_and_highlight_item(Plugins.MetaConversationItem target, uint duration = 500) {
        Widget widget = null;
        int h = 0;
        foreach (Plugins.MetaConversationItem item in meta_items) {
            widget = widgets[item];
            if (target == item) {
                break;
            }
            h += widget.get_allocated_height();
        }
        if (widget != widgets[target]) {
            warning("Target item widget not reached");
            return;
        }
        double target_height = h - scrolled.vadjustment.page_size * 1/3;
        Adw.Animation animation = scroll_animation(target_height);
        animation.done.connect(() => {
            widget.remove_css_class("highlight-once");
            widget.add_css_class("highlight-once");
            Timeout.add(5000, () => {
                widget.remove_css_class("highlight-once");
                return false;
            });
        });
        animation.play();
    }

    private Adw.Animation scroll_animation(double target) {
        return new Adw.TimedAnimation(scrolled, scrolled.vadjustment.value, target, 500,
                new Adw.PropertyAnimationTarget(scrolled.vadjustment, "value")
        );
    }

    public void initialize_around_message(Conversation conversation, ContentItem content_item) {
        if (conversation == this.conversation) {
            ContentMetaItem? matching_item = content_items.first_match(it => it.content_item.id == content_item.id);
            if (matching_item != null) {
                scroll_and_highlight_item(matching_item);
                return;
            }
        }
        clear();
        initialize_for_conversation_(conversation);
        Gee.List<ContentMetaItem> before_items = content_populator.populate_before(conversation, content_item, 40);
        foreach (ContentMetaItem item in before_items) {
            do_insert_item(item);
        }
        ContentMetaItem meta_item = content_populator.get_content_meta_item(content_item);
        insert_new(meta_item);
        content_items.add(meta_item);
        meta_items.add(meta_item);

        Gee.List<ContentMetaItem> after_items = content_populator.populate_after(conversation, content_item, 40);
        foreach (ContentMetaItem item in after_items) {
            do_insert_item(item);
        }
        if (after_items.size == 40) {
            at_current_content = false;
        }

        // Compute where to jump to for centered message, jump, highlight.
        reload_messages = false;
        Timeout.add(700, () => {
            scroll_and_highlight_item(meta_item, 300);
            reload_messages = true;
            return false;
        });
    }

    private void initialize_for_conversation_(Conversation? conversation) {
        if (this.conversation == conversation) {
            debug("Re-initialized for %s", conversation.counterpart.bare_jid.to_string());
        }
        // Deinitialize old conversation
        Dino.Application app = Dino.Application.get_default();
        if (this.conversation != null) {
            foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_addition_populators) {
                populator.close(conversation);
            }
            foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
                populator.close(conversation);
            }
        }

        // Clear data structures
        clear_notifications();
        this.conversation = conversation;

        // Init for new conversation
        foreach (Plugins.ConversationItemPopulator populator in app.plugin_registry.conversation_addition_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK4);
        }
        content_populator.init(this, conversation, Plugins.WidgetType.GTK4);
        subscription_notification.init(conversation, this);
    }

    private void display_latest() {
        Gee.List<ContentMetaItem> items = content_populator.populate_latest(conversation, 40);
        foreach (ContentMetaItem item in items) {
            do_insert_item(item);
        }

        Application app = GLib.Application.get_default() as Application;
        foreach (Plugins.NotificationPopulator populator in app.plugin_registry.notification_populators) {
            populator.init(conversation, this, Plugins.WidgetType.GTK4);
        }
        Idle.add(() => { on_value_notify(); return false; });
    }

    public void insert_item(Plugins.MetaConversationItem item) {
        if (meta_items.size > 0) {
            bool after_last = meta_items.last().time.compare(item.time) <= 0;
            bool within_range = meta_items.last().time.compare(item.time) > 0 && meta_items.first().time.compare(item.time) < 0;
            bool accept = within_range || (at_current_content && after_last);
            if (!accept) {
                return;
            }
        }

        do_insert_item(item);
    }

    public void do_insert_item(Plugins.MetaConversationItem item) {
        lock (meta_items) {
            insert_new(item);
            if (item is ContentMetaItem) {
                content_items.add((ContentMetaItem)item);
            }
            meta_items.add(item);
        }

        inserted_item(item);
    }

    private void remove_item(Plugins.MetaConversationItem item) {
        ConversationItemSkeleton? skeleton = item_item_skeletons[item];
        if (skeleton != null) {
            main.remove(skeleton.get_widget());
            widgets.unset(item);
            widget_order.remove(skeleton.get_widget());
            item_item_skeletons.unset(item);

            if (item is ContentMetaItem) {
                if (selection_anchor_item == item) selection_anchor_item = null;
                if (selection_drag_anchor_item == item) selection_drag_anchor_item = null;
                selected_content_items.remove((ContentMetaItem)item);
                content_items.remove((ContentMetaItem)item);
                update_primary_selection();
            }
            meta_items.remove(item);
            skeleton.dispose();
        }

        removed_item(item);
    }

    public void on_add_meta_notification(Plugins.MetaConversationNotification notification) {
        Widget? widget = (Widget) notification.get_widget(Plugins.WidgetType.GTK4);
        if (widget != null) {
            add_notification(widget);
        }
    }

    public void on_remove_meta_notification(Plugins.MetaConversationNotification notification){
        Widget? widget = (Widget) notification.get_widget(Plugins.WidgetType.GTK4);
        if (widget != null) {
            remove_notification(widget);
        }
    }

    public void add_notification(Widget widget) {
        notifications.append(widget);
        Timeout.add(20, () => {
            notification_revealer.transition_duration = 200;
            notification_revealer.reveal_child = true;
            return false;
        });
    }

    public void remove_notification(Widget widget) {
        notification_revealer.reveal_child = false;
        notifications.remove(widget);
    }

    private Widget insert_new(Plugins.MetaConversationItem item) {
        Plugins.MetaConversationItem? lower_item = meta_items.lower(item);

        // Fill datastructure
        ConversationItemSkeleton item_skeleton = new ConversationItemSkeleton(stream_interactor, conversation, item);
        item_item_skeletons[item] = item_skeleton;
        int index = lower_item != null ? widget_order.index_of(item_item_skeletons[lower_item].get_widget()) + 1 : 0;
        widget_order.insert(index, item_skeleton.get_widget());

        // Insert widget
        widgets[item] = item_skeleton.get_widget();
        widgets[item].insert_after(main, item_item_skeletons.has_key(lower_item) ? item_item_skeletons[lower_item].get_widget() : null);

        if (lower_item != null) {
            if (can_merge(item, lower_item)) {
                item_skeleton.show_skeleton = false;
            } else {
                item_skeleton.show_skeleton = true;
            }
        } else {
            item_skeleton.show_skeleton = true;
        }

        Plugins.MetaConversationItem? upper_item = meta_items.higher(item);
        if (upper_item != null) {
            if (!can_merge(upper_item, item)) {
                ConversationItemSkeleton upper_skeleton = item_item_skeletons[upper_item];
                upper_skeleton.show_skeleton = true;
            }
        }

        // If an item from the past was added, add everything between that item and the (post-)first present item
        if (index == 0) {
            Dino.Application app = Dino.Application.get_default();
            if (widget_order.size == 1) {
                foreach (Plugins.ConversationAdditionPopulator populator in app.plugin_registry.conversation_addition_populators) {
                    populator.populate_timespan(conversation, item.time, new DateTime.now_utc());
                }
            } else {
                foreach (Plugins.ConversationAdditionPopulator populator in app.plugin_registry.conversation_addition_populators) {
                    populator.populate_timespan(conversation, item.time, meta_items.higher(item).time);
                }
            }
        }
        return item_skeleton.get_widget();
    }

    private bool can_merge(Plugins.MetaConversationItem upper_item /*more recent, displayed below*/, Plugins.MetaConversationItem lower_item /*less recent, displayed above*/) {
        return upper_item.time != null && lower_item.time != null &&
            upper_item.time.difference(lower_item.time) < TimeSpan.MINUTE &&
            upper_item.jid != null && lower_item.jid != null &&
            upper_item.jid.equals(lower_item.jid) &&
            upper_item.encryption == lower_item.encryption &&
            (upper_item.mark == Message.Marked.WONTSEND) == (lower_item.mark == Message.Marked.WONTSEND);
    }

    private void on_action_button_clicked(Button button) {
        on_action_selected(button.name);
    }

    private void on_action_selected(string action_name) {
        if (currently_highlighted != null) {
            currently_highlighted.grab_focus();
        }
        switch (action_name) {
            case "reaction":
                critical("Action unsupported for direct activation: %s", action_name);
                break;
            case "delete":
                on_delete_action_selected();
                break;
            case "toggle-selection":
                toggle_current_selection();
                break;
            default:
                invoke_message_action(action_name);
                break;
        }
    }

    private void on_delete_action_selected() {
        if (currently_highlighted == null) {
            critical("No message selected");
            return;
        }
        Plugins.MessageAction? delete_action = null;
        foreach (var action in message_actions) {
            if (action.name == "delete") {
                delete_action = action;
            }
        }
        if (delete_action == null || delete_action.extras == null || !delete_action.extras.is_of_type(VariantType.BOOLEAN)) {
            critical(@"Delete action unavailable or can_delete_for_everyone not set");
            return;
        }
        bool can_delete_for_everyone = delete_action.extras.get_boolean();
        Adw.AlertDialog dialog = new Adw.AlertDialog(_("Delete message"), null) { content_width = 350, follows_content_size = false };
        if (can_delete_for_everyone) {
            CheckButton check_button = new CheckButton() { label="Delete for everyone", active=true };

            Box extra_child = new Box(Orientation.VERTICAL, 8);
            extra_child.append(new Label("Would you like to remove this message for everyone or just for yourself?") { xalign=0, use_markup=true, wrap=true });
            extra_child.append(new Label("The message will only be deleted for others <b>if their app supports it</b>!") { xalign=0, use_markup=true, wrap=true });
            extra_child.append(check_button);
            dialog.extra_child = extra_child;

            check_button.toggled.connect(() => {
                dialog.remove_response("delete");
                dialog.remove_response("cancel");
                if (check_button.active) {
                    dialog.add_response("delete", "Delete for everyone");
                } else {
                    dialog.add_response("delete", "Only delete for yourself");
                }
                dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.add_response("cancel", _("Cancel"));
            });
            dialog.response.connect((response) => {
                if (response == "delete") {
                    invoke_message_action("delete", new GLib.Variant.boolean(check_button.active));
                }
            });
            dialog.add_response("delete", "Delete for everyone");
            dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.add_response("cancel", _("Cancel"));
        } else {
            dialog.extra_child = new Label("This message <b>can't be deleted</b> for everyone. Would you like to remove it only for yourself?") { use_markup=true, wrap=true };
            dialog.add_response("delete", "Only delete for myself");
            dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.add_response("cancel", _("Cancel"));
            dialog.response.connect((response) => {
                if (response == "delete") {
                    invoke_message_action("delete", new GLib.Variant.boolean(false));
                }
            });
        }
        dialog.close_response = "cancel";
        dialog.present(currently_highlighted);
    }

    private void invoke_message_action(string action_name, GLib.Variant? variant = null) {
        if (message_actions == null) return;

        foreach (var action in message_actions) {
            if (action.name == action_name) {
                action.callback(variant);
                return;
            }
        }
        warning("Unknown action invoked: %s", action_name);
    }

    private void on_selection_pressed(GestureClick gesture, int n_press, double x, double y) {
        ContentMetaItem? item = get_selectable_content_item_at_y(y);
        if (item == null) return;

        ModifierType state = gesture.get_current_event_state();
        bool ctrl_pressed = (state & ModifierType.CONTROL_MASK) > 0;
        bool shift_pressed = (state & ModifierType.SHIFT_MASK) > 0;

        message_menu_box.visible = false;
        grab_focus();

        if (shift_pressed && selection_anchor_item != null) {
            if (ctrl_pressed) {
                set_range_selection(selection_anchor_item, item, !selected_content_items.contains(item));
            } else {
                select_range(selection_anchor_item, item);
            }
            selection_drag_anchor_item = null;
            selection_drag_active = false;
            gesture.set_state(Gtk.EventSequenceState.CLAIMED);
        } else if (ctrl_pressed) {
            selection_anchor_item = item;
            selection_drag_anchor_item = null;
            selection_drag_active = false;
            toggle_content_item_selection(item);
            gesture.set_state(Gtk.EventSequenceState.CLAIMED);
        } else {
            selection_anchor_item = item;
            selection_drag_anchor_item = item;
            selection_drag_active = false;
            selection_drag_start_x = x;
            selection_drag_start_y = y;
        }
    }

    private void update_selection_drag(double x, double y) {
        if (selection_drag_anchor_item == null) return;

        if (!selection_drag_active) {
            double dx = x - selection_drag_start_x;
            double dy = y - selection_drag_start_y;
            if (dx * dx + dy * dy < SELECTION_DRAG_THRESHOLD * SELECTION_DRAG_THRESHOLD) return;
            selection_drag_active = true;
        }

        ContentMetaItem? item = get_selectable_content_item_at_y(y);
        if (item == null) return;

        select_range(selection_drag_anchor_item, item);
    }

    private void on_selection_released(double x, double y) {
        if (selection_drag_anchor_item != null && selection_drag_active) {
            update_selection_drag(x, y);
        }
        selection_drag_anchor_item = null;
        selection_drag_active = false;
    }

    private bool on_key_pressed(EventControllerKey controller, uint keyval, uint keycode, ModifierType state) {
        if (selected_content_items.size == 0) return false;

        if (keyval == Gdk.Key.Escape) {
            clear_selected_content_items();
            return true;
        }

        bool ctrl_pressed = (state & ModifierType.CONTROL_MASK) > 0;
        bool other_modifier_pressed = (state & (ModifierType.ALT_MASK | ModifierType.META_MASK | ModifierType.SUPER_MASK)) > 0;
        if (ctrl_pressed && !other_modifier_pressed && (keyval == Gdk.Key.c || keyval == Gdk.Key.C)) {
            copy_selected_content_items();
            return true;
        }

        return false;
    }

    private bool is_selectable_content_item(ContentMetaItem? item) {
        return item != null && (item.content_item.type_ == MessageItem.TYPE || item.content_item.type_ == FileItem.TYPE);
    }

    private ContentMetaItem? get_selectable_content_item_at_y(double y) {
        int h = 0;
        ContentMetaItem? first_selectable_item = null;
        ContentMetaItem? last_selectable_item = null;

        foreach (Plugins.MetaConversationItem item in meta_items) {
            Widget widget = widgets[item];
            h += widget.get_allocated_height() + widget.margin_top + widget.margin_bottom;

            ContentMetaItem? content_meta_item = item as ContentMetaItem;
            if (is_selectable_content_item(content_meta_item)) {
                if (first_selectable_item == null) first_selectable_item = content_meta_item;
                last_selectable_item = content_meta_item;
                if (h >= y) return content_meta_item;
            }
        };

        if (y < 0) return first_selectable_item;
        return last_selectable_item;
    }

    private void select_range(ContentMetaItem start_item, ContentMetaItem end_item) {
        selected_content_items.clear();
        set_range_selection(start_item, end_item, true);
    }

    private void set_range_selection(ContentMetaItem start_item, ContentMetaItem end_item, bool selected, bool update = true) {

        bool in_range = false;
        foreach (Plugins.MetaConversationItem item in meta_items) {
            ContentMetaItem? content_meta_item = item as ContentMetaItem;
            if (!is_selectable_content_item(content_meta_item)) continue;

            if (content_meta_item == start_item || content_meta_item == end_item) {
                if (selected) {
                    selected_content_items.add(content_meta_item);
                } else {
                    selected_content_items.remove(content_meta_item);
                }
                if (start_item == end_item) break;
                if (in_range) break;
                in_range = true;
                continue;
            }

            if (in_range) {
                if (selected) {
                    selected_content_items.add(content_meta_item);
                } else {
                    selected_content_items.remove(content_meta_item);
                }
            }
        }

        if (update) update_selected_content_items();
    }

    private void toggle_content_item_selection(ContentMetaItem item) {
        if (selected_content_items.contains(item)) {
            selected_content_items.remove(item);
        } else {
            selected_content_items.add(item);
        }

        update_selected_content_items();
    }

    private void toggle_current_selection() {
        if (!is_selectable_content_item(current_meta_item)) return;

        selection_anchor_item = current_meta_item;
        toggle_content_item_selection(current_meta_item);

        update_message_menu();
    }

    private void update_selected_content_items() {
        foreach (ContentMetaItem item in content_items) {
            Widget? widget = widgets[item];
            if (widget == null) continue;

            if (selected_content_items.contains(item)) {
                widget.add_css_class("message-selected");
            } else {
                widget.remove_css_class("message-selected");
            }
        }

        update_primary_selection();
    }

    private void clear_selected_content_items() {
        selection_anchor_item = null;
        selection_drag_anchor_item = null;
        selection_drag_active = false;
        selected_content_items.clear();
        update_selected_content_items();
    }

    private void copy_selected_content_items() {
        string text = get_selected_content_items_text();
        if (text != "") get_clipboard().set_text(text);
    }

    private void update_primary_selection() {
        string text = get_selected_content_items_text();
        if (text == "" && selected_content_items.size == 0) return;

        get_display().get_primary_clipboard().set_text(text);
    }

    private string get_selected_content_items_text() {
        StringBuilder builder = new StringBuilder();
        bool first = true;

        foreach (ContentMetaItem item in selected_content_items) {
            string? text = get_content_item_text(item.content_item);
            if (text == null || text == "") continue;

            if (!first) builder.append("\n\n");
            builder.append(text);
            first = false;
        }

        return builder.str;
    }

    private string? get_content_item_text(ContentItem content_item) {
        string sender = Util.get_participant_display_name(stream_interactor, conversation, content_item.jid, true);
        string time = content_item.time.to_local().format("%Y-%m-%d %H:%M");
        string? text = null;

        if (content_item.type_ == MessageItem.TYPE) {
            Message message = ((MessageItem)content_item).message;
            FileTransfer? file_transfer = stream_interactor.get_module(FileTransferStorage.IDENTITY).get_file_by_message_id(message.id, ((MessageItem)content_item).conversation);
            if (file_transfer != null) {
                text = get_file_transfer_text(file_transfer, ((MessageItem)content_item).conversation);
            } else {
                text = Dino.message_body_without_reply_fallback(message);
            }
        } else if (content_item.type_ == FileItem.TYPE) {
            FileItem file_item = (FileItem)content_item;
            text = get_file_transfer_text(file_item.file_transfer, file_item.conversation);
        }

        if (text == null) return null;

        return @"$sender - $time\n$text";
    }

    private string get_file_transfer_text(FileTransfer file_transfer, Conversation file_conversation) {
        string text = _("File") + ": " + file_transfer.file_name;
        string? url = get_file_transfer_url(file_transfer, file_conversation);
        if (url != null && url != "") {
            text += "\n" + url;
        }
        return text;
    }

    private string? get_file_transfer_url(FileTransfer file_transfer, Conversation file_conversation) {
        foreach (Xep.StatelessFileSharing.Source source in file_transfer.sfs_sources) {
            Xep.StatelessFileSharing.HttpSource? http_source = source as Xep.StatelessFileSharing.HttpSource;
            if (http_source != null) return http_source.url;
        }

        if (file_transfer.provider == FileManager.HTTP_PROVIDER_ID && file_transfer.info != null) {
            Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_id(int.parse(file_transfer.info), file_conversation);
            if (message != null) return message.body;
        }

        return null;
    }

    private void on_upper_notify() {
        if (was_upper == null || scrolled.vadjustment.value >  was_upper - was_page_size - 1) { // scrolled down or content smaller than page size
            if (at_current_content) {
                Idle.add(() => {
                    // If we do this directly without Idle.add, scrolling down doesn't work properly
                    scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size; // scroll down
                    return false;
                });
            }
        } else if (scrolled.vadjustment.value < scrolled.vadjustment.upper - scrolled.vadjustment.page_size - 1) {
            scrolled.vadjustment.value = scrolled.vadjustment.upper - was_upper + scrolled.vadjustment.value; // stay at same content
        }
        was_upper = scrolled.vadjustment.upper;
        was_page_size = scrolled.vadjustment.page_size;
        was_value = scrolled.vadjustment.value;
        reloading_mutex.trylock();
        reloading_mutex.unlock();
    }

    private void on_value_notify() {
        if (scrolled.vadjustment.value < 400) {
            load_earlier_messages();
        } else if (scrolled.vadjustment.upper - (scrolled.vadjustment.value + scrolled.vadjustment.page_size) < 400) {
            load_later_messages();
        }
    }

    private void load_earlier_messages() {
        was_value = scrolled.vadjustment.value;
        if (!reloading_mutex.trylock()) return;
        if (content_items.size > 0) {
            Gee.List<ContentMetaItem> items = content_populator.populate_before(conversation, ((ContentMetaItem) content_items.first()).content_item, 20);
            foreach (ContentMetaItem item in items) {
                do_insert_item(item);
            }
        } else {
            reloading_mutex.unlock();
        }
    }

    private void load_later_messages() {
        if (!reloading_mutex.trylock()) return;
        if (content_items.size > 0 && !at_current_content) {
            Gee.List<ContentMetaItem> items = content_populator.populate_after(conversation, ((ContentMetaItem) content_items.last()).content_item, 20);
            if (items.size == 0) {
                at_current_content = true;
            }
            foreach (ContentMetaItem item in items) {
                do_insert_item(item);
            }
        } else {
            reloading_mutex.unlock();
        }
    }

    private static int compare_content_meta_items(ContentMetaItem a, ContentMetaItem b) {
        return compare_meta_items(a, b);
    }

    private static int compare_meta_items(Plugins.MetaConversationItem a, Plugins.MetaConversationItem b) {
        int cmp1 = a.time.compare(b.time);
        if (cmp1 != 0) return cmp1;

        return a.secondary_sort_indicator - b.secondary_sort_indicator;
    }

    private void clear() {
        was_upper = null;
        was_page_size = null;
        clear_selected_content_items();
        foreach (var item in content_items) {
            item.dispose();
        }
        content_items.clear();
        meta_items.clear();
        widget_order.clear();
        foreach (var skeleton in item_item_skeletons.values) {
            skeleton.dispose();
        }
        item_item_skeletons.clear();
        foreach (Widget widget in widgets.values) {
            widget.unparent();
            widget.dispose();
        }
        widgets.clear();

        Widget? notification = notifications.get_first_child();
        while (notification != null) {
            notifications.remove(notification);
            notification = notifications.get_first_child();
        }
    }

    private void clear_notifications() {
//        notifications.@foreach((widget) => { notifications.remove(widget); });
        notification_revealer.transition_duration = 0;
        notification_revealer.set_reveal_child(false);
    }
}

}
