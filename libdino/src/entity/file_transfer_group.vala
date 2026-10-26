using Xmpp;

namespace Dino.Entities {

    public class FileTransferGroup : Object {
        public Gee.ArrayList<FileTransfer> file_transfers = new Gee.ArrayList<FileTransfer>();

        public int id { get; set; default=-1; }
        public int message_id { get; set; default=-1; }

        private Database? db;

        public FileTransferGroup.from_row(Database db, Qlite.Row row, Gee.ArrayList<FileTransfer> file_transfers) throws InvalidJidError {
            this.db = db;
            this.file_transfers = file_transfers;

            id = row[db.file_transfer_group.id];
            message_id = row[db.file_transfer_group.message_id];

            notify.connect(on_update);
        }

        public void persist(Database db) {
            if (id != -1) return;

            this.db = db;

            id = (int) db.file_transfer_group.insert()
                    .value(db.file_transfer_group.message_id, message_id)
                    .perform();


            Qlite.InsertBuilder builder = db.file_transfer_group_file_transfer.insert();
            foreach (FileTransfer file_transfer in file_transfers) {
                db.file_transfer_group_file_transfer.insert()
                        .value(db.file_transfer_group_file_transfer.file_transfer_group_id, id)
                        .value(db.file_transfer_group_file_transfer.file_transfer_id, file_transfer.id)
                        .perform();
            }

            notify.connect(on_update);
        }

        private void on_update(Object o, ParamSpec sp) {
            Qlite.UpdateBuilder update_builder = db.file_transfer_group.update().with(db.file_transfer_group.id, "=", id);
            switch (sp.name) {
                case "message-id":
                    update_builder.set(db.file_transfer_group.message_id, message_id); break;
            }
            update_builder.perform();
        }
    }
}