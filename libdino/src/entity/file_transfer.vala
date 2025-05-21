using Xmpp;

namespace Dino.Entities {

public class FileTransfer : Object {

    public signal void sources_changed();

    public const bool DIRECTION_SENT = true;
    public const bool DIRECTION_RECEIVED = false;

    public enum State {
        COMPLETE,
        IN_PROGRESS,
        NOT_STARTED,
        FAILED
    }

    public int id { get; set; default=-1; }
    public string? file_sharing_id { get; set; }
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

    // This value is not persisted
    public int64 transferred_bytes { get; set; }

    public Xep.FileMetadataElement.FileMetadata file_metadata {
        owned get {
            return new Xep.FileMetadataElement.FileMetadata() {
                name = this.file_name,
                mime_type = this.mime_type,
                size = this.size,
                desc = this.desc,
                date = this.modification_date,
                width = this.width,
                height = this.height,
                length = this.length,
                hashes = this.hashes,
                thumbnails = this.thumbnails
            };
        }
        set {
            this.file_name = value.name;
            this.mime_type = value.mime_type;
            this.size = value.size;
            this.desc = value.desc;
            this.modification_date = value.date;
            this.width = value.width;
            this.height = value.height;
            this.length = value.length;
            this.hashes = value.hashes;
            this.thumbnails = value.thumbnails;
        }
    }
    public string? desc { get; set; }
    public DateTime? modification_date { get; set; }
    public int width { get; set; default=-1; }
    public int height { get; set; default=-1; }
    public int64 length { get; set; default=-1; }
    public Gee.List<Xep.CryptographicHashes.Hash> hashes = new Gee.ArrayList<Xep.CryptographicHashes.Hash>();
    public Gee.List<Xep.StatelessFileSharing.Source> sfs_sources = new Gee.ArrayList<Xep.StatelessFileSharing.Source>(Xep.StatelessFileSharing.Source.equals_func);
    public Gee.List<Xep.JingleContentThumbnails.Thumbnail> thumbnails = new Gee.ArrayList<Xep.JingleContentThumbnails.Thumbnail>();

    private Database? db;
    private string storage_dir;

    public FileTransfer.from_row(Database db, Qlite.Row row, string storage_dir) throws InvalidJidError {
        this.db = db;
        this.storage_dir = storage_dir;

        id = row[db.file_transfer.id];
        file_sharing_id = row[db.file_transfer.file_sharing_id];
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

        // TODO put those into the initial query
        foreach(var hash_row in db.file_hashes.select().with(db.file_hashes.id, "=", id)) {
            Xep.CryptographicHashes.Hash hash = new Xep.CryptographicHashes.Hash();
            hash.algo = hash_row[db.file_hashes.algo];
            hash.val = hash_row[db.file_hashes.value];
            hashes.add(hash);
        }

        foreach(var thumbnail_row in db.file_thumbnails.select().with(db.file_thumbnails.id, "=", id)) {
            Xep.JingleContentThumbnails.Thumbnail thumbnail = new Xep.JingleContentThumbnails.Thumbnail();
            thumbnail.uri = thumbnail_row[db.file_thumbnails.uri];
            thumbnail.media_type = thumbnail_row[db.file_thumbnails.mime_type];
            thumbnail.width = thumbnail_row[db.file_thumbnails.width];
            thumbnail.height = thumbnail_row[db.file_thumbnails.height];
            thumbnails.add(thumbnail);
        }

        foreach(Qlite.Row source_row in db.sfs_sources.select().with(db.sfs_sources.file_transfer_id, "=", id)) {
            if (source_row[db.sfs_sources.type] == "http") {
                sfs_sources.add(new Xep.StatelessFileSharing.HttpSource() { url=source_row[db.sfs_sources.data] });
            }
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

        if (file_sharing_id != null) builder.value(db.file_transfer.file_sharing_id, file_sharing_id);
        if (path != null) builder.value(db.file_transfer.path, path);
        if (mime_type != null) builder.value(db.file_transfer.mime_type, mime_type);
        if (path != null) builder.value(db.file_transfer.path, path);
        if (modification_date != null) builder.value(db.file_transfer.modification_date, (long) modification_date.to_unix());
        if (width != -1) builder.value(db.file_transfer.width, width);
        if (height != -1) builder.value(db.file_transfer.height, height);
        if (length != -1) builder.value(db.file_transfer.length, (long) length);

        id = (int) builder.perform();

        foreach (Xep.CryptographicHashes.Hash hash in hashes) {
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

        foreach (Xep.StatelessFileSharing.Source source in sfs_sources) {
            persist_source(source);
        }

        notify.connect(on_update);
    }

    public void add_sfs_source(Xep.StatelessFileSharing.Source source) {
        if (sfs_sources.contains(source)) return; // Don't add the same source twice. Might happen due to MAM and lacking deduplication.

        sfs_sources.add(source);
        if (id != -1) {
            persist_source(source);
        }
        sources_changed();
    }

    private void persist_source(Xep.StatelessFileSharing.Source source) {
        Xep.StatelessFileSharing.HttpSource? http_source = source as Xep.StatelessFileSharing.HttpSource;
        if (http_source != null) {
            db.sfs_sources.insert()
                    .value(db.sfs_sources.file_transfer_id, id)
                    .value(db.sfs_sources.type, "http")
                    .value(db.sfs_sources.data, http_source.url)
                    .perform();
        }
    }

    public File? get_file() {
        if (path == null) return null;
        return File.new_for_path(Path.build_filename(Dino.get_storage_dir(), "files", path));
    }

    private void on_update(Object o, ParamSpec sp) {
        Qlite.UpdateBuilder update_builder = db.file_transfer.update().with(db.file_transfer.id, "=", id);
        switch (sp.name) {
            case "file-sharing-id":
                update_builder.set(db.file_transfer.file_sharing_id, file_sharing_id); break;
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
}

}
