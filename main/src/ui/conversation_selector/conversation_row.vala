using Gee;
using Gdk;
using Gtk;
using Pango;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSelector {

[GtkTemplate (ui = "/im/dino/Dino/conversation_selector/conversation_row.ui")]
public abstract class ConversationRow : ListBoxRow {

    public signal void closed();

    [GtkChild] protected Image image;
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

    protected Message? last_message;
    protected bool read = true;


    protected StreamInteractor stream_interactor;

    construct {
        name_label.attributes = new AttrList();
    }

    public ConversationRow(StreamInteractor stream_interactor, Conversation conversation) {
        this.conversation = conversation;
        this.stream_interactor = stream_interactor;

        x_button.clicked.connect(close_conversation);
        conversation.notify["read-up-to"].connect(update_read);
        stream_interactor.connection_manager.connection_state_changed.connect(update_avatar);

        update_name_label();
        update_avatar();
        message_received();

    }

    public void update() {
        update_time_label();
    }

    public void message_received(Entities.Message? m = null) {
        last_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation) ?? m;
        update_message_label();
        update_time_label();
        update_read();
    }

    public virtual void on_show_received(Show presence) {
        update_avatar();
    }

    public void update_avatar() {
        bool self_online = stream_interactor.connection_manager.get_state(conversation.account) == ConnectionManager.ConnectionState.CONNECTED;
        bool counterpart_online = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(conversation.counterpart, conversation.account) != null;
        bool greyscale = !self_online || !counterpart_online;

        Pixbuf pixbuf = ((new AvatarGenerator(AVATAR_SIZE, AVATAR_SIZE, image.scale_factor))
                .set_greyscale(greyscale)
                .draw_conversation(stream_interactor, conversation));
        Util.image_set_from_scaled_pixbuf(image, pixbuf, image.get_scale_factor());
    }

    protected void update_name_label(string? new_name = null) {
        name_label.label = Util.get_conversation_display_name(stream_interactor, conversation);
    }

    protected void update_time_label(DateTime? new_time = null) {
        if (last_message != null) {
            time_label.visible = true;
            time_label.label = get_relative_time(last_message.time.to_local());
        }
    }

    protected virtual void update_message_label() {
        if (last_message != null) {
            message_label.visible = true;
            message_label.label = last_message.body.replace("\n", " ");
        }
    }

    protected void update_read() {
        bool read_was = read;
        read = last_message == null || (conversation.read_up_to != null && last_message.equals(conversation.read_up_to));
        if (read == read_was) return;
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

    protected Box get_fulljid_box(Jid full_jid) {
        Box box = new Box(Orientation.HORIZONTAL, 5) { visible=true };

        Show show = stream_interactor.get_module(PresenceManager.IDENTITY).get_last_show(full_jid, conversation.account);
        Image image = new Image() { visible=true };
        if (show.as == Show.AWAY) {
            image.set_from_icon_name("dino-status-away", IconSize.SMALL_TOOLBAR);
        } else if (show.as == Show.XA || show.as == Show.DND) {
            image.set_from_icon_name("dino-status-dnd", IconSize.SMALL_TOOLBAR);
        } else if (show.as == Show.CHAT) {
            image.set_from_icon_name("dino-status-chat", IconSize.SMALL_TOOLBAR);
        } else {
            image.set_from_icon_name("dino-status-online", IconSize.SMALL_TOOLBAR);
        }
        box.add(image);

        Label resource = new Label(full_jid.resourcepart) { visible=true };
        resource.xalign = 0;
        box.add(resource);
        box.show_all();
        return box;
    }

    private void close_conversation() {
        main_revealer.set_transition_type(RevealerTransitionType.SLIDE_UP);
        main_revealer.set_reveal_child(false);
        closed();
        main_revealer.notify["child-revealed"].connect(() => {
            stream_interactor.get_module(ConversationManager.IDENTITY).close_conversation(conversation);
        });
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

    private static string get_relative_time(DateTime datetime) {
         DateTime now = new DateTime.now_utc();
         TimeSpan timespan = now.difference(datetime);
         if (timespan > 365 * TimeSpan.DAY) {
             return datetime.get_year().to_string();
         } else if (timespan > 7 * TimeSpan.DAY) {
             // Day and month
             // xgettext:no-c-format
             return datetime.format(_("%b %d"));
         } else if (timespan > 2 * TimeSpan.DAY) {
             return datetime.format("%a");
         } else if (timespan > 1 * TimeSpan.DAY) {
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
