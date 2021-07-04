using Gdk;
using Gtk;
namespace Dino.Ui.ConversationSummary {
public class PreviewDownloadManager:Object{
    static Soup.Session sesion ;
    public delegate void DataCallback (File file);   
    private static HashTable<string,PreviewDownloadInProgess> downloadsInProgess ;

    public static PreviewDownloadInProgess get_event(string uri){
        lock(downloadsInProgess){
            if(downloadsInProgess==null){
                sesion = new Soup.Session();
                sesion.add_feature(new Soup.ContentSniffer());
                downloadsInProgess =  new HashTable<string,PreviewDownloadInProgess>(str_hash, str_equal);
            }
            PreviewDownloadInProgess dip;
            if(downloadsInProgess.contains(uri)){
                dip = downloadsInProgess[uri];
            }else{
                dip = new PreviewDownloadInProgess(uri);
                downloadsInProgess[uri]= dip;
            }
            return dip;            
        }     
    }
    public class PreviewDownloadInProgess : Object {
        public enum Status{
            NOTSTARTED,
            INPROGRESS,
            FINISHED
        }
        public Status status;
        public signal void finished_event (File file);
        public Mutex mutex = Mutex();
        public File file ;
        string uri;

        public PreviewDownloadInProgess(string uri){
            this.uri = uri;

            var checsum = GLib.Checksum.compute_for_string(GLib.ChecksumType.SHA256,uri );
            var path = Path.build_filename(Dino.get_storage_dir(), "files", checsum);
            file = File.new_for_path(path);            
            if(GLib.FileUtils.test(path,GLib.FileTest.EXISTS)){
                status = Status.FINISHED;                 
            }else{
                status =  Status.NOTSTARTED;
            }
        }
        

        public void start_download(){
            status = Status.INPROGRESS;
            Soup.Message message =new  Soup.Message("GET", uri);  
            message.ref();
            sesion.queue_message(message,(sesion,msg)=>{
                try{
                    FileOutputStream os = file.create (FileCreateFlags.PRIVATE);
                    os.write_async.begin(msg.response_body.data,GLib.Priority.DEFAULT,null,(obj, res) => {
                        mutex.lock();
                        status= Status.FINISHED;
                        this.finished_event(file);
                        mutex.unlock();
                        message.unref();                        
                    });
                }catch (Error e) {
                    warning(e.message);
                }
            }); 
        }
    }
}              

public class PreviewWidget:Frame{   

    static Regex regex_zalgo = /< *meta[^<]*property= *"og:([^"]+)"[^<]*content= *"([^"]+)"/;
    static Regex regex_title = /<title>(.*?)<\/title>/;
    public delegate void DataCallback (File file);

    public string uri;

    public PreviewWidget(string uri,bool auto_download){
        visible= true;
        if (uri.length<64)
            label = uri;
        else{
            label = @"$(uri[0:60])...";
        }
        var dip = PreviewDownloadManager.get_event(uri);
        dip.mutex.lock();
        switch (dip.status) {
            case NOTSTARTED:{
                if(!auto_download){
                    var button = new Button(){visible=true, label=@"Generate preview"};
                    add(button);
                    button.clicked.connect(()=>{
                        button.set_sensitive(false);
                        dip.mutex.lock();
                        if (dip.status == NOTSTARTED)
                            PreviewDownloadManager.get_event(uri).start_download();     
                        dip.mutex.unlock();
                            
                    });                   
                }else{
                    PreviewDownloadManager.get_event(uri).start_download();   
                }
                dip.finished_event.connect(handle_file);
                break;
            }
            case INPROGRESS:{
                dip.finished_event.connect(handle_file);
                break;
            }
            case FINISHED:{
                handle_file.begin(dip.file);
                break;
            }
        }
        dip.mutex.unlock();
    }

    private void handle_OGP(ByteArray data){
        var text =(string)data.data;            
        MatchInfo match_info;
        regex_zalgo.match(text, 0, out match_info);
        string? title = null;
        string? description = null;
        string? imagePath = null;
        while (match_info.matches()) {
                int start, end;
                match_info.fetch_pos(1, out start, out end);
                var key =text[start:end];
                match_info.fetch_pos(2, out start, out end);
                var value =text[start:end];
                if (key == "title"){
                    title= value;
                }
                if (key == "description"){
                    description = value;
                }
                if(key =="image"){
                    imagePath  = value;
                }
                try{
                    match_info.next();
                }catch (GLib.RegexError e) {
                    warning(@"Regex Error - $(e.message)");
                    return;
                }
        }
        if(title == null){
            int start, end;
            regex_title.match(text, 0, out match_info);
            match_info.fetch_pos(1, out start, out end);
            if(match_info.matches())
                title =text[start:end];
        }
        var ltext = "";
        if(title!=null)
            ltext +=@"<b>$(title)</b>\n\n";
        if(description!=null)
            ltext+=description;

        var summary = new Label(""){visible=true};
        summary.set_line_wrap(true);
        summary.set_markup(ltext);
        summary.set_max_width_chars(80);

        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,10){visible=true};
        box.pack_end(summary,true,true);
        this.add(box);

        if(imagePath!=null){
            var dip = PreviewDownloadManager.get_event(imagePath);
            dip.mutex.lock();
            switch (dip.status) {
                case NOTSTARTED:{
                    dip.finished_event.connect(add_minature);
                    dip.start_download();
                    break;
                }
                case INPROGRESS:{
                    dip.finished_event.connect(add_minature);
                    break;    
                }
                case FINISHED:{
                    add_minature.begin(dip.file);
                    break;
                }
            }        
            dip.mutex.unlock();
        }
    }
    private async void add_minature(File file){
        Thread<ScalingImage?> thread = new Thread<ScalingImage?> (null, () => {
            ScalingImage image = new ScalingImage() { halign=Align.START, visible = true, max_width = 300, max_height = 100 };
            Gdk.Pixbuf pixbuf;
            try {
                pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
            } catch (Error error) {
                warning("Can't load picture %s - %s", file.get_path(), error.message);
                Idle.add(add_minature.callback);
                return null;
            }
            pixbuf = pixbuf.apply_embedded_orientation();
            image.load(pixbuf);
            Idle.add(add_minature.callback);
            return image;
        });
        yield;
        ScalingImage image = thread.join();
        if (image == null) {
            warning("Error loading image");
            return;
        }
        var box = get_child() as Gtk.Box;
        box.pack_start(image,false);
    }
    static bool is_mime_image(string type){
        foreach (PixbufFormat pixbuf_format in Pixbuf.get_formats()) {
            foreach (string mime_type in pixbuf_format.get_mime_types()) {
                if (mime_type == type) {
                    return true;
                }
            }
        }
        return false;
    }   
    private void handle_image(File file){
        var fiw = new FileImageWidget(){visible=true};            
        fiw.load_from_file.begin (file,"Preview",600,300,()=>{this.add(fiw);});
    }

    public async void handle_file(File file ){       
        try {
            var os = new DataInputStream(yield  file.read_async());     
            uint8[] line ;  
            var buffer = new ByteArray();
            while( (line= (yield os.read_bytes_async(1024)).get_data())!=null){
                buffer.append(line);
            }
            bool isOk ;
            var mime = ContentType.guess(null,buffer.data,out isOk);
            if(get_child()!=null)
                remove(get_child());    
            if(mime.to_string()=="text/html"){
                handle_OGP(buffer);
            }else if (is_mime_image(mime.to_string())){
                handle_image(file);
            }
            else{
                this.add(new Label(@"No preview for $mime"));
            }
        } catch (Error e) {
            warning(e.message);
        }
    }
} 
}