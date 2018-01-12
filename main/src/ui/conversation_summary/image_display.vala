using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

public class ImageDisplay : Plugins.MetaConversationItem {
    public override Jid? jid { get; set; }
    public override DateTime? sort_time { get; set; }
    public override DateTime? display_time { get; set; }
    public override Encryption? encryption { get; set; }
    public override Entities.Message.Marked? mark { get; set; }

    public override bool can_merge { get; set; default=true; }
    public override bool requires_avatar { get; set; default=true; }
    public override bool requires_header { get; set; default=true; }

    private const int MAX_HEIGHT = 300;
    private const int MAX_WIDTH = 600;

    private StreamInteractor stream_interactor;
    private FileTransfer file_transfer;

    public ImageDisplay(StreamInteractor stream_interactor, FileTransfer file_transfer) {
        this.stream_interactor = stream_interactor;
        this.file_transfer = file_transfer;

        this.jid = file_transfer.direction == FileTransfer.DIRECTION_SENT ? file_transfer.account.bare_jid.with_resource(file_transfer.account.resourcepart) : file_transfer.counterpart;
        this.sort_time = file_transfer.time;
        this.seccondary_sort_indicator = file_transfer.id + 0.2903;
        this.display_time = file_transfer.time;
        this.encryption = file_transfer.encryption;
        this.mark = file_to_message_state(file_transfer.state);
        file_transfer.notify["state"].connect_after(() => {
            this.mark = file_to_message_state(file_transfer.state);
        });
    }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        Image image = new Image() { halign=Align.START, visible = true };
        Gdk.Pixbuf pixbuf;
        try {
            pixbuf = new Gdk.Pixbuf.from_file(file_transfer.get_uri());
        } catch (Error error) {
            return null;
        }

        int max_scaled_height = MAX_HEIGHT * image.scale_factor;
        if (pixbuf.height > max_scaled_height) {
            pixbuf = pixbuf.scale_simple((int) ((double) max_scaled_height / pixbuf.height * pixbuf.width), max_scaled_height, Gdk.InterpType.BILINEAR);
        }
        int max_scaled_width = MAX_WIDTH * image.scale_factor;
        if (pixbuf.width > max_scaled_width) {
            pixbuf = pixbuf.scale_simple(max_scaled_width, (int) ((double) max_scaled_width / pixbuf.width * pixbuf.height), Gdk.InterpType.BILINEAR);
        }
        pixbuf = AvatarGenerator.crop_corners(pixbuf, 3 * image.get_scale_factor());
        Util.image_set_from_scaled_pixbuf(image, pixbuf);
        Util.force_css(image, "* { box-shadow: 0px 0px 2px 0px rgba(0,0,0,0.1); margin: 2px; border-radius: 3px; }");

        Builder builder = new Builder.from_resource("/im/dino/Dino/conversation_summary/image_toolbar.ui");
        Widget toolbar = builder.get_object("main") as Widget;
        Util.force_background(toolbar, "rgba(0, 0, 0, 0.5)");
        Util.force_css(toolbar, "* { padding: 3px; border-radius: 3px; }");

        Label url_label = builder.get_object("url_label") as Label;
        Util.force_color(url_label, "#eee");
        file_transfer.notify["info"].connect_after(() => { update_info(url_label, file_transfer.info); });
        update_info(url_label, file_transfer.info);

        Image copy_image = builder.get_object("copy_image") as Image;
        Util.force_css(copy_image, "*:not(:hover) { color: #eee; }");
        Button copy_button = builder.get_object("copy_button") as Button;
        Util.force_css(copy_button, "*:hover { background-color: rgba(255,255,255,0.3); border-color: transparent; }");
        copy_button.clicked.connect(() => {
           if (file_transfer.info != null) Clipboard.get_default(Gdk.Display.get_default()).set_text(file_transfer.info, file_transfer.info.length);
        });

        Image open_image = builder.get_object("open_image") as Image;
        Util.force_css(open_image, "*:not(:hover) { color: #eee; }");
        Button open_button = builder.get_object("open_button") as Button;
        Util.force_css(open_button, "*:hover { background-color: rgba(255,255,255,0.3); border-color: transparent; }");
        open_button.clicked.connect(() => {
            try{
                AppInfo.launch_default_for_uri(file_transfer.info, null);
            } catch (Error err) {
                print("Tried to open " + file_transfer.info);
            }
        });

        Revealer toolbar_revealer = new Revealer() { transition_type=RevealerTransitionType.CROSSFADE, transition_duration=400, visible=true };
        toolbar_revealer.add(toolbar);

        Grid grid = new Grid() { visible=true };
        grid.attach(toolbar_revealer, 0, 0, 1, 1);
        grid.attach(image, 0, 0, 1, 1);

        EventBox event_box = new EventBox() { halign=Align.START, visible=true };
        event_box.add(grid);
        event_box.enter_notify_event.connect(() => { toolbar_revealer.reveal_child = true; return false; });
        event_box.leave_notify_event.connect(() => { toolbar_revealer.reveal_child = false; return false; });

        return event_box;
    }

    private void update_info(Label url_label, string? info) {
        string url = info ?? "";
        if (url.has_prefix("https://")) url = url.substring(8);
        if (url.has_prefix("http://")) url = url.substring(7);
        if (url.has_prefix("www.")) url = url.substring(4);
        string[] slash_split = url.split("/");
        if (slash_split.length > 2) url = slash_split[0] + "/…/" + slash_split[slash_split.length - 1];
        url_label.label = url;
    }

    private Entities.Message.Marked file_to_message_state(FileTransfer.State state) {
        switch (state) {
            case FileTransfer.State.IN_PROCESS:
                return Entities.Message.Marked.UNSENT;
            case FileTransfer.State.COMPLETE:
                return Entities.Message.Marked.NONE;
            case FileTransfer.State.NOT_STARTED:
                return Entities.Message.Marked.UNSENT;
            case FileTransfer.State.FAILED:
                return Entities.Message.Marked.WONTSEND;
        }
        assert_not_reached();
    }
}

}
