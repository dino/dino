using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class FileManager : StreamInteractionModule, Object {
    public static ModuleIdentity<FileManager> IDENTITY = new ModuleIdentity<FileManager>("file");
    public string id { get { return IDENTITY.id; } }

    public signal void upload_available(Account account);
    public signal void received_file(FileTransfer file_transfer);

    private StreamInteractor stream_interactor;
    private Database db;
    private Gee.List<FileSender> file_senders = new ArrayList<FileSender>();
    private Gee.List<IncomingURLRewriter> incoming_url_rewriters = new ArrayList<IncomingURLRewriter>();
    private Gee.List<OutgoingURLRewriter> outgoing_url_rewriters = new ArrayList<OutgoingURLRewriter>();
    private Gee.List<IncommingFileProcessor> incomming_processors = new ArrayList<IncommingFileProcessor>();
    private Gee.List<OutgoingFileProcessor> outgoing_processors = new ArrayList<OutgoingFileProcessor>();

    public static void start(StreamInteractor stream_interactor, Database db) {
        FileManager m = new FileManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public static string get_storage_dir() {
        return Path.build_filename(Dino.get_storage_dir(), "files");
    }

    private FileManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        DirUtils.create_with_parents(get_storage_dir(), 0700);
    }

    public void send_file(string uri, Conversation conversation) {
        FileTransfer file_transfer = new FileTransfer();
        file_transfer.account = conversation.account;
        file_transfer.counterpart = conversation.counterpart;
        file_transfer.ourpart = conversation.account.bare_jid;
        file_transfer.direction = FileTransfer.DIRECTION_SENT;
        file_transfer.time = new DateTime.now_utc();
        file_transfer.local_time = new DateTime.now_utc();
        file_transfer.encryption = Encryption.NONE;
        try {
            File file = File.new_for_path(uri);
            FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
            file_transfer.file_name = file_info.get_display_name();
            file_transfer.mime_type = file_info.get_content_type();
            file_transfer.size = (int)file_info.get_size();
            file_transfer.input_stream = file.read();
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
        save_file(file_transfer);

        file_transfer.persist(db);

        foreach (OutgoingFileProcessor processor in outgoing_processors) {
            if (processor.can_process(conversation, file_transfer)) {
                processor.process(conversation, file_transfer);
            }
        }

        foreach (FileSender file_sender in file_senders) {
            if (file_sender.can_send(conversation, file_transfer)) {
                file_sender.send_file(conversation, file_transfer);
            }
        }
        received_file(file_transfer);
    }

    public bool is_upload_available(Conversation conversation) {
        foreach (FileSender file_sender in file_senders) {
            if (file_sender.is_upload_available(conversation)) return true;
        }
        return false;
    }

    public Gee.List<FileTransfer> get_file_transfers(Account account, Jid counterpart, DateTime after, DateTime before) {
        Qlite.QueryBuilder select = db.file_transfer.select()
                .with(db.file_transfer.counterpart_id, "=", db.get_jid_id(counterpart))
                .with(db.file_transfer.account_id, "=", account.id)
                .with(db.file_transfer.local_time, ">", (long)after.to_unix())
                .with(db.file_transfer.local_time, "<", (long)before.to_unix())
                .order_by(db.file_transfer.id, "DESC");

        Gee.List<FileTransfer> ret = new ArrayList<FileTransfer>();
        foreach (Qlite.Row row in select) {
            FileTransfer file_transfer = new FileTransfer.from_row(db, row);
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), file_transfer.path ?? file_transfer.file_name));
            try {
                file_transfer.input_stream = file.read();
            } catch (Error e) { }
            ret.insert(0, file_transfer);
        }
        return ret;
    }

    public void add_provider(FileProvider file_provider) {
        file_provider.file_incoming.connect(handle_incomming_file);
    }

    public void add_sender(FileSender file_sender) {
        file_senders.add(file_sender);
        file_sender.upload_available.connect((account) => {
            upload_available(account);
        });
    }

    public void add_incomming_processor(IncommingFileProcessor processor) {
        incomming_processors.add(processor);
    }

    public void add_outgoing_processor(OutgoingFileProcessor processor) {
        outgoing_processors.add(processor);
    }

    public void add_incoming_url_rewriter(IncomingURLRewriter rewriter) {
        incoming_url_rewriters.add(rewriter);
    }

    public void add_outgoing_url_rewriter(OutgoingURLRewriter rewriter) {
        outgoing_url_rewriters.add(rewriter);
    }

    public string rewrite_incoming_url(string url) {
        foreach (IncomingURLRewriter rewriter in incoming_url_rewriters) {
            string? rewritten_url = rewriter.rewrite(url);
            if (rewritten_url != null)
              return rewritten_url;
        }
        return url;
    }

    public string rewrite_outgoing_url(string url, Conversation conversation) {
        foreach (OutgoingURLRewriter rewriter in outgoing_url_rewriters) {
            string? rewritten_url = rewriter.rewrite(conversation, url);
            if (rewritten_url != null)
              return rewritten_url;
        }
        return url;
    }

    private void handle_incomming_file(FileTransfer file_transfer) {
        foreach (IncommingFileProcessor processor in incomming_processors) {
            if (processor.can_process(file_transfer)) {
                processor.process(file_transfer);
            }
        }
        save_file(file_transfer);

        try {
            FileInfo file_info = file_transfer.get_file().query_info("*", FileQueryInfoFlags.NONE);
            file_transfer.mime_type = file_info.get_content_type();
        } catch (Error e) { }

        file_transfer.persist(db);
        received_file(file_transfer);
    }

    private void save_file(FileTransfer file_transfer) {
        try {
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));
            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            os.splice(file_transfer.input_stream, 0);
            os.close();
            file_transfer.state = FileTransfer.State.COMPLETE;
            file_transfer.path = filename;
            file_transfer.input_stream = file.read();
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

}

public interface FileProvider : Object {
    public signal void file_incoming(FileTransfer file_transfer);
}

public interface FileSender : Object {
    public signal void upload_available(Account account);
    public abstract bool is_upload_available(Conversation conversation);
    public abstract bool can_send(Conversation conversation, FileTransfer file_transfer);
    public abstract void send_file(Conversation conversation, FileTransfer file_transfer);
}

public interface IncomingURLRewriter : Object {
    public abstract string? rewrite(string url);
}

public interface OutgoingURLRewriter : Object {
    public abstract string? rewrite(Conversation conversation, string url);
}

public interface IncommingFileProcessor : Object {
    public abstract bool can_process(FileTransfer file_transfer);
    public abstract void process(FileTransfer file_transfer);
}

public interface OutgoingFileProcessor : Object {
    public abstract bool can_process(Conversation conversation, FileTransfer file_transfer);
    public abstract void process(Conversation conversation, FileTransfer file_transfer);
}

}
