using Dino;
using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

namespace Dino.Ui.ConversationDetails {

    public void populate_dialog(Model.ConversationDetails model, Conversation conversation, StreamInteractor stream_interactor) {
        model.conversation = conversation;
        model.display_name = stream_interactor.get_module(ContactModels.IDENTITY).get_display_name_model(conversation);
        model.blocked = stream_interactor.get_module(BlockingManager.IDENTITY).is_blocked(model.conversation.account, model.conversation.counterpart);
        model.domain_blocked = stream_interactor.get_module(BlockingManager.IDENTITY).is_blocked(model.conversation.account, model.conversation.counterpart.domain_jid);

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            stream_interactor.get_module(MucManager.IDENTITY).get_config_form.begin(conversation.account, conversation.counterpart, (_, res) => {
                model.data_form = stream_interactor.get_module(MucManager.IDENTITY).get_config_form.end(res);
                if (model.data_form == null) return;
                model.data_form_bak = model.data_form.stanza_node.to_string();
            });
        }
    }

    public void bind_dialog(Model.ConversationDetails model, ViewModel.ConversationDetails view_model, StreamInteractor stream_interactor) {
        // Set some data once
        view_model.avatar = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(model.conversation);
        view_model.show_blocked = model.conversation.type_ == Conversation.Type.CHAT && stream_interactor.get_module(BlockingManager.IDENTITY).is_supported(model.conversation.account);
        view_model.members_sorted.set_model(model.members);
        view_model.members.set_map_func((item) => {
            var conference_member = (Ui.Model.ConferenceMember) item;
            Jid? nick_jid = stream_interactor.get_module(MucManager.IDENTITY).get_occupant_jid(model.conversation.account, model.conversation.counterpart, conference_member.jid);
            return new Ui.ViewModel.ConferenceMemberListRow() {
                avatar = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(model.conversation, conference_member.jid),
                name = nick_jid != null ? nick_jid.resourcepart : conference_member.jid.localpart,
                jid = conference_member.jid.to_string(),
                affiliation = conference_member.affiliation
            };
        });
        view_model.account_jid = stream_interactor.get_accounts().size > 1 ? model.conversation.account.bare_jid.to_string() : null;

        if (model.domain_blocked) {
            view_model.blocked = DOMAIN;
        } else if (model.blocked) {
            view_model.blocked = USER;
        } else {
            view_model.blocked = UNBLOCK;
        }

        // Bind properties
        model.display_name.bind_property("display-name", view_model, "name", BindingFlags.SYNC_CREATE);
        model.conversation.bind_property("notify-setting", view_model, "notification", BindingFlags.SYNC_CREATE, (_, from, ref to) => {
            switch (model.conversation.get_notification_setting(stream_interactor)) {
                case ON:
                    to = ViewModel.ConversationDetails.NotificationSetting.ON;
                    break;
                case OFF:
                    to = ViewModel.ConversationDetails.NotificationSetting.OFF;
                    break;
                case HIGHLIGHT:
                    to = ViewModel.ConversationDetails.NotificationSetting.HIGHLIGHT;
                    break;
                case DEFAULT:
                    // A "default" setting should have been resolved to the actual default value
                    assert_not_reached();
            }
            return true;
        });
        model.conversation.bind_property("notify-setting", view_model, "notification-is-default", BindingFlags.SYNC_CREATE, (_, from, ref to) => {
            var notify_setting = (Conversation.NotifySetting) from;
            to = notify_setting == Conversation.NotifySetting.DEFAULT;
            return true;
        });
        model.conversation.bind_property("pinned", view_model, "pinned", BindingFlags.SYNC_CREATE, (_, from, ref to) => {
            var from_int = (int) from;
            to = from_int > 0;
            return true;
        });
        model.conversation.bind_property("type-", view_model, "notification-options", BindingFlags.SYNC_CREATE, (_, from, ref to) => {
            var ty = (Conversation.Type) from;
            to = ty == Conversation.Type.GROUPCHAT ? ViewModel.ConversationDetails.NotificationOptions.ON_HIGHLIGHT_OFF : ViewModel.ConversationDetails.NotificationOptions.ON_OFF;
            return true;
        });
        model.bind_property("data-form", view_model, "room-configuration-rows", BindingFlags.SYNC_CREATE, (_, from, ref to) => {
            var data_form = (DataForms.DataForm) from;
            if (data_form == null) return true;
            var list_store = new GLib.ListStore(typeof(ViewModel.PreferencesRow.Any));

            foreach (var field in data_form.fields) {
                var field_view_model = Util.get_data_form_field_view_model(field);
                if (field_view_model != null) {
                    list_store.append(field_view_model);
                }
            }

            to = list_store;
            return true;
        });

        view_model.pin_changed.connect(() => {
            model.conversation.pinned = model.conversation.pinned == 1 ? 0 : 1;
        });
        view_model.block_changed.connect((action) => {
            switch (action) {
                case USER:
                    stream_interactor.get_module(BlockingManager.IDENTITY).block(model.conversation.account, model.conversation.counterpart);
                    stream_interactor.get_module(BlockingManager.IDENTITY).unblock(model.conversation.account, model.conversation.counterpart.domain_jid);
                    break;
                case DOMAIN:
                    stream_interactor.get_module(BlockingManager.IDENTITY).block(model.conversation.account, model.conversation.counterpart.domain_jid);
                    break;
                case UNBLOCK:
                    stream_interactor.get_module(BlockingManager.IDENTITY).unblock(model.conversation.account, model.conversation.counterpart);
                    stream_interactor.get_module(BlockingManager.IDENTITY).unblock(model.conversation.account, model.conversation.counterpart.domain_jid);
                    break;
            }
            view_model.blocked = action;
        });
        view_model.notification_changed.connect((setting) => {
            switch (setting) {
                case ON:
                    model.conversation.notify_setting = ON;
                    break;
                case OFF:
                    model.conversation.notify_setting = OFF;
                    break;
                case HIGHLIGHT:
                    model.conversation.notify_setting = HIGHLIGHT;
                    break;
                case DEFAULT:
                    model.conversation.notify_setting = DEFAULT;
                    break;
            }
        });

        view_model.notification_flipped.connect(() => {
            model.conversation.notify_setting = view_model.notification == ON ? Conversation.NotifySetting.OFF : Conversation.NotifySetting.ON;
        });
    }

    public void set_about_rows(Model.ConversationDetails model, ViewModel.ConversationDetails view_model, StreamInteractor stream_interactor) {
        view_model.about_rows.append(new ViewModel.PreferencesRow.Text() {
            title = _("XMPP Address"),
            text = model.conversation.counterpart.to_string()
        });
        if (model.conversation.type_ == Conversation.Type.CHAT) {
            var about_row = new ViewModel.PreferencesRow.Entry() {
                title = _("Display name"),
                text = model.display_name.display_name
            };
            about_row.changed.connect(() => {
                if (about_row.text != model.display_name.display_name) {
                    stream_interactor.get_module(RosterManager.IDENTITY).set_jid_handle(model.conversation.account, model.conversation.counterpart, about_row.text);
                }
            });
            view_model.about_rows.append(about_row);
        }
        if (model.conversation.type_ == Conversation.Type.GROUPCHAT) {
            var topic = stream_interactor.get_module(MucManager.IDENTITY).get_groupchat_subject(model.conversation.counterpart, model.conversation.account);

            Ui.ViewModel.PreferencesRow.Any preferences_row = null;
            Jid? own_muc_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(model.conversation.counterpart, model.conversation.account);
            if (own_muc_jid != null) {
                Xep.Muc.Role? own_role = stream_interactor.get_module(MucManager.IDENTITY).get_role(own_muc_jid, model.conversation.account);
                if (own_role != null) {
                    if (own_role == MODERATOR) {
                        var preferences_row_entry = new ViewModel.PreferencesRow.Entry() {
                            title = _("Topic"),
                            text = topic
                        };
                        preferences_row_entry.changed.connect(() => {
                            if (preferences_row_entry.text != topic) {
                                stream_interactor.get_module(MucManager.IDENTITY).change_subject(model.conversation.account, model.conversation.counterpart, preferences_row_entry.text);
                            }
                        });
                        preferences_row = preferences_row_entry;
                    }
                }
            }
            if (preferences_row == null && topic != null && topic != "") {
                preferences_row = new ViewModel.PreferencesRow.Text() {
                    title = _("Topic"),
                    text = Util.parse_add_markup(topic, null, true, true)
                };
            }
            if (preferences_row != null) {
                view_model.about_rows.append(preferences_row);
            }
        }
    }

    public Dialog setup_dialog(Conversation conversation, StreamInteractor stream_interactor, Window parent) {
        var dialog = new Dialog() { transient_for = parent };
        var model = new Model.ConversationDetails();
        model.populate(stream_interactor, conversation);
        bind_dialog(model, dialog.model, stream_interactor);

        set_about_rows(model, dialog.model, stream_interactor);

        dialog.close_request.connect(() => {
            // Only send the config form if something was changed
            if (model.data_form_bak != null && model.data_form_bak != model.data_form.stanza_node.to_string()) {
                stream_interactor.get_module(MucManager.IDENTITY).set_config_form.begin(conversation.account, conversation.counterpart, model.data_form);
            }
            return false;
        });

        Plugins.ContactDetails contact_details = new Plugins.ContactDetails();
        contact_details.add_settings_action_row.connect((entry_row_model) => {
            dialog.model.settings_rows.append((Ui.ViewModel.PreferencesRow.Any) entry_row_model);
        });
        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_contact_details_entry(new ContactDetails.SettingsProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new ContactDetails.PermissionsProvider(stream_interactor));

        foreach (Plugins.ContactDetailsProvider provider in app.plugin_registry.contact_details_entries) {
            var preferences_group = (Adw.PreferencesGroup) provider.get_widget(conversation);
            if (preferences_group != null) {
                dialog.add_encryption_tab_element((Adw.PreferencesGroup) provider.get_widget(conversation));
            }
            provider.populate(conversation, contact_details, Plugins.WidgetType.GTK4);
        }

        return dialog;
    }
}
