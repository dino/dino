using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/file_send_overlay.ui")]
public class FileSendOverlay : Gtk.EventBox {

    public signal void send_file(File file);
    public Promise<long> file_size_limit = new Promise<long>();

    [GtkChild] public unowned Button close_button;
    [GtkChild] public unowned Button send_button;
    [GtkChild] public unowned Button add_more;    
    [GtkChild] public unowned Box files_widget;

    private bool can_send = true;

    public FileSendOverlay() {

        close_button.clicked.connect(() => {
            this.destroy();
        });
        send_button.clicked.connect(() => {
            foreach( var child in files_widget.get_children()){
                var files_widget = (FileWidget) child;
                if(files_widget.is_ok)
                    send_file(files_widget.file);
            }
            this.destroy();
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
                this.destroy();
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
            //TODO filter exisitng files or sort
            load_file_widget.begin(file);       
        }        
        update_send_label();
    }

    
    private void update_send_label() {
        var remaining_size = 0;
        foreach( var child in files_widget.get_children()){
            var files_widget = (FileWidget) child;
            if(files_widget.is_ok)
                remaining_size++;
        }
        
        send_button.label = n("Send %i file","Send %i files",remaining_size).printf(remaining_size);
        
        can_send = remaining_size != 0;
        send_button.sensitive = can_send;
        
    }

    [GtkTemplate (ui = "/im/dino/Dino/file_send_overlay_file_widget.ui")]
    public class FileWidget:Gtk.Box {
        [GtkChild] public unowned Button remove_button;
        [GtkChild] public unowned Label error_label;
        [GtkChild] public unowned Container box_for_widget;

        public bool is_ok = true;
        public File file;
        FileInfo file_info;
        FileSendOverlay overlay;



        public FileWidget(FileSendOverlay fileSendOverlay, File file,FileInfo file_info) {
            this.file = file;
            this.file_info = file_info;
            this.overlay = fileSendOverlay;

            remove_button.clicked.connect(()=>{                
                this.destroy();
                fileSendOverlay.update_send_label();
            });
        }
        private bool open_file(EventButton event_button){
            if (event_button.button != 1)
            return false;
            var file_uri = file.get_uri();
            try{
                AppInfo.launch_default_for_uri(file_uri, null);
            } catch (Error err) {
                warning("Failed to open %s - %s", file_uri, err.message);
            }
            return false;
        }

        public async void load_file() {
            Widget? widget = yield try_to_create_image_widget();
            if (widget == null) {
               widget= yield create_default_widget();
            }
            box_for_widget.add(widget);

            if (file_info.get_file_type() == GLib.FileType.DIRECTORY){
                set_error(_("Directories cannot be uploaded."));
            }else {
                var size = yield overlay.file_size_limit.future.wait_async();
                if (file_info.get_size() > size)
                    set_error(_("The file exceeds the server's maximum upload size of %s.").printf(format_size(size)));               
            }
        }
        private void set_error(string message){
            Util.force_error_color(error_label);
            error_label.label = message;
            error_label.visible=true;
            is_ok = false;
            overlay.update_send_label();
        }


        private async Widget? try_to_create_image_widget() {
            
            string file_name = file_info.get_display_name();
            string mime_type = file_info.get_content_type();
            
            bool is_image = false;
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

        private async Widget create_default_widget() {
            string file_name = file_info.get_display_name();
            string mime_type = file_info.get_content_type();
            FileDefaultWidget default_widget = new FileDefaultWidget() { visible=true };
            default_widget.name_label.label = file_name;
            default_widget.update_file_info(mime_type, FileTransfer.State.COMPLETE, (long)file_info.get_size());
            default_widget.button_release_event.connect(open_file);
            return default_widget;
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
        var box = new FileWidget(this,file,file_info);
        yield box.load_file();
        files_widget.add(box);
    }
}
}