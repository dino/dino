using Gdk;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

public class DefaultFileDisplay : Plugins.MetaConversationItem {
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

    public DefaultFileDisplay(StreamInteractor stream_interactor, FileTransfer file_transfer) {
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
        Box main_box = new Box(Orientation.HORIZONTAL, 4) { halign=Align.START, visible=true };
        string? icon_name = ContentType.get_generic_icon_name(file_transfer.mime_type);
        Image content_type_image = new Image.from_icon_name(icon_name, IconSize.DND) { visible=true };
        main_box.add(content_type_image);

        Box right_box = new Box(Orientation.VERTICAL, 0) { visible=true };
        Label name_label = new Label(file_transfer.file_name) { xalign=0, yalign=0, visible=true};
        right_box.add(name_label);
        Label mime_label = new Label("<span size='small'>" + _("File") + ": " + file_transfer.mime_type + "</span>") { use_markup=true, xalign=0, yalign=1, visible=true};
        mime_label.get_style_context().add_class("dim-label");
        right_box.add(mime_label);
        main_box.add(right_box);

        EventBox event_box = new EventBox() { halign=Align.START, visible=true };
        event_box.add(main_box);

        event_box.enter_notify_event.connect((event) => {
            event.get_window().set_cursor(new Cursor.for_display(Gdk.Display.get_default(), CursorType.HAND2));
            return false;
        });
        event_box.leave_notify_event.connect((event) => {
            event.get_window().set_cursor(new Cursor.for_display(Gdk.Display.get_default(), CursorType.XTERM));
            return false;
        });
        event_box.button_release_event.connect((event_button) => {
            if (event_button.button == 1) {
                try{
                    AppInfo.launch_default_for_uri("file://" + file_transfer.get_uri(), null);
                } catch (Error err) {
                    print("Tried to open " + file_transfer.get_uri());
                }
            }
            return false;
        });

        return event_box;
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
