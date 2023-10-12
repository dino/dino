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

    [GtkChild] protected unowned AvatarPicture picture;
    [GtkChild] protected unowned Label name_label;
    [GtkChild] protected unowned Label time_label;
    [GtkChild] protected unowned Label nick_label;
    [GtkChild] protected unowned Label message_label;
    [GtkChild] protected unowned Label unread_count_label;
    [GtkChild] protected unowned Button x_button;
    [GtkChild] protected unowned Revealer time_revealer;
    [GtkChild] protected unowned Revealer xbutton_revealer;
    [GtkChild] protected unowned Revealer top_row_revealer;
    [GtkChild] protected unowned Image pinned_image;
    [GtkChild] public unowned Revealer main_revealer;

    public Conversation conversation { get; private set; }

    protected const int AVATAR_SIZE = 40;

    protected ContentItem? last_content_item;
    protected int num_unread = 0;


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
                        update_read(true); // bubble color might have changed
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
                has_tooltip = Util.use_tooltips();
                query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
                    tooltip.set_custom(Util.widget_if_tooltips_active(generate_tooltip()));
                    return true;
                });
                break;
            case Conversation.Type.GROUPCHAT:
                has_tooltip = Util.use_tooltips();
                set_tooltip_text(Util.string_if_tooltips_active(conversation.counterpart.bare_jid.to_string()));
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
        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(conversation);
        conversation.notify["read-up-to-item"].connect(() => update_read());
        conversation.notify["pinned"].connect(() => { update_pinned_icon(); });

        update_name_label();
        update_pinned_icon();
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
        if (conversation.counterpart.bare_jid.to_string() == conversation.account.bare_jid.to_string()){ //talking to yourself
            name_label.label = "Notes to self (" + conversation.account.bare_jid.to_string() + ")";
            change_label_attribute(name_label, attr_weight_new(Weight.BOLD));
        }
        else {
            name_label.label = Util.get_conversation_display_name(stream_interactor, conversation);
        }
    }

    private void update_pinned_icon() {
        pinned_image.visible = conversation.pinned != 0;
    }

    protected void update_time_label(DateTime? new_time = null) {
        if (last_content_item != null) {
            time_label.visible = true;
            time_label.label = get_relative_time(last_content_item.time.to_local());
        }
    }

    protected void update_message_label() {
        if (last_content_item != null) {
            switch (last_content_item.type_) {
                case MessageItem.TYPE:
                    MessageItem message_item = last_content_item as MessageItem;
                    Message last_message = message_item.message;

                    string body = Dino.message_body_without_reply_fallback(last_message);
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

                    change_label_attribute(message_label, attr_style_new(Pango.Style.NORMAL));
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
                    change_label_attribute(message_label, attr_style_new(Pango.Style.ITALIC));
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
                    change_label_attribute(message_label, attr_style_new(Pango.Style.ITALIC));
                    message_label.label = call.direction == Call.DIRECTION_OUTGOING ? _("Outgoing call") : _("Incoming call");
                    break;
            }
            nick_label.visible = true;
            message_label.visible = true;
        }
    }

    private static void change_label_attribute(Label label, owned Attribute attribute) {
        AttrList copy = label.attributes.copy();
        copy.change((owned) attribute);
        label.attributes = copy;
    }

    private bool update_read_pending = false;
    private bool update_read_pending_force = false;
    protected void update_read(bool force_update = false) {
        if (force_update) update_read_pending_force = true;
        if (update_read_pending) return;
        update_read_pending = true;
        Idle.add(() => {
            update_read_pending = false;
            update_read_pending_force = false;
            update_read_idle(update_read_pending_force);
            return Source.REMOVE;
        }, Priority.LOW);
    }

    private void update_read_idle(bool force_update = false) {
        int current_num_unread = stream_interactor.get_module(ChatInteraction.IDENTITY).get_num_unread(conversation);
        if (num_unread == current_num_unread && !force_update) return;
        num_unread = current_num_unread;

        if (num_unread == 0) {
            unread_count_label.visible = false;

            change_label_attribute(name_label, attr_weight_new(Weight.NORMAL));
            change_label_attribute(time_label, attr_weight_new(Weight.NORMAL));
            change_label_attribute(nick_label, attr_weight_new(Weight.NORMAL));
            change_label_attribute(message_label, attr_weight_new(Weight.NORMAL));
        } else {
            unread_count_label.label = num_unread.to_string();
            unread_count_label.visible = true;

            if (conversation.get_notification_setting(stream_interactor) == Conversation.NotifySetting.ON) {
                unread_count_label.add_css_class("unread-count-notify");
                unread_count_label.remove_css_class("unread-count");
            } else {
                unread_count_label.add_css_class("unread-count");
                unread_count_label.remove_css_class("unread-count-notify");
            }

            change_label_attribute(name_label, attr_weight_new(Weight.BOLD));
            change_label_attribute(time_label, attr_weight_new(Weight.BOLD));
            change_label_attribute(nick_label, attr_weight_new(Weight.BOLD));
            change_label_attribute(message_label, attr_weight_new(Weight.BOLD));
        }
    }

    public override void state_flags_changed(StateFlags flags) {
        StateFlags curr_flags = get_state_flags();
        if ((curr_flags & StateFlags.PRELIGHT) != 0) {
            time_revealer.set_reveal_child(false);
            top_row_revealer.set_reveal_child(false);
            xbutton_revealer.set_reveal_child(true);
        } else {
            time_revealer.set_reveal_child(true);
            top_row_revealer.set_reveal_child(true);
            xbutton_revealer.set_reveal_child(false);
        }
    }

    private static Regex dino_resource_regex = /^dino\.[a-f0-9]{8}$/;

    private Widget generate_tooltip() {
        Grid grid = new Grid() { row_spacing=5, column_homogeneous=false, column_spacing=5, margin_start=7, margin_end=7, margin_top=7, margin_bottom=7 };

        Label label = new Label(conversation.counterpart.to_string()) { valign=Align.START, xalign=0 };
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

                Image image = new Image() { hexpand=false, valign=Align.CENTER };
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
                } else if (full_jid.resourcepart != null && dino_resource_regex.match(full_jid.resourcepart)) {
                    sb.append("Dino");
                } else if (full_jid.resourcepart != null) {
                    sb.append(full_jid.resourcepart);
                } else {
                    return;
                }
                if (status != null) {
                    sb.append(" <i>(").append(status).append(")</i>");
                }

                Label resource = new Label(sb.str) { use_markup=true, hexpand=true, xalign=0 };

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

}
