using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class FileManager : StreamInteractionModule, Object {
    public static ModuleIdentity<FileManager> IDENTITY = new ModuleIdentity<FileManager>("file");
    public string id { get { return IDENTITY.id; } }

    public signal void received_file(FileTransfer file_transfer);

    private StreamInteractor stream_interactor;
    private Database db;
    private Gee.List<FileTransfer> file_transfers = new ArrayList<FileTransfer>();

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

    public void add_provider(Plugins.FileProvider file_provider) {
        file_provider.file_incoming.connect((file_transfer) => {
            file_transfers.add(file_transfer);
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            file_transfer.file_name = filename;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));
            try {
                OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
                os.splice(file_transfer.input_stream, 0);
                os.close();
                file_transfer.state = FileTransfer.State.COMPLETE;
            } catch (Error e) {
                file_transfer.state = FileTransfer.State.FAILED;
            }
            file_transfer.persist(db);
            file_transfer.input_stream = file.read();
            received_file(file_transfer);
        });
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
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), file_transfer.file_name));
            file_transfer.input_stream = file.read();
            ret.insert(0, file_transfer);
        }
        return ret;
    }

}

}
