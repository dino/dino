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

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            stream_interactor.get_module(MucManager.IDENTITY).get_config_form.begin(conversation.account, conversation.counterpart, (_, res) => {
                model.data_form = stream_interactor.get_module(MucManager.IDENTITY).get_config_form.end(res);
                model.data_form_bak = model.data_form.stanza_node.to_string();
            });
        }
    }

    public void bind_dialog(Model.ConversationDetails model, ViewModel.ConversationDetails view_model, StreamInteractor stream_interactor) {
        view_model.avatar = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(model.conversation);
        view_model.show_blocked = model.conversation.type_ == Conversation.Type.CHAT && stream_interactor.get_module(BlockingManager.IDENTITY).is_supported(model.conversation.account);

        model.display_name.bind_property("display-name", view_model, "name", BindingFlags.SYNC_CREATE);
        model.conversation.bind_property("notify-setting", view_model, "notification", BindingFlags.SYNC_CREATE, (_, from, ref to) => {
            switch (model.conversation.get_notification_setting(stream_interactor)) {
                case Conversation.NotifySetting.ON:
                    to = ViewModel.ConversationDetails.NotificationSetting.ON;
                    break;
                case Conversation.NotifySetting.OFF:
                    to = ViewModel.ConversationDetails.NotificationSetting.OFF;
                    break;
                case Conversation.NotifySetting.HIGHLIGHT:
                    to = ViewModel.ConversationDetails.NotificationSetting.HIGHLIGHT;
                    break;
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
        model.bind_property("blocked", view_model, "blocked", BindingFlags.SYNC_CREATE);
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
        view_model.block_changed.connect(() => {
            if (view_model.blocked) {
                stream_interactor.get_module(BlockingManager.IDENTITY).unblock(model.conversation.account, model.conversation.counterpart);
            } else {
                stream_interactor.get_module(BlockingManager.IDENTITY).block(model.conversation.account, model.conversation.counterpart);
            }
            view_model.blocked = !view_model.blocked;
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

    public Window setup_dialog(Conversation conversation, StreamInteractor stream_interactor, Window parent) {
        var dialog = new Dialog() { transient_for = parent };
        var model = new Model.ConversationDetails();
        populate_dialog(model, conversation, stream_interactor);
        bind_dialog(model, dialog.model, stream_interactor);

        dialog.model.about_rows.append(new ViewModel.PreferencesRow.Text() {
            title = _("XMPP Address"),
            text = conversation.counterpart.to_string()
        });
        if (model.conversation.type_ == Conversation.Type.CHAT) {
            var about_row = new ViewModel.PreferencesRow.Entry() {
                title = _("Display name"),
                text = dialog.model.name
            };
            about_row.changed.connect(() => {
                if (about_row.text != Util.get_conversation_display_name(stream_interactor, conversation)) {
                    stream_interactor.get_module(RosterManager.IDENTITY).set_jid_handle(conversation.account, conversation.counterpart, about_row.text);
                }
            });
            dialog.model.about_rows.append(about_row);
        }
        if (model.conversation.type_ == Conversation.Type.GROUPCHAT) {
            var topic = stream_interactor.get_module(MucManager.IDENTITY).get_groupchat_subject(conversation.counterpart, conversation.account);
            if (topic != null && topic != "") {
                dialog.model.about_rows.append(new ViewModel.PreferencesRow.Text() {
                    title = _("Topic"),
                    text = Util.parse_add_markup(topic, null, true, true)
                });
            }
        }
        dialog.close_request.connect(() => {
            // Only send the config form if something was changed
            if (model.data_form_bak != null && model.data_form_bak != model.data_form.stanza_node.to_string()) {
                stream_interactor.get_module(MucManager.IDENTITY).set_config_form.begin(conversation.account, conversation.counterpart, model.data_form);
            }
            return false;
        });

        Plugins.ContactDetails contact_details = new Plugins.ContactDetails();
        contact_details.add.connect((c, l, d, wo) => {
            add_entry(c, l, d, wo, dialog);
        });
        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_contact_details_entry(new ContactDetails.SettingsProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new ContactDetails.PermissionsProvider(stream_interactor));

        foreach (Plugins.ContactDetailsProvider provider in app.plugin_registry.contact_details_entries) {
            provider.populate(conversation, contact_details, Plugins.WidgetType.GTK4);
        }

        return dialog;
    }

    private void add_entry(string category, string label, string? description, Object wo, Dialog dialog) {
        if (!(wo is Widget)) return;

        Widget widget = (Widget) wo;
        if (widget.get_type().is_a(typeof(Entry))) {
            Util.EntryLabelHybrid hybrid = new Util.EntryLabelHybrid.wrap(widget as Entry) { xalign=1 };
            widget = hybrid;
        } else if (widget.get_type().is_a(typeof(ComboBoxText))) {
            Util.ComboBoxTextLabelHybrid hybrid = new Util.ComboBoxTextLabelHybrid.wrap(widget as ComboBoxText) { xalign=1 };
            widget = hybrid;
        }

        var view_model = new ViewModel.PreferencesRow.WidgetDeprecated() {
            title = label,
            widget = widget
        };

        switch (category) {
            case "Encryption":
                dialog.model.encryption_rows.append(view_model);
                break;
            case "Permissions":
            case "Local Settings":
            case "Settings":
                dialog.model.settings_rows.append(view_model);
                break;
        }
    }
}