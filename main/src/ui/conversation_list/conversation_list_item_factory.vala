using Gtk;
using Dino.Entities;
using Dino;
using Gee;
using Pango;
using Xmpp;

namespace Dino.Ui.ConversationList {

    public static ListItemFactory get_item_factory() {
        SignalListItemFactory item_factory = new SignalListItemFactory();
        item_factory.setup.connect((list_item) => { on_setup(list_item); });
        item_factory.bind.connect((list_item) => { on_bind(list_item); });
        return item_factory;
    }

    public static void on_setup(ListItem listitem) {
        listitem.child = new ConversationListRow();
    }

    public static void on_bind(ListItem listitem) {
        ConversationViewModel list_model = (ConversationViewModel) listitem.get_item();
        ConversationListRow view = (ConversationListRow) listitem.get_child();
        StreamInteractor stream_interactor = list_model.stream_interactor;

        list_model.bind_property("name", view.name_label, "label");
        list_model.notify["latest-content-item"].connect((obj, _) => {
            update_content_item(view, list_model.conversation, stream_interactor, ((ConversationViewModel) obj).latest_content_item);
        });
        list_model.notify["unread-count"].connect((obj, _) => {
            update_read(view, list_model.conversation, stream_interactor, (int) obj);
        });

        view.x_button.clicked.connect(() => list_model.closed() );

        ConversationViewModel view_model = (ConversationViewModel) listitem.get_item();
        view.name_label.label = view_model.name;
        if (view_model.latest_content_item != null) {
            update_content_item(view, view_model.conversation, stream_interactor, view_model.latest_content_item);
        }
        update_read(view, view_model.conversation, stream_interactor, view_model.unread_count);
    }

    private static void update_content_item(ConversationListRow view, Conversation conversation, StreamInteractor stream_interactor, ContentItem last_content_item) {
        view.time_label.label = get_relative_time(last_content_item.time.to_local());
        view.image.set_conversation(stream_interactor, conversation);

        Label nick_label = view.nick_label;
        Label message_label = view.message_label;

        switch (last_content_item.type_) {
            case MessageItem.TYPE:
                MessageItem message_item = last_content_item as MessageItem;
                Message last_message = message_item.message;

                string body = last_message.body;
                bool me_command = body.has_prefix("/me ");

                /* If we have a /me command, we always show the display
                 * name, and we don't set me_is_me on
                 * get_participant_display_name, since that will return
                 * "Me" (internationalized), whereas /me commands expect to
                 * be in the third person. We also omit the colon in this
                 * case, and strip off the /me prefix itself. */

                if (conversation.type_ == Conversation.Type.GROUPCHAT || me_command) {
                    nick_label.label = Util.get_participant_display_name(stream_interactor, conversation, last_message.from, !me_command);
                } else if (last_message.direction == Message.DIRECTION_SENT) {
                    nick_label.label = _("Me");
                } else {
                    nick_label.label = "";
                }

                if (me_command) {
                    /* Don't slice off the space after /me */
                    body = body.slice("/me".length, body.length);
                } else if (nick_label.label.length > 0) {
                    /* TODO: Is this valid for RTL languages? */
                    nick_label.label += ": ";
                }

                message_label.attributes.filter((attr) => attr.equal(attr_style_new(Pango.Style.ITALIC)));
                message_label.label = Util.summarize_whitespaces_to_space(body);

                break;
            case FileItem.TYPE:
                FileItem file_item = last_content_item as FileItem;
                FileTransfer transfer = file_item.file_transfer;

                if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    // TODO properly display nick for oneself
                    nick_label.label = Util.get_participant_display_name(stream_interactor, conversation, file_item.file_transfer.from, true) + ": ";
                } else {
                    nick_label.label = transfer.direction == Message.DIRECTION_SENT ? _("Me") + ": " : "";
                }

                bool file_is_image = transfer.mime_type != null && transfer.mime_type.has_prefix("image");
                message_label.attributes.insert(attr_style_new(Pango.Style.ITALIC));
                if (transfer.direction == Message.DIRECTION_SENT) {
                    message_label.label = (file_is_image ? _("Image sent") : _("File sent") );
                } else {
                    message_label.label = (file_is_image ? _("Image received") : _("File received") );
                }
                break;
            case CallItem.TYPE:
                CallItem call_item = (CallItem) last_content_item;
                Call call = call_item.call;

                nick_label.label = call.direction == Call.DIRECTION_OUTGOING ? _("Me") + ": " : "";
                message_label.attributes.insert(attr_style_new(Pango.Style.ITALIC));
                message_label.label = call.direction == Call.DIRECTION_OUTGOING ? _("Outgoing call") : _("Incoming call");
                break;
        }
        nick_label.visible = true;
        message_label.visible = true;
    }

    private void update_read(ConversationListRow view, Conversation conversation, StreamInteractor stream_interactor, int num_unread) {
        Label unread_count_label = view.unread_count_label;
        Label name_label = view.name_label;
        Label time_label = view.time_label;
        Label nick_label = view.nick_label;
        Label message_label = view.message_label;
        if (num_unread == 0) {
            unread_count_label.visible = false;

            name_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            time_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            nick_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            message_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
        } else {
            unread_count_label.label = num_unread.to_string();
            unread_count_label.visible = true;

            if (conversation.get_notification_setting(stream_interactor) == Conversation.NotifySetting.ON) {
                unread_count_label.get_style_context().add_class("unread-count-notify");
                unread_count_label.get_style_context().remove_class("unread-count");
            } else {
                unread_count_label.get_style_context().add_class("unread-count");
                unread_count_label.get_style_context().remove_class("unread-count-notify");
            }

            name_label.attributes.insert(attr_weight_new(Weight.BOLD));
            time_label.attributes.insert(attr_weight_new(Weight.BOLD));
            nick_label.attributes.insert(attr_weight_new(Weight.BOLD));
            message_label.attributes.insert(attr_weight_new(Weight.BOLD));
        }

        name_label.label = name_label.label; // TODO initializes redrawing, which would otherwise not happen. nicer?
        time_label.label = time_label.label;
        nick_label.label = nick_label.label;
        message_label.label = message_label.label;
    }

    private Widget generate_tooltip(StreamInteractor stream_interactor, Conversation conversation) {
        Grid grid = new Grid() { row_spacing=5, column_homogeneous=false, column_spacing=5, margin_start=7, margin_end=7, margin_top=7, margin_bottom=7 };

        Label label = new Label(conversation.counterpart.to_string()) { valign=Align.START, xalign=0, visible=true };
        label.attributes = new AttrList();
        label.attributes.insert(attr_weight_new(Weight.BOLD));

        grid.attach(label, 0, 0, 2, 1);

        Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(conversation.counterpart, conversation.account);
        if (full_jids == null) return grid;

        for (int i = 0; i < full_jids.size; i++) {
            Jid full_jid = full_jids[i];
            string? show = stream_interactor.get_module(PresenceManager.IDENTITY).get_last_show(full_jid, conversation.account);
            if (show == null) continue;

            int i_cache = i;
            stream_interactor.get_module(EntityInfo.IDENTITY).get_identity.begin(conversation.account, full_jid, (_, res) => {
                Xep.ServiceDiscovery.Identity? identity = stream_interactor.get_module(EntityInfo.IDENTITY).get_identity.end(res);

                Image image = new Image() { hexpand=false, valign=Align.CENTER, visible=true };
                if (identity != null && (identity.type_ == Xep.ServiceDiscovery.Identity.TYPE_PHONE || identity.type_ == Xep.ServiceDiscovery.Identity.TYPE_TABLET)) {
                    image.set_from_icon_name("dino-device-phone-symbolic");
                } else {
                    image.set_from_icon_name("dino-device-desktop-symbolic");
                }

                if (show == Presence.Stanza.SHOW_AWAY) {
                    Util.force_color(image, "#FF9800");
                } else if (show == Presence.Stanza.SHOW_XA || show == Presence.Stanza.SHOW_DND) {
                    Util.force_color(image, "#FF5722");
                } else {
                    Util.force_color(image, "#4CAF50");
                }

                string? status = null;
                if (show == Presence.Stanza.SHOW_AWAY) {
                    status = "away";
                } else if (show == Presence.Stanza.SHOW_XA) {
                    status = "not available";
                } else if (show == Presence.Stanza.SHOW_DND) {
                    status = "do not disturb";
                }

                var sb = new StringBuilder();
                if (identity != null && identity.name != null) {
                    sb.append(identity.name);
                } else if (full_jid.resourcepart != null) {
                    sb.append(full_jid.resourcepart);
                } else {
                    return;
                }
                if (status != null) {
                    sb.append(" <i>(").append(status).append(")</i>");
                }

                Label resource = new Label(sb.str) { use_markup=true, hexpand=true, xalign=0, visible=true };

                grid.attach(image, 0, i_cache + 1, 1, 1);
                grid.attach(resource, 1, i_cache + 1, 1, 1);
            });
        }
        return grid;
    }

    private static string get_relative_time(DateTime datetime) {
        DateTime now = new DateTime.now_local();
        TimeSpan timespan = now.difference(datetime);
        if (timespan > 365 * TimeSpan.DAY) {
            return datetime.get_year().to_string();
        } else if (timespan > 7 * TimeSpan.DAY) {
            // Day and month
            // xgettext:no-c-format
            return datetime.format(_("%b %d"));
        } else if (timespan > 2 * TimeSpan.DAY) {
            return datetime.format("%a");
        } else if (datetime.get_day_of_month() != now.get_day_of_month()) {
            return _("Yesterday");
        } else if (timespan > 9 * TimeSpan.MINUTE) {
            return datetime.format(Util.is_24h_format() ?
                    /* xgettext:no-c-format */ /* Time in 24h format (w/o seconds) */ _("%H∶%M") :
                    /* xgettext:no-c-format */ /* Time in 12h format (w/o seconds) */ _("%l∶%M %p"));
        } else if (timespan > 1 * TimeSpan.MINUTE) {
            ulong mins = (ulong) (timespan.abs() / TimeSpan.MINUTE);
            return n("%i min ago", "%i mins ago", mins).printf(mins);
        } else {
            return _("Just now");
        }
    }
}