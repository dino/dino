using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class FileManager : StreamInteractionModule, Object {
    public static ModuleIdentity<FileManager> IDENTITY = new ModuleIdentity<FileManager>("file");
    public string id { get { return IDENTITY.id; } }

    public signal void upload_available(Account account);
    public signal void received_file(FileTransfer file_transfer, Conversation conversation);

    private StreamInteractor stream_interactor;
    private Database db;
    private Gee.List<FileSender> file_senders = new ArrayList<FileSender>();
    public Gee.List<IncomingFileProcessor> incoming_processors = new ArrayList<IncomingFileProcessor>();
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

    public async void send_file(string uri, Conversation conversation) {
        FileTransfer file_transfer = new FileTransfer();
        file_transfer.account = conversation.account;
        file_transfer.counterpart = conversation.counterpart;
        file_transfer.ourpart = conversation.account.bare_jid;
        file_transfer.direction = FileTransfer.DIRECTION_SENT;
        file_transfer.time = new DateTime.now_utc();
        file_transfer.local_time = new DateTime.now_utc();
        file_transfer.encryption = conversation.encryption;
        try {
            File file = File.new_for_path(uri);
            FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
            file_transfer.file_name = file_info.get_display_name();
            file_transfer.mime_type = file_info.get_content_type();
            file_transfer.size = (int)file_info.get_size();
            file_transfer.input_stream = yield file.read_async();
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
        yield save_file(file_transfer);

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
        received_file(file_transfer, conversation);
    }

    public bool is_upload_available(Conversation conversation) {
        foreach (FileSender file_sender in file_senders) {
            if (file_sender.is_upload_available(conversation)) return true;
        }
        return false;
    }

    public Gee.List<FileTransfer> get_latest_transfers(Account account, Jid counterpart, int n) {
        Qlite.QueryBuilder select = db.file_transfer.select()
                .with(db.file_transfer.counterpart_id, "=", db.get_jid_id(counterpart))
                .with(db.file_transfer.account_id, "=", account.id)
                .order_by(db.file_transfer.local_time, "DESC")
                .limit(n);
        return get_transfers_from_qry(select);
    }

    public Gee.List<FileTransfer> get_transfers_before(Account account, Jid counterpart, DateTime before, int n) {
        Qlite.QueryBuilder select = db.file_transfer.select()
                .with(db.file_transfer.counterpart_id, "=", db.get_jid_id(counterpart))
                .with(db.file_transfer.account_id, "=", account.id)
                .with(db.file_transfer.local_time, "<", (long)before.to_unix())
                .order_by(db.file_transfer.local_time, "DESC")
                .limit(n);
        return get_transfers_from_qry(select);
    }

    public Gee.List<FileTransfer> get_transfers_after(Account account, Jid counterpart, DateTime after, int n) {
        Qlite.QueryBuilder select = db.file_transfer.select()
                .with(db.file_transfer.counterpart_id, "=", db.get_jid_id(counterpart))
                .with(db.file_transfer.account_id, "=", account.id)
                .with(db.file_transfer.local_time, ">", (long)after.to_unix())
                .limit(n);
        return get_transfers_from_qry(select);
    }

    private Gee.List<FileTransfer> get_transfers_from_qry(Qlite.QueryBuilder select) {
        Gee.List<FileTransfer> ret = new ArrayList<FileTransfer>();
        foreach (Qlite.Row row in select) {
            FileTransfer file_transfer = new FileTransfer.from_row(db, row, get_storage_dir());
            ret.insert(0, file_transfer);
        }
        return ret;
    }

    public void add_provider(FileProvider file_provider) {
        file_provider.file_incoming.connect((file_transfer, conversation) => { handle_incoming_file.begin(file_provider, file_transfer, conversation); });
    }

    public void add_sender(FileSender file_sender) {
        file_senders.add(file_sender);
        file_sender.upload_available.connect((account) => {
            upload_available(account);
        });
    }

    public void add_incoming_processor(IncomingFileProcessor processor) {
        incoming_processors.add(processor);
    }

    public void add_outgoing_processor(OutgoingFileProcessor processor) {
        outgoing_processors.add(processor);
    }

    public bool is_sender_trustworthy(FileTransfer file_transfer, Conversation conversation) {
        Jid relevant_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(file_transfer.from, conversation.account) ?? conversation.counterpart;
        bool in_roster = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(conversation.account, relevant_jid) != null;
        return file_transfer.direction == FileTransfer.DIRECTION_SENT || in_roster;
    }

    private async void handle_incoming_file(FileProvider file_provider, FileTransfer file_transfer, Conversation conversation) {
        if (!is_sender_trustworthy(file_transfer, conversation)) return;

        if (file_transfer.size == -1) {
            yield file_provider.get_meta_info(file_transfer);
        }

        if (file_transfer.size >= 0 && file_transfer.size < 5000000) {
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));
            yield file_provider.download(file_transfer, file);

            try {
                FileInfo file_info = file_transfer.get_file().query_info("*", FileQueryInfoFlags.NONE);
                file_transfer.mime_type = file_info.get_content_type();
            } catch (Error e) { }

            file_transfer.persist(db);
            received_file(file_transfer, conversation);
        }
    }

    private async void save_file(FileTransfer file_transfer) {
        try {
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));
            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            yield os.splice_async(file_transfer.input_stream, 0);
            os.close();
            file_transfer.state = FileTransfer.State.COMPLETE;
            file_transfer.path = filename;
            file_transfer.input_stream = yield file.read_async();
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

}

public interface FileProvider : Object {
    public signal void file_incoming(FileTransfer file_transfer, Conversation conversation);
    public abstract async void get_meta_info(FileTransfer file_transfer);
    public abstract async void download(FileTransfer file_transfer, File file);
}

public interface FileSender : Object {
    public signal void upload_available(Account account);
    public abstract bool is_upload_available(Conversation conversation);
    public abstract bool can_send(Conversation conversation, FileTransfer file_transfer);
    public abstract void send_file(Conversation conversation, FileTransfer file_transfer);
}

public interface IncomingFileProcessor : Object {
    public abstract bool can_process(FileTransfer file_transfer);
    public abstract void process(FileTransfer file_transfer);
}

public interface OutgoingFileProcessor : Object {
    public abstract bool can_process(Conversation conversation, FileTransfer file_transfer);
    public abstract void process(Conversation conversation, FileTransfer file_transfer);
}

}
