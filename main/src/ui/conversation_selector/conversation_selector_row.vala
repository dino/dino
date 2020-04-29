using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino;
using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_row.ui")]
public class ConversationSelectorRow : ListBoxRow {

    [GtkChild] protected AvatarImage image;
    [GtkChild] protected Label name_label;
    [GtkChild] protected Label time_label;
    [GtkChild] protected Label nick_label;
    [GtkChild] protected Label message_label;
    [GtkChild] protected Button x_button;
    [GtkChild] protected Revealer time_revealer;
    [GtkChild] protected Revealer xbutton_revealer;
    [GtkChild] public Revealer main_revealer;

    public Conversation conversation { get; private set; }

    protected const int AVATAR_SIZE = 40;

    protected ContentItem? last_content_item;
    protected bool read = true;


    protected StreamInteractor stream_interactor;

    construct {
        name_label.attributes = new AttrList();
    }

    public ConversationSelectorRow(StreamInteractor stream_interactor, Conversation conversation) {
        this.conversation = conversation;
        this.stream_interactor = stream_interactor;

        switch (conversation.type_) {
            case Conversation.Type.CHAT:
                stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
                    if (conversation.account.equals(account) && conversation.counterpart.equals(jid)) {
                        update_name_label();
                    }
                });
                break;
            case Conversation.Type.GROUPCHAT:
                stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect((account, jid) => {
                    if (conversation != null && conversation.counterpart.equals_bare(jid) && conversation.account.equals(account)) {
                        update_name_label();
                    }
                });
                stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.connect((account, room, occupant) => {
                    if (conversation != null && conversation.counterpart.equals_bare(room.bare_jid) && conversation.account.equals(account)) {
                        update_name_label();
                    }
                });
                break;
            case Conversation.Type.GROUPCHAT_PM:
                break;
        }

        // Set tooltip
        switch (conversation.type_) {
            case Conversation.Type.CHAT:
                has_tooltip = true;
                query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
                    tooltip.set_custom(generate_tooltip());
                    return true;
                });
                break;
            case Conversation.Type.GROUPCHAT:
                has_tooltip = true;
                set_tooltip_text(conversation.counterpart.bare_jid.to_string());
                break;
            case Conversation.Type.GROUPCHAT_PM:
                break;
        }

        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect((item, c) => {
            if (conversation.equals(c)) {
                content_item_received(item);
            }
        });
        stream_interactor.get_module(MessageCorrection.IDENTITY).received_correction.connect((item) => {
            if (last_content_item != null && last_content_item.id == item.id) {
                content_item_received(item);
            }
        });

        last_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(conversation);

        x_button.clicked.connect(() => {
            stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
        });
        image.set_conversation(stream_interactor, conversation);
        conversation.notify["read-up-to-item"].connect(update_read);

        update_name_label();
        content_item_received();
    }

    public void update() {
        update_time_label();
    }

    public void content_item_received(ContentItem? ci = null) {
        last_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(conversation) ?? ci;
        update_message_label();
        update_time_label();
        update_read();
    }

    public async void colapse() {
        main_revealer.set_transition_type(RevealerTransitionType.SLIDE_UP);
        main_revealer.set_reveal_child(false);

        // Animations can be diabled (=> child_revealed immediately false). Wait for completion in case they're enabled.
        if (main_revealer.child_revealed) {
            main_revealer.notify["child-revealed"].connect(() => {
                Idle.add(colapse.callback);
            });
            yield;
        }
    }

    protected void update_name_label() {
        name_label.label = Util.get_conversation_display_name(stream_interactor, conversation);
    }

    protected void update_time_label(DateTime? new_time = null) {
        if (last_content_item != null) {
            time_label.visible = true;
            time_label.label = get_relative_time(last_content_item.display_time.to_local());
        }
    }

    protected void update_message_label() {
        if (last_content_item != null) {
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
            }
            nick_label.visible = true;
            message_label.visible = true;
        }
    }

    protected void update_read() {
        bool current_read_status = !stream_interactor.get_module(ChatInteraction.IDENTITY).has_unread(conversation);
        if (read == current_read_status) return;
        read = current_read_status;

        if (read) {
            name_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            time_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            nick_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            message_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
        } else {
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

    public override void state_flags_changed(StateFlags flags) {
        StateFlags curr_flags = get_state_flags();
        if ((curr_flags & StateFlags.PRELIGHT) != 0) {
            time_revealer.set_reveal_child(false);
            xbutton_revealer.set_reveal_child(true);
        } else {
            time_revealer.set_reveal_child(true);
            xbutton_revealer.set_reveal_child(false);
        }
    }

    private static Regex dino_resource_regex = /^dino\.[a-f0-9]{8}$/;

    private Widget generate_tooltip() {
        Grid grid = new Grid() { row_spacing=5, column_homogeneous=false, column_spacing=2, margin_start=5, margin_end=5, margin_top=2, margin_bottom=2, visible=true };

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
            Xep.ServiceDiscovery.Identity? identity = stream_interactor.get_module(EntityInfo.IDENTITY).get_identity(conversation.account, full_jid);

            Image image = new Image() { hexpand=false, valign=Align.START, visible=true };
            if (identity != null && (identity.type_ == Xep.ServiceDiscovery.Identity.TYPE_PHONE || identity.type_ == Xep.ServiceDiscovery.Identity.TYPE_TABLET)) {
                image.set_from_icon_name("dino-device-phone-symbolic", IconSize.SMALL_TOOLBAR);
            } else {
                image.set_from_icon_name("dino-device-desktop-symbolic", IconSize.SMALL_TOOLBAR);
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
            } else if (full_jid.resourcepart != null && dino_resource_regex.match(full_jid.resourcepart)) {
                sb.append("Dino");
            } else if (full_jid.resourcepart != null) {
                sb.append(full_jid.resourcepart);
            } else {
                continue;
            }
            if (status != null) {
                sb.append(" <i>(").append(status).append(")</i>");
            }

            Label resource = new Label(sb.str) { use_markup=true, hexpand=true, xalign=0, visible=true };

            grid.attach(image, 0, i + 1, 1, 1);
            grid.attach(resource, 1, i + 1, 1, 1);
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

}
