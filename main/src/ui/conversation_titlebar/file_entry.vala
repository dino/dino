using Gtk;

using Dino.Entities;

namespace Dino.Ui {

public class FileEntry : Plugins.ConversationTitlebarEntry, Object {
    public string id { get { return "send_files"; } }

    StreamInteractor stream_interactor;

    public FileEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public double order { get { return 4; } }
    public Plugins.ConversationTitlebarWidget? get_widget(Plugins.WidgetType type) {
        if (type == Plugins.WidgetType.GTK) {
            return new FileWidget(stream_interactor) { visible=true };
        }
        return null;
    }
}

public class FileWidget : Button, Plugins.ConversationTitlebarWidget {

    private Conversation? conversation;
    private StreamInteractor stream_interactor;

    public FileWidget(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        image = new Image.from_icon_name("mail-attachment-symbolic", IconSize.MENU);
        clicked.connect(on_clicked);
        stream_interactor.get_module(FileManager.IDENTITY).upload_available.connect(on_upload_available);
    }

    public void on_clicked() {
        FileChooserNative chooser = new FileChooserNative (
                "Select file", get_toplevel() as Window, FileChooserAction.OPEN,
                "Select", "Cancel");
        Image preview_area = new Image();
        chooser.set_preview_widget (preview_area);
        chooser.update_preview.connect (() => {
            try {
                // TODO: maybe handle get_preview_uri with gvfs or something
                string filename = chooser.get_preview_filename();
                if (filename != null) {
                    int preview_width, preview_height;
                    Gdk.PixbufFormat preview_format = Gdk.Pixbuf.get_file_info(filename, out preview_width, out preview_height);
                    if (preview_format == null || preview_width > 4096 || preview_height > 4096) {
                        chooser.set_preview_widget_active(false);
                        return;
                    }
                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_size(filename, 180, 180);
                    preview_area.set_from_pixbuf(pixbuf);
                    chooser.set_preview_widget_active(true);
                } else {
                    chooser.set_preview_widget_active(false);
                }
            } catch (Error e) {
              chooser.set_preview_widget_active(false);
            }
        });

//        long max_file_size = stream_interactor.get_module(Manager.IDENTITY).get_max_file_size(conversation.account);
//        if (max_file_size != -1) {
//            FileFilter filter = new FileFilter();
//            filter.add_custom(FileFilterFlags.URI, (filter_info) => {
//                File file = File.new_for_uri(filter_info.uri);
//                FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
//                return file_info.get_size() <= max_file_size;
//            });
//            chooser.set_filter(filter);
//        }
        if (chooser.run() == Gtk.ResponseType.ACCEPT) {
            string uri = chooser.get_filename();
            stream_interactor.get_module(FileManager.IDENTITY).send_file(uri, conversation);
        }
    }

    public void on_upload_available(Account account) {
        if (conversation != null && conversation.account.equals(account)) {
            visible = true;
        }
    }

    public new void set_conversation(Conversation conversation) {
        this.conversation = conversation;
        visible = stream_interactor.get_module(FileManager.IDENTITY).is_upload_available(conversation);
    }
}

}
