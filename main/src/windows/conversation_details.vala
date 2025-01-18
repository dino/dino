using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

namespace Dino.Ui.ConversationDetails {

    [GtkTemplate (ui = "/im/dino/Dino/conversation_details.ui")]
    public class Dialog : Adw.Window {
        [GtkChild] public unowned Stack stack;
        [GtkChild] public unowned Box about_box;
        [GtkChild] public unowned Button pin_button;
        [GtkChild] public unowned Adw.ButtonContent pin_button_content;
        [GtkChild] public unowned MenuButton block_button;
        [GtkChild] public unowned Adw.ButtonContent block_button_content;
        [GtkChild] public unowned Button notification_button_toggle;
        [GtkChild] public unowned Adw.ButtonContent notification_button_toggle_content;
        [GtkChild] public unowned MenuButton notification_button_menu;
        [GtkChild] public unowned Adw.ButtonContent notification_button_menu_content;
        [GtkChild] public unowned Adw.SplitButton notification_button_split;
        [GtkChild] public unowned Adw.ButtonContent notification_button_split_content;

        [GtkChild] public unowned ViewModel.ConversationDetails model { get; }

        public StackPage? encryption_stack_page = null;
        public Box? encryption_box = null;

        public StackPage? member_stack_page = null;
        public Box? member_box = null;

        private SimpleAction block_action = new SimpleAction.stateful("block", VariantType.INT32, new Variant.int32(ViewModel.ConversationDetails.BlockState.UNBLOCK));

        class construct {
            install_action("notification.on", null, (widget, action_name) => { ((Dialog) widget).model.notification_changed(ViewModel.ConversationDetails.NotificationSetting.ON); } );
            install_action("notification.off", null, (widget, action_name) => { ((Dialog) widget).model.notification_changed(ViewModel.ConversationDetails.NotificationSetting.OFF); } );
            install_action("notification.highlight", null, (widget, action_name) => { ((Dialog) widget).model.notification_changed(ViewModel.ConversationDetails.NotificationSetting.HIGHLIGHT); } );
            install_action("notification.default", null, (widget, action_name) => { ((Dialog) widget).model.notification_changed(ViewModel.ConversationDetails.NotificationSetting.DEFAULT); } );
        }

        construct {
            pin_button.clicked.connect(() => { model.pin_changed(); });
            notification_button_toggle.clicked.connect(() => { model.notification_flipped(); });
            notification_button_split.clicked.connect(() => { model.notification_flipped(); });

            model.notify["pinned"].connect(update_pinned_button);
            model.notify["blocked"].connect(update_blocked_button);
            model.notify["notification"].connect(update_notification_button);
            model.notify["notification"].connect(update_notification_button_state);
            model.notify["notification-options"].connect(update_notification_button_visibility);
            model.notify["notification-is-default"].connect(update_notification_button_visibility);

            model.about_rows.items_changed.connect(create_preferences_rows);
            model.settings_rows.items_changed.connect(create_preferences_rows);
            model.notify["room-configuration-rows"].connect(create_preferences_rows);

            model.notify["members"].connect(create_members);
            create_members();

            // Create block action
            SimpleActionGroup block_action_group = new SimpleActionGroup();
            block_action = new SimpleAction.stateful("block", VariantType.INT32, new Variant.int32(0));
            block_action.activate.connect((parameter) => {
                block_action.set_state(parameter);
                model.block_changed((ViewModel.ConversationDetails.BlockState) parameter.get_int32());
            });
            block_action_group.insert(block_action);
            this.insert_action_group("block", block_action_group);

            // Create block menu model
            Menu block_menu_model = new Menu();
            string[] menu_labels = new string[] { _("Block user"), _("Block entire domain"), _("Unblock") };
            ViewModel.ConversationDetails.BlockState[] menu_states = new ViewModel.ConversationDetails.BlockState[] { ViewModel.ConversationDetails.BlockState.USER, ViewModel.ConversationDetails.BlockState.DOMAIN, ViewModel.ConversationDetails.BlockState.UNBLOCK };
            for (int i = 0; i < menu_labels.length; i++) {
                MenuItem item = new MenuItem(menu_labels[i], null);
                item.set_action_and_target_value("block.block", new Variant.int32(menu_states[i]));
                block_menu_model.append_item(item);
            }
            block_button.menu_model = block_menu_model;

#if Adw_1_4
            // TODO: replace with putting buttons in new line on small screens
            notification_button_menu_content.can_shrink = true;
#endif
            update_blocked_button();
        }

        private void update_pinned_button() {
            pin_button_content.icon_name = "view-pin-symbolic";
            pin_button_content.label = model.pinned ? _("Pinned") : _("Pin");
            if (model.pinned) {
                pin_button.add_css_class("accent");
            } else {
                pin_button.remove_css_class("accent");
            }
        }

        private void update_blocked_button() {
            switch (model.blocked) {
                case USER:
                    block_button_content.label = _("Blocked");
                    block_button.add_css_class("error");
                    break;
                case DOMAIN:
                    block_button_content.label = _("Domain blocked");
                    block_button.add_css_class("error");
                    break;
                case UNBLOCK:
                    block_button_content.label = _("Block");
                    block_button.remove_css_class("error");
                    break;
            }

            block_action.set_state(new Variant.int32(model.blocked));
        }

        private void update_notification_button() {
            string icon_name = model.notification == OFF ?
                    "dino-bell-large-none-symbolic" : "dino-bell-large-symbolic";
            notification_button_toggle_content.icon_name = icon_name;
            notification_button_split_content.icon_name = icon_name;
            notification_button_menu_content.icon_name = icon_name;
        }

        private void update_notification_button_state() {
            switch (model.notification) {
                case ON:
                    notification_button_toggle_content.label = _("Mute");
                    notification_button_split_content.label = _("Mute");
                    notification_button_menu_content.label = _("Notifications enabled");
                    break;
                case HIGHLIGHT:
                    notification_button_menu_content.label = _("Notifications for mentions");
                    break;
                case OFF:
                    notification_button_toggle_content.label = _("Muted");
                    notification_button_split_content.label = _("Muted");
                    notification_button_menu_content.label = _("Notifications disabled");
                    break;
            }
        }

        private void update_notification_button_visibility() {
            notification_button_toggle.visible = notification_button_menu.visible = notification_button_split.visible = false;

            if (model.notification_options == ON_OFF) {
                if (model.notification_is_default) {
                    notification_button_toggle.visible = true;
                } else {
                    notification_button_split.visible = true;
                }
            } else {
                notification_button_menu.visible = true;
            }
        }

        private void create_members() {
#if GTK_4_8
            if (model.members_sorted.n_items == 0) return;
#else
            if (model.members_sorted.model.get_n_items() == 0) return;
#endif

            var selection_model = new NoSelection(model.members_sorted);
            var item_factory = new BuilderListItemFactory.from_resource(null, "/im/dino/Dino/muc_member_list_row.ui");
            var list_view = new ListView(selection_model, item_factory) { single_click_activate = true };
            list_view.add_css_class("card");
            list_view.activate.connect((position) => {
//                var widget = (Gtk.Widget) list_view.observe_children().get_item(position);
//                var name_label = widget.get_template_child(Type.OBJECT, "name-label");
//                print(widget.get_type().name());

//                var popover = new Popover();
//                popover.parent = widget;
//                popover.popup();


                var row_view_model = (Ui.Model.ConferenceMember) model.members_sorted.get_item(position);
                print(@"$(position) $(row_view_model.name)\n");
            });

            add_members_tab_element(list_view);
        }

        private void create_preferences_rows() {
            var widget = about_box.get_first_child();
            while (widget != null) {
                about_box.remove(widget);
                widget = about_box.get_first_child();
            }

            if (model.about_rows.get_n_items() > 0) {
                about_box.append(Util.rows_to_preference_group(model.about_rows, _("About")));
            }
            if (model.settings_rows.get_n_items() > 0) {
                about_box.append(Util.rows_to_preference_group(model.settings_rows, _("Settings")));
            }
            if (model.room_configuration_rows != null && model.room_configuration_rows.get_n_items() > 0) {
                about_box.append(Util.rows_to_preference_group(model.room_configuration_rows, _("Room Configuration")));
            }
        }

        public void add_encryption_tab_element(Adw.PreferencesGroup preferences_group) {
            if (encryption_stack_page == null) {
                encryption_box = new Box(Orientation.VERTICAL, 12) { margin_end = 12, margin_start = 12, margin_top = 18, margin_bottom = 40 };
                var scrolled_window = new ScrolledWindow() { vexpand = true };
                var clamp = new Adw.Clamp();
                clamp.set_child(encryption_box);
                scrolled_window.set_child(clamp);
                encryption_stack_page = stack.add_child(scrolled_window);
                encryption_stack_page.title = _("Encryption");
                encryption_stack_page.name = "encryption";
            }
            encryption_box.append(preferences_group);
        }

        public void add_members_tab_element(Widget widget) {
            if (member_stack_page == null) {
                member_box = new Box(Orientation.VERTICAL, 12) { margin_end = 12, margin_start = 12, margin_top = 18 };
                member_stack_page = stack.add_child(member_box);
                member_stack_page.title = _("Members");
                member_stack_page.name = "member";
            }
            member_box.append(widget);
        }
    }

    [GtkTemplate (ui = "/im/dino/Dino/muc_member_list_row.ui")]
    public class Dino.Ui.ConversationDetails.MemberListItem : Gtk.Widget {

    }
}
