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
    [GtkChild] public unowned Box files_widget;
    [GtkChild] public unowned ScrolledWindow files_widget_scroll;

    private bool can_send = true;

    public GLib.List<File> remaing_files;

    public FileSendOverlay(SList<File> files) {

        close_button.clicked.connect(() => {
            this.close();
            this.destroy();
        });
        send_button.clicked.connect(() => {
            foreach( var file in remaing_files){
                send_file(file);
            }
            this.close();
            this.destroy();
        });
        foreach( var file in files){
            load_file_widget.begin(file);
            remaing_files.append(file);            
        }
        

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
    }

    
    private void update_send_label(){
        var remaining_size = remaing_files.length();
        send_button.label = n("Send %i file","Send %i files",remaining_size).printf(remaining_size);
        if (remaining_size==0){
            send_button.sensitive = false;
            can_send=false;
        }
        if (files_widget.get_children().length()==0)
            close_button.clicked();
    }

    private async Widget? try_to_create_image_widget(File file,FileInfo file_info){
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

        Widget? widget = null;
        if (is_image) {
            FileImageWidget image_widget = new FileImageWidget() { visible=true };
            try {
                yield image_widget.load_from_file(file, file_name,500,200);
                widget = image_widget;
            } catch (Error e) { }
        }
        return widget;
    }

    private async Widget create_default_widget(File file,FileInfo file_info){
        string file_name = file_info.get_display_name();
        string mime_type = file_info.get_content_type();

        FileDefaultWidget default_widget = new FileDefaultWidget() { visible=true };
        default_widget.name_label.label = file_name;
        default_widget.update_file_info(mime_type, FileTransfer.State.COMPLETE, (long)file_info.get_size());
        return default_widget;
    }

    private Container create_widget_strucute(File file,FileInfo file_info){
        var box = new Box(Gtk.Orientation.HORIZONTAL,0){visible=true};
        var box2 = new Box(Gtk.Orientation.VERTICAL,0){visible=true};
        var button = new Button(){visible=true, label=_("Remove File")};
        button.clicked.connect(()=>{
            remaing_files.remove(file);
            files_widget.remove(box2);
            box2.destroy();
            update_send_label();
        });

        
        box.add(button);
        box2.add(box);
        files_widget.add(box2);

        if(file_info.get_file_type()==GLib.FileType.DIRECTORY){
            //Create make file file method?
            var info_label = new Label( _("Directories cannot be uploaded.")){visible=true};
            Util.force_error_color(info_label);
            box2.add (info_label);
            remaing_files.remove(file);
        }else{
            set_file_size_limit.connect((size)=>{
                if (file_info.get_size()<=size)
                    return ;
                var info_label = new Label( _("The file exceeds the server's maximum upload size.")){visible=true};
                Util.force_error_color(info_label);
                box2.add (info_label);
                remaing_files.remove(file);
                update_send_label();
            });
        }
        return box;
    }

    private async void load_file_widget(File file) {
        FileInfo file_info;
        try {
            file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        } catch (Error e) { return; }
    

        var box =create_widget_strucute(file,file_info);
        Widget? widget = yield try_to_create_image_widget(file,file_info);
        if (widget == null) {
           widget= yield create_default_widget(file,file_info);
        }
        box.add(widget);
    }
}

}