using Gee;
using Gdk;
using Gtk;
using Pango;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

[GtkTemplate (ui = "/im/dino/conversation_selector/conversation_row.ui")]
public abstract class ConversationRow : ListBoxRow {

    public signal void closed();

    [GtkChild] protected Image image;
    [GtkChild] private Label name_label;
    [GtkChild] private Label time_label;
    [GtkChild] private Label message_label;
    [GtkChild] protected Button x_button;
    [GtkChild] private Revealer time_revealer;
    [GtkChild] private Revealer xbutton_revealer;
    [GtkChild] public Revealer main_revealer;

    public Conversation conversation { get; private set; }

    protected const int AVATAR_SIZE = 40;

    protected string display_name;
    protected string message;
    protected DateTime time;
    protected bool read = true;


    protected StreamInteractor stream_interactor;

    construct {
        name_label.attributes = new AttrList();
    }

    public ConversationRow(StreamInteractor stream_interactor, Conversation conversation) {
        this.conversation = conversation;
        this.stream_interactor = stream_interactor;

        x_button.clicked.connect(on_x_button_clicked);

        update_name(Util.get_conversation_display_name(stream_interactor, conversation));
        message_received();
    }

    public void update() {
        update_time();
    }

    public void message_received(Entities.Message? m = null) {
        Entities.Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_last_message(conversation);
        if (message != null) {
            update_message(message.body.replace("\n", " "));
            update_time(message.time.to_utc());
        }
    }

    public void set_avatar(Pixbuf pixbuf, int scale_factor = 1) {
        Util.image_set_from_scaled_pixbuf(image, pixbuf, scale_factor);
        image.queue_draw();
    }

    public void mark_read() {
        update_read(true);
    }

    public void mark_unread() {
        update_read(false);
    }

    public abstract void on_show_received(Show presence);
    public abstract void network_connection(bool connected);

    protected void update_name(string? new_name = null) {
        if (new_name != null) {
            display_name = new_name;
        }
        name_label.label = display_name;
    }

    protected void update_time(DateTime? new_time = null) {
        time_label.visible = true;
        if (new_time != null) {
            time = new_time;
        }
        if (time != null) {
            time_label.label = get_relative_time(time);
        }
    }

    protected void update_message(string? new_message = null) {
        if (new_message != null) {
            message = new_message;
        }
        if (message != null) {
            message_label.visible = true;
            message_label.label = message;
        }
    }

    protected void update_read(bool read) {
        this.read = read;
        if (read) {
            name_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            time_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
            message_label.attributes.filter((attr) => attr.equal(attr_weight_new(Weight.BOLD)));
        } else {
            name_label.attributes.insert(attr_weight_new(Weight.BOLD));
            time_label.attributes.insert(attr_weight_new(Weight.BOLD));
            message_label.attributes.insert(attr_weight_new(Weight.BOLD));
        }
        name_label.label = name_label.label; // TODO initializes redrawing, which would otherwise not happen. nicer?
        time_label.label = time_label.label;
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

    private void on_x_button_clicked() {
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
                /* xgettext:no-c-format */ /* Time in 24h format (w/o seconds) */ _("%H\u2236%M") :
                /* xgettext:no-c-format */ /* Time in 12h format (w/o seconds) */ _("%l\u2236%M %p"));
         } else if (timespan > 1 * TimeSpan.MINUTE) {
             ulong mins = (ulong) (timespan.abs() / TimeSpan.MINUTE);
             return n("%i min ago", "%i mins ago", mins).printf(mins);
         } else {
             return _("Just now");
         }
    }
}

}
