using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_send_overlay.ui")]
public class FileSendOverlay : Gtk.EventBox {

    public signal void close();
    public signal void send_file(File file);
    public signal void set_file_size_limit(long size);

    [GtkChild] public unowned Button close_button;
    [GtkChild] public unowned Button send_button;
    [GtkChild] public unowned Button add_more;    
    [GtkChild] public unowned Box files_widget;

    private bool can_send = true;

    public GLib.List<File> remaing_files;

    public FileSendOverlay() {
        close.connect_after(()=>{
            this.destroy();
        });
        close_button.clicked.connect(() => {
            this.close();
        });
        send_button.clicked.connect(() => {
            foreach( var file in remaing_files){
                send_file(file);
            }
            this.close();
        });
       

        this.realize.connect(() => {
            if (can_send) {
                send_button.grab_focus();
            } else {
                close_button.grab_focus();
            }
        });

        this.key_release_event.connect((event) => {
            if (event.keyval == Gdk.Key.Escape) {
                this.close();
            }
            return false;
        });
        update_send_label();
        add_more.clicked.connect(()=>{
            PreviewFileChooserNative chooser = new PreviewFileChooserNative(_("Select file"), get_toplevel() as Gtk.Window, FileChooserAction.OPEN, _("Select"), _("Cancel"),true);
            if (chooser.run() == Gtk.ResponseType.ACCEPT) {
                add_files(chooser.get_files());
            }
        });
    }
    public void add_files(SList<File> files) {
        foreach( var file in files){
            //TODO filter exisitng files?
            load_file_widget.begin(file);
            remaing_files.append(file);            
        }    
        update_send_label();
    }

    
    private void update_send_label() {
        var remaining_size = remaing_files.length();
        send_button.label = n("Send %i file","Send %i files",remaining_size).printf(remaining_size);
        
        var is_sending_ok =remaining_size!=0;
        send_button.sensitive = is_sending_ok;
        can_send=is_sending_ok;
    }

    [GtkTemplate (ui = "/im/dino/Dino/file_send_overlay_file_widget.ui")]
    public class FileWidget:Gtk.Box {
        [GtkChild] public unowned Button remove_button;
        [GtkChild] public unowned Label error_label;
        [GtkChild] public unowned Container box_for_widget;

        public FileWidget(FileSendOverlay fileSendOverlay, File file,FileInfo file_info) {
            remove_button.clicked.connect(()=>{                
                fileSendOverlay.files_widget.remove(this);
                this.destroy();
                fileSendOverlay.remaing_files.remove(file);
                fileSendOverlay.update_send_label();
            });
            Util.force_error_color(error_label);
            if (file_info.get_file_type()==GLib.FileType.DIRECTORY){
                error_label.label = _("Directories cannot be uploaded.");
                error_label.visible=true;
                fileSendOverlay.remaing_files.remove(file);
            }else {
                fileSendOverlay.set_file_size_limit.connect((size)=>{
                    if (file_info.get_size()<=size)
                        return ;
                    error_label.label = _ ("The file exceeds the server's maximum upload size of %s.").printf(format_size((uint64)size));
                    error_label.visible=true;
                    fileSendOverlay.remaing_files.remove(file);
                    fileSendOverlay.update_send_label();
                });
            }
        }

        private async Widget? try_to_create_image_widget(File file,FileInfo file_info) {
            bool is_image = false;
            string file_name = file_info.get_display_name();
            string mime_type = file_info.get_content_type();
            foreach (PixbufFormat pixbuf_format in Pixbuf.get_formats()) {
                foreach (string supported_mime_type in pixbuf_format.get_mime_types()) {
                    if (supported_mime_type == mime_type) {
                        is_image = true;
                    }
                }
            }
            if (!is_image)
                return null;
            FileImageWidget image_widget = new FileImageWidget() { visible=true };
            try {
                yield image_widget.load_from_file(file, file_name,500,200);
                return image_widget;
            } catch (Error e) {   
                warning("Failed to generate preview %s - %s", file.get_path(), e.message);
                return null;
            }
        }

        private async Widget create_default_widget(File file,FileInfo file_info) {
            string file_name = file_info.get_display_name();
            string mime_type = file_info.get_content_type();
            FileDefaultWidget default_widget = new FileDefaultWidget() { visible=true };
            default_widget.name_label.label = file_name;
            default_widget.update_file_info(mime_type, FileTransfer.State.COMPLETE, (long)file_info.get_size());
            return default_widget;
        }

        public async void load_file( File file,FileInfo file_info) {
            Widget? widget = yield try_to_create_image_widget(file,file_info);
            if (widget == null) {
               widget= yield create_default_widget(file,file_info);
            }
            widget.button_release_event.connect(()=>{
                    var file_uri = file.get_uri();
                    try{
                        AppInfo.launch_default_for_uri(file_uri, null);
                    } catch (Error err) {
                        warning("Failed to open %s - %s", file_uri, err.message);
                    }
                    return false;
            });
            box_for_widget.add(widget);
        }
    }



    private async void load_file_widget(File file) {
        FileInfo file_info;
        try {
            file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        } catch (Error e) { 
            warning("Failed to get file info %s - %s", file.get_path(), e.message);
            return ;
         }

        var box = new FileWidget (this,file,file_info);
        files_widget.add(box);
        yield box.load_file(file,file_info);
    }

}
}