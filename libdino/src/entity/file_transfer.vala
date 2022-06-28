using Xmpp;

namespace Dino.Entities {

public class FileTransfer : Object {

    public const bool DIRECTION_SENT = true;
    public const bool DIRECTION_RECEIVED = false;

    public enum State {
        COMPLETE,
        IN_PROGRESS,
        NOT_STARTED,
        FAILED
    }

    public class SerializedSfsSource: Object {
        public string type;
        public string data;

        public SerializedSfsSource.from_sfs_source(Xep.StatelessFileSharing.SfsSource source) {
            this.type = source.type();
            this.data = source.serialize();
        }

        public async Xep.StatelessFileSharing.SfsSource to_sfs_source() {
            assert(this.type == Xep.StatelessFileSharing.HttpSource.SOURCE_TYPE);
            Xep.StatelessFileSharing.HttpSource http_source = yield Xep.StatelessFileSharing.HttpSource.deserialize(this.data);
            return http_source;
        }
    }

    public int id { get; set; default=-1; }
    public Account account { get; set; }
    public Jid counterpart { get; set; }
    public Jid ourpart { get; set; }
    public Jid? from {
        get { return direction == DIRECTION_SENT ? ourpart : counterpart; }
    }
    public Jid? to {
        get { return direction == DIRECTION_SENT ? counterpart : ourpart; }
    }
    public bool direction { get; set; }
    public DateTime time { get; set; }
    public DateTime? local_time { get; set; }
    public Encryption encryption { get; set; default=Encryption.NONE; }

    private InputStream? input_stream_ = null;
    public InputStream input_stream {
        get {
            if (input_stream_ == null) {
                File file = File.new_for_path(Path.build_filename(storage_dir, path ?? file_name));
                try {
                    input_stream_ = file.read();
                } catch (Error e) { }
            }
            return input_stream_;
        }
        set {
            input_stream_ = value;
        }
    }

    private string file_name_;
    public string file_name {
        get { return file_name_; }
        set {
            file_name_ = Path.get_basename(value);
            if (file_name_ == Path.DIR_SEPARATOR_S || file_name_ == ".") {
                file_name_ = "unknown filename";
            } else if (file_name_.has_prefix(".")) {
                file_name_ = "_" + file_name_;
            }
        }
    }
    private string? server_file_name_ = null;
    public string server_file_name {
        get { return server_file_name_ ?? file_name; }
        set { server_file_name_ = value; }
    }
    public string path { get; set; }
    public string? mime_type { get; set; }
    public int64 size { get; set; }
    public State state { get; set; default=State.NOT_STARTED; }
    public int provider { get; set; }
    public string info { get; set; }
    public Cancellable cancellable { get; default=new Cancellable(); }
    public string? desc { get; set; }
    public DateTime? modification_date { get; set; }
    public int width { get; set; default=-1; }
    public int height { get; set; default=-1; }
    public int64 length { get; set; default=-1; }
    public Xep.CryptographicHashes.Hashes hashes { get; set; default=new Xep.CryptographicHashes.Hashes();}
    public ListStore sfs_sources { get; set; default=new ListStore(typeof(SerializedSfsSource)); }
    public Gee.List<Xep.JingleContentThumbnails.Thumbnail> thumbnails = new Gee.ArrayList<Xep.JingleContentThumbnails.Thumbnail>();

    private Database? db;
    private string storage_dir;

    public FileTransfer.from_row(Database db, Qlite.Row row, string storage_dir) throws InvalidJidError {
        this.db = db;
        this.storage_dir = storage_dir;

        id = row[db.file_transfer.id];
        account = db.get_account_by_id(row[db.file_transfer.account_id]); // TODO don’t have to generate acc new

        counterpart = db.get_jid_by_id(row[db.file_transfer.counterpart_id]);
        string counterpart_resource = row[db.file_transfer.counterpart_resource];
        if (counterpart_resource != null) counterpart = counterpart.with_resource(counterpart_resource);

        string our_resource = row[db.file_transfer.our_resource];
        if (our_resource != null) {
            ourpart = account.bare_jid.with_resource(our_resource);
        } else {
            ourpart = account.bare_jid;
        }
        direction = row[db.file_transfer.direction];
        time = new DateTime.from_unix_utc(row[db.file_transfer.time]);
        local_time = new DateTime.from_unix_utc(row[db.file_transfer.local_time]);
        encryption = (Encryption) row[db.file_transfer.encryption];
        file_name = row[db.file_transfer.file_name];
        path = row[db.file_transfer.path];
        mime_type = row[db.file_transfer.mime_type];
        size = (int64) row[db.file_transfer.size];
        state = (State) row[db.file_transfer.state];
        provider = row[db.file_transfer.provider];
        info = row[db.file_transfer.info];
        modification_date = new DateTime.from_unix_utc(row[db.file_transfer.modification_date]);
        width = row[db.file_transfer.width];
        height = row[db.file_transfer.height];
        length = (int64) row[db.file_transfer.length];

        foreach(var hash_row in db.file_hashes.select().with(db.file_hashes.id, "=", id)) {
            Xep.CryptographicHashes.Hash hash = new Xep.CryptographicHashes.Hash();
            hash.algo = hash_row[db.file_hashes.algo];
            hash.val = hash_row[db.file_hashes.value];
            hashes.hashes.add(hash);
        }

        foreach(var thumbnail_row in db.file_thumbnails.select().with(db.file_thumbnails.id, "=", id)) {
            Xep.JingleContentThumbnails.Thumbnail thumbnail = new Xep.JingleContentThumbnails.Thumbnail();
            thumbnail.uri = thumbnail_row[db.file_thumbnails.uri];
            thumbnail.media_type = thumbnail_row[db.file_thumbnails.mime_type];
            thumbnail.width = thumbnail_row[db.file_thumbnails.width];
            thumbnail.height = thumbnail_row[db.file_thumbnails.height];
            thumbnails.add(thumbnail);
        }

        foreach(Qlite.Row source_row in db.sfs_sources.select().with(db.sfs_sources.id, "=", id)) {
            SerializedSfsSource source = new SerializedSfsSource();
            source.type = source_row[db.sfs_sources.type];
            source.data = source_row[db.sfs_sources.data];
            sfs_sources.append(source as Object);
        }

        notify.connect(on_update);
    }

    public void persist(Database db) {
        if (id != -1) return;

        this.db = db;
        Qlite.InsertBuilder builder = db.file_transfer.insert()
            .value(db.file_transfer.account_id, account.id)
            .value(db.file_transfer.counterpart_id, db.get_jid_id(counterpart))
            .value(db.file_transfer.counterpart_resource, counterpart.resourcepart)
            .value(db.file_transfer.our_resource, ourpart.resourcepart)
            .value(db.file_transfer.direction, direction)
            .value(db.file_transfer.time, (long) time.to_unix())
            .value(db.file_transfer.local_time, (long) local_time.to_unix())
            .value(db.file_transfer.encryption, encryption)
            .value(db.file_transfer.file_name, file_name)
            .value(db.file_transfer.size, (long) size)
            .value(db.file_transfer.state, state)
            .value(db.file_transfer.provider, provider)
            .value(db.file_transfer.info, info);

        if (path != null) builder.value(db.file_transfer.path, path);
        if (mime_type != null) builder.value(db.file_transfer.mime_type, mime_type);
        if (path != null) builder.value(db.file_transfer.path, path);
        if (modification_date != null) builder.value(db.file_transfer.modification_date, (long) modification_date.to_unix());
        if (width != -1) builder.value(db.file_transfer.width, width);
        if (height != -1) builder.value(db.file_transfer.height, height);
        if (length != -1) builder.value(db.file_transfer.length, (long) length);

        id = (int) builder.perform();

        foreach (Xep.CryptographicHashes.Hash hash in hashes.hashes) {
            db.file_hashes.insert()
                    .value(db.file_hashes.id, id)
                    .value(db.file_hashes.algo, hash.algo)
                    .value(db.file_hashes.value, hash.val)
                    .perform();
        }
        foreach (Xep.JingleContentThumbnails.Thumbnail thumbnail in thumbnails) {
            db.file_thumbnails.insert()
                    .value(db.file_thumbnails.id, id)
                    .value(db.file_thumbnails.uri, thumbnail.uri)
                    .value(db.file_thumbnails.mime_type, thumbnail.media_type)
                    .value(db.file_thumbnails.width, thumbnail.width)
                    .value(db.file_thumbnails.height, thumbnail.height)
                    .perform();
        }

        for(int i = 0; i < sfs_sources.get_n_items(); i++) {
            Object source_object = sfs_sources.get_item(i);
            SerializedSfsSource source = source_object as SerializedSfsSource;
            db.sfs_sources.insert()
                    .value(db.sfs_sources.id, id)
                    .value(db.sfs_sources.type, source.type)
                    .value(db.sfs_sources.data, source.data)
                    .perform();
        }

        notify.connect(on_update);
        sfs_sources.items_changed.connect((position, removed, added) => {
            on_update_sources_items(this, position, removed, added);
        });
    }

    public File get_file() {
        return File.new_for_path(Path.build_filename(Dino.get_storage_dir(), "files", path));
    }

    private void on_update(Object o, ParamSpec sp) {
        Qlite.UpdateBuilder update_builder = db.file_transfer.update().with(db.file_transfer.id, "=", id);
        switch (sp.name) {
            case "counterpart":
                update_builder.set(db.file_transfer.counterpart_id, db.get_jid_id(counterpart));
                update_builder.set(db.file_transfer.counterpart_resource, counterpart.resourcepart); break;
            case "ourpart":
                update_builder.set(db.file_transfer.our_resource, ourpart.resourcepart); break;
            case "direction":
                update_builder.set(db.file_transfer.direction, direction); break;
            case "time":
                update_builder.set(db.file_transfer.time, (long) time.to_unix()); break;
            case "local-time":
                update_builder.set(db.file_transfer.local_time, (long) local_time.to_unix()); break;
            case "encryption":
                update_builder.set(db.file_transfer.encryption, encryption); break;
            case "file-name":
                update_builder.set(db.file_transfer.file_name, file_name); break;
            case "path":
                update_builder.set(db.file_transfer.path, path); break;
            case "mime-type":
                update_builder.set(db.file_transfer.mime_type, mime_type); break;
            case "size":
                update_builder.set(db.file_transfer.size, (long) size); break;
            case "state":
                if (state == State.IN_PROGRESS) return;
                update_builder.set(db.file_transfer.state, state); break;
            case "provider":
                update_builder.set(db.file_transfer.provider, provider); break;
            case "info":
                update_builder.set(db.file_transfer.info, info); break;
            case "modification-date":
                update_builder.set(db.file_transfer.modification_date, (long) modification_date.to_unix()); break;
            case "width":
                update_builder.set(db.file_transfer.width, width); break;
            case "height":
                update_builder.set(db.file_transfer.height, height); break;
            case "length":
                update_builder.set(db.file_transfer.length, (long) length); break;
        }
        update_builder.perform();
    }

    private void on_update_sources_items(FileTransfer file_transfer, uint position, uint removed, uint added) {
        for(uint i = position; i < position + added; i++) {
            Object source_object = file_transfer.sfs_sources.get_item(i);
            SerializedSfsSource source = source_object as SerializedSfsSource;
            db.sfs_sources.insert()
                    .value(db.sfs_sources.id, id)
                    .value(db.sfs_sources.type, source.type)
                    .value(db.sfs_sources.data, source.data)
                    .perform();
        }
    }

    public Xep.FileMetadataElement.FileMetadata to_metadata_element() {
        Xep.FileMetadataElement.FileMetadata metadata = new Xep.FileMetadataElement.FileMetadata();
        metadata.name = this.file_name;
        metadata.mime_type = this.mime_type;
        metadata.size = this.size;
        metadata.desc = this.desc;
        metadata.date = this.modification_date;
        metadata.width = this.width;
        metadata.height = this.height;
        metadata.length = this.length;
        metadata.hashes = this.hashes;
        metadata.thumbnails = this.thumbnails;
        return metadata;
    }

    public async Xep.StatelessFileSharing.SfsElement to_sfs_element() {
        Xep.StatelessFileSharing.SfsElement sfs_element = new Xep.StatelessFileSharing.SfsElement();
        sfs_element.metadata = this.to_metadata_element();
        for(int i = 0; i < sfs_sources.get_n_items(); i++) {
            Object source_object = sfs_sources.get_item(i);
            SerializedSfsSource source = source_object as SerializedSfsSource;
            sfs_element.sources.add(yield source.to_sfs_source());
        }

        return sfs_element;
    }

    public void with_metadata_element(Xep.FileMetadataElement.FileMetadata metadata) {
        this.file_name = metadata.name;
        this.mime_type = metadata.mime_type;
        this.size = metadata.size;
        this.desc = metadata.desc;
        this.modification_date = metadata.date;
        this.width = metadata.width;
        this.height = metadata.height;
        this.length = metadata.length;
        this.hashes = metadata.hashes;
        this.thumbnails = metadata.thumbnails;
    }
}

}
