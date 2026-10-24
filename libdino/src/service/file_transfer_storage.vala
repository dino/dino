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
        private WeakMap<int, FileTransferGroup> file_group_by_db_id = new WeakMap<int, FileTransferGroup>();
        private WeakMap<int, FileTransferGroup> file_group_by_message_id = new WeakMap<int, FileTransferGroup>();
        private WeakMap<string, FileTransfer> files_by_message_and_file_id = new WeakMap<string, FileTransfer>();
        private HashSet<int> automatically_retried_files = new HashSet<int>();

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

        public void add_file_group(FileTransferGroup file_group) {
            file_group.persist(db);
            cache_file_group(file_group);
        }

        // `conversation` should be provided, otherwise the FileTransfer.ourpart might be wrong
        public FileTransfer? get_file_by_id(int id, Conversation? conversation) {
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

        public FileTransferGroup? get_file_group_by_id(int id, Conversation conversation) {
            FileTransferGroup? file_group = file_group_by_db_id[id];
            if (file_group != null) {
                return file_group;
            }

            RowOption row_option = db.file_transfer_group.select().with(db.file_transfer_group.id, "=", id).row();
            return row_option.is_present() ? create_file_group_from_row(row_option.inner, conversation) : null;
        }

        public FileTransferGroup get_file_group_by_message_id(int id, Conversation conversation) {
            FileTransferGroup? file_group = file_group_by_message_id[id];
            if (file_group != null) {
                return file_group;
            }

            foreach (Row row in db.file_transfer_group.select().with(db.file_transfer_group.message_id, "=", id)) {
                return create_file_group_from_row(row, conversation);
            }

            return null;
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

        private FileTransfer? create_file_from_row_opt(RowOption row_opt, Conversation? conversation) {
            if (!row_opt.is_present()) return null;

            try {
                FileTransfer file_transfer = new FileTransfer.from_row(db, row_opt.inner, FileManager.get_storage_dir());

                if (conversation != null && conversation.type_.is_muc_semantic()) {
                    file_transfer.ourpart = conversation.counterpart.with_resource(file_transfer.ourpart.resourcepart);
                }

                cache_file(file_transfer);
                return file_transfer;
            } catch (InvalidJidError e) {
                warning("Got file transfer with invalid Jid: %s", e.message);
            }
            return null;
        }

        public void recover_incomplete_file(FileTransfer file_transfer) {
            if (file_transfer.direction != FileTransfer.DIRECTION_RECEIVED) return;

            if (file_transfer.state != FileTransfer.State.IN_PROGRESS) {
                File? partial_file = file_transfer.get_partial_file();
                if (partial_file != null) FileUtils.remove(partial_file.get_path());
            }

            if (file_transfer.state == FileTransfer.State.COMPLETE) {
                File? file = file_transfer.get_file();
                bool valid = file != null && file.query_exists();
                int64 expected_size = stream_interactor.get_module(FileManager.IDENTITY).get_expected_file_size(file_transfer);
                if (valid && expected_size >= 0) {
                    try {
                        FileInfo file_info = file.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
                        valid = file_info.get_size() == expected_size;
                    } catch (Error e) {
                        valid = false;
                    }
                }
                if (valid) return;

                if (file != null) FileUtils.remove(file.get_path());
                file_transfer.state = FileTransfer.State.NOT_STARTED;
            }

            if (file_transfer.state == FileTransfer.State.NOT_STARTED && file_transfer.path != null &&
                    file_transfer.id != -1 && automatically_retried_files.add(file_transfer.id)) {
                Idle.add_once(() => {
                    if (file_transfer.state != FileTransfer.State.NOT_STARTED || file_transfer.path == null) return;
                    stream_interactor.get_module(FileManager.IDENTITY).download_file.begin(file_transfer);
                });
            }
        }

        private FileTransferGroup? create_file_group_from_row(Row file_transfer_group_row, Conversation conversation) {
            QueryBuilder query = db.file_transfer_group_file_transfer.select()
                    .with(db.file_transfer_group_file_transfer.file_transfer_group_id, "=", file_transfer_group_row[db.file_transfer_group.id]);
            var file_transfers = new ArrayList<FileTransfer>();
            foreach (Qlite.Row row in query) {
                FileTransfer file_transfer = get_file_by_id(row[db.file_transfer_group_file_transfer.file_transfer_id], conversation);
                file_transfers.add(file_transfer);
            }
            if (file_transfers.size == 0) return null;

            FileTransferGroup file_group = new FileTransferGroup.from_row(db, file_transfer_group_row, file_transfers);
            cache_file_group(file_group);
            return file_group;
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

        private void cache_file_group(FileTransferGroup file_group) {
            file_group_by_db_id[file_group.id] = file_group;
//            file_group_by_message_id[file_group.message_id] = file_group;
        }
    }
}