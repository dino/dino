using Xmpp;
using Gee;
using Qlite;

using Dino.Entities;

namespace Dino {

    public class FileTransferStorage : StreamInteractionModule, Object {
        public static ModuleIdentity<FileTransferStorage> IDENTITY = new ModuleIdentity<FileTransferStorage>("file_store");
        public string id { get { return IDENTITY.id; } }

        private StreamInteractor stream_interactor;
        private Database db;

        private WeakMap<int, FileTransfer> files_by_db_id = new WeakMap<int, FileTransfer>();

        public static void start(StreamInteractor stream_interactor, Database db) {
            FileTransferStorage m = new FileTransferStorage(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        private FileTransferStorage(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;
        }

        public void add_file(FileTransfer file_transfer) {
            file_transfer.persist(db);
            cache_file(file_transfer);
        }

        public FileTransfer? get_file_by_id(int id, Conversation conversation) {
            FileTransfer? file_transfer = files_by_db_id[id];
            if (file_transfer != null) {
                return file_transfer;
            }

            RowOption row_option = db.file_transfer.select().with(db.file_transfer.id, "=", id).row();

            return create_file_from_row_opt(row_option, conversation);
        }

        private FileTransfer? create_file_from_row_opt(RowOption row_opt, Conversation conversation) {
            if (!row_opt.is_present()) return null;

            try {
                FileTransfer file_transfer = new FileTransfer.from_row(db, row_opt.inner, FileManager.get_storage_dir());

                if (conversation.type_.is_muc_semantic()) {
                    file_transfer.ourpart = conversation.counterpart.with_resource(file_transfer.ourpart.resourcepart);
                }

                cache_file(file_transfer);
                return file_transfer;
            } catch (InvalidJidError e) {
                warning("Got file transfer with invalid Jid: %s", e.message);
            }
            return null;
        }

        private void cache_file(FileTransfer file_transfer) {
            files_by_db_id[file_transfer.id] = file_transfer;
        }
    }
}