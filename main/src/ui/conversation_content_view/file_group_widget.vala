using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui {

    public class FileGroupMetaItem : ConversationSummary.ContentMetaItem {

        private StreamInteractor stream_interactor;
        private FileGroupItem file_group_item;

        public FileGroupMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
            base(content_item);
            this.stream_interactor = stream_interactor;
            this.file_group_item = content_item as FileGroupItem;
        }

        public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {
            var file_transfers = file_group_item.file_group.file_transfers;

            if (file_transfers.size > 1 && all_files_images(file_transfers)) {
                return new ImageGroupWidget(file_transfers);
            } else {
                Box box = new Box(Orientation.VERTICAL, 6);
                foreach (FileTransfer file_transfer in file_transfers) {
                    FileWidget widget = new FileWidget(file_transfer) { halign = Align.START };
                    widget.add_css_class("file-image-widget");
                    FileWidgetController widget_controller = new FileWidgetController(widget, file_transfer, stream_interactor);
                    box.append(widget);
                }
                return box;
            }
        }

        public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) {
            Gee.List<Plugins.MessageAction> actions = new ArrayList<Plugins.MessageAction>();
            return actions;
        }
    }

    public class ImageGroupWidget : Box {

        private Gee.ArrayList<FileTransfer> file_transfers;

        public ImageGroupWidget(Gee.ArrayList<FileTransfer> file_transfers) {
            this.file_transfers = file_transfers;

            if (file_transfers.size == 3) {
                Box box = new Box(Orientation.HORIZONTAL, 4) {
                    overflow = Overflow.HIDDEN,
                    halign = Align.START
                };
                box.add_css_class("image-group");

                var picture1 = new FileImageWidget.from_file_transfer(file_transfers[0], 200);
                box.append(picture1);

                Box box1 = new Box(Orientation.VERTICAL, 4);

                var picture2 = new FileImageWidget.from_file_transfer(file_transfers[1], 100);
                box1.append(picture2);
                var picture3 = new FileImageWidget.from_file_transfer(file_transfers[2], 100);
                box1.append(picture3);
                box.append(box1);

                this.append(box);
            } else {
                Box box = new Box(Orientation.VERTICAL, 4) {
                    overflow = Overflow.HIDDEN,
                    halign = Align.START
                };
                box.add_css_class("image-group");

                Box row_upper_row = new Box(Orientation.HORIZONTAL, 4);

                var picture1 = new FileImageWidget.from_file_transfer(file_transfers[0], 150);
                row_upper_row.append(picture1);

                var picture2 = new FileImageWidget.from_file_transfer(file_transfers[1], 150);
                row_upper_row.append(picture2);
                box.append(row_upper_row);

                if (file_transfers.size >= 4) {

                    int size = 150;
                    if (file_transfers.size == 5) size = 99;

                    Box row_lower_row = new Box(Orientation.HORIZONTAL, 4);

                    var picture3 = new FileImageWidget.from_file_transfer(file_transfers[2], size);
                    row_lower_row.append(picture3);

                    var picture4 = new FileImageWidget.from_file_transfer(file_transfers[3], size);
                    row_lower_row.append(picture4);

                    if (file_transfers.size == 5) {
                        var picture5 = new FileImageWidget.from_file_transfer(file_transfers[4], size);
                        row_lower_row.append(picture5);
                    }

                    box.append(row_lower_row);
                }
                this.append(box);
            }
        }
    }

    public static bool all_files_images(Gee.ArrayList<FileTransfer> file_transfers) {
        foreach (FileTransfer file_transfer in file_transfers) {
            if (!Dino.Util.is_pixbuf_supported_content_type(file_transfer.content_type)) {
                return false;
            }
        }
        return true;
    }
}