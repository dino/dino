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
        private WeakMap<int, FileTransfer> files_by_message_id = new WeakMap<int, FileTransfer>();
        private WeakMap<string, FileTransfer> files_by_message_and_file_id = new WeakMap<string, FileTransfer>();

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

        // Http file transfers store the corresponding message id in the `info` field
        public FileTransfer? get_file_by_message_id(int id, Conversation conversation) {
            FileTransfer? file_transfer = files_by_message_id[id];
            if (file_transfer != null) {
                return file_transfer;
            }

            RowOption row_option = db.file_transfer.select()
                .with(db.file_transfer.info, "=", id.to_string())
                .single()
                .row();

            return create_file_from_row_opt(row_option, conversation);
        }

        public FileTransfer get_files_by_message_and_file_id(int message_id, string file_sharing_id, Conversation conversation) {
            string combined_identifier = message_id.to_string() + file_sharing_id;
            FileTransfer? file_transfer = files_by_message_and_file_id[combined_identifier];

            if (file_transfer == null) {
                RowOption row_option = db.file_transfer.select()
                        .with(db.file_transfer.info, "=", message_id.to_string())
                        .with(db.file_transfer.file_sharing_id, "=", file_sharing_id)
                        .single()
                        .row();

                file_transfer = create_file_from_row_opt(row_option, conversation);
            }

            // There can be collisions in the combined identifier, check it's the correct FileTransfer
            if (file_transfer != null && file_transfer.info == message_id.to_string() && file_transfer.file_sharing_id == file_sharing_id) {
                return file_transfer;
            }
            return null;
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

            if (file_transfer.info != null && file_transfer.info != "") {
                files_by_message_id[int.parse(file_transfer.info)] = file_transfer;

                if (file_transfer.file_sharing_id != null && file_transfer.info != null) {
                    string combined_identifier = file_transfer.info + file_transfer.file_sharing_id;
                    files_by_message_and_file_id[combined_identifier] = file_transfer;
                }
            }
        }
    }
}