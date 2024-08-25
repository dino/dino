using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

namespace Dino.Ui.ConversationDetails {

    [GtkTemplate (ui = "/im/dino/Dino/conversation_details.ui")]
    public class Dialog : Adw.Window {
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
            model.encryption_rows.items_changed.connect(create_preferences_rows);
            model.settings_rows.items_changed.connect(create_preferences_rows);
            model.notify["room-configuration-rows"].connect(create_preferences_rows);

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

        private void create_preferences_rows() {
            var widget = about_box.get_first_child();
            while (widget != null) {
                about_box.remove(widget);
                widget = about_box.get_first_child();
            }

            if (model.about_rows.get_n_items() > 0) {
                about_box.append(rows_to_preference_group(model.about_rows, _("About")));
            }
            if (model.encryption_rows.get_n_items() > 0) {
                about_box.append(rows_to_preference_group(model.encryption_rows, _("Encryption")));
            }
            if (model.settings_rows.get_n_items() > 0) {
                about_box.append(rows_to_preference_group(model.settings_rows, _("Settings")));
            }
            if (model.room_configuration_rows != null && model.room_configuration_rows.get_n_items() > 0) {
                about_box.append(rows_to_preference_group(model.room_configuration_rows, _("Room Configuration")));
            }
        }

        private Adw.PreferencesGroup rows_to_preference_group(GLib.ListStore row_view_models, string title) {
            var preference_group = new Adw.PreferencesGroup() { title=title };

            for (int preference_group_i = 0; preference_group_i < row_view_models.get_n_items(); preference_group_i++) {
                var preferences_row = (ViewModel.PreferencesRow.Any) row_view_models.get_item(preference_group_i);

                Widget? w = null;

                var entry_view_model = preferences_row as ViewModel.PreferencesRow.Entry;
                if (entry_view_model != null) {
#if Adw_1_2
                    Adw.EntryRow view = new Adw.EntryRow() { title = entry_view_model.title, show_apply_button=true };
                    entry_view_model.bind_property("text", view, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, (_, from, ref to) => {
                        var str = (string) from;
                        to = str ?? "";
                        return true;
                    });
                    view.apply.connect(() => {
                        entry_view_model.changed();
                    });
#else
                    var view = new Adw.ActionRow() { title = entry_view_model.title };
                    var entry = new Entry() { text=entry_view_model.text, valign=Align.CENTER };
                    entry_view_model.bind_property("text", entry, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
                    entry.changed.connect(() => {
                        entry_view_model.changed();
                    });
                    view.activatable_widget = entry;
                    view.add_suffix(entry);
#endif
                    w = view;
                }

                var row_text = preferences_row as ViewModel.PreferencesRow.Text;
                if (row_text != null) {
                    w = new Adw.ActionRow() {
                        title = row_text.title,
                        subtitle = row_text.text,
#if Adw_1_3
                            subtitle_selectable = true
#endif
                };
                    w.add_css_class("property");

                    Util.force_css(w, "row.property > box.header > box.title > .title { font-weight: 400; font-size: 9pt; opacity: 0.55; }");
                    Util.force_css(w, "row.property > box.header > box.title > .subtitle { font-size: inherit; opacity: 1; }");
                }

                var toggle_view_model = preferences_row as ViewModel.PreferencesRow.Toggle;
                if (toggle_view_model != null) {
                    var view = new Adw.ActionRow() { title = toggle_view_model.title, subtitle = toggle_view_model.subtitle };
                    var toggle = new Switch() { valign = Align.CENTER };
                    view.activatable_widget = toggle;
                    view.add_suffix(toggle);
                    toggle_view_model.bind_property("state", toggle, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
                    w = view;
                }

                var combobox_view_model = preferences_row as ViewModel.PreferencesRow.ComboBox;
                if (combobox_view_model != null) {
                    var string_list = new StringList(null);
                    foreach (string text in combobox_view_model.items) {
                        string_list.append(text);
                    }
#if Adw_1_4
                    var view = new Adw.ComboRow() { title = combobox_view_model.title };
                    view.model = string_list;
                    combobox_view_model.bind_property("active-item", view, "selected", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
#else
                    var view = new Adw.ActionRow() { title = combobox_view_model.title };
                    var drop_down = new DropDown(string_list, null) { valign = Align.CENTER };
                    combobox_view_model.bind_property("active-item", drop_down, "selected", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
                    view.activatable_widget = drop_down;
                    view.add_suffix(drop_down);
#endif
                    w = view;
                }

                var widget_view_model = preferences_row as ViewModel.PreferencesRow.WidgetDeprecated;
                if (widget_view_model != null) {
                    var view = new Adw.ActionRow() { title = widget_view_model.title };
                    view.add_suffix(widget_view_model.widget);
                    w = view;
                }

                if (w == null) {
                    continue;
                }

                preference_group.add(w);
            }

            return preference_group;
        }
    }
}
