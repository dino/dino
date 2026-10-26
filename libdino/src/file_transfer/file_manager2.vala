using Gdk;
using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

namespace Dino {

    public class FileManager2 : StreamInteractionModule, Object {
        public static ModuleIdentity<FileManager2> IDENTITY = new ModuleIdentity<FileManager2>("file2");
        public string id { get { return IDENTITY.id; } }

        public signal void received_file(FileTransfer file_group, Conversation conversation);
        public signal void received_file_group(FileTransferGroup file_group, Conversation conversation);

        private StreamInteractor stream_interactor;
        private Database db;

        public const int HTTP_PROVIDER_ID = 0;
        public const int SFS_PROVIDER_ID = 2;

        public StatelessFileSharing sfs {
            owned get { return stream_interactor.get_module(StatelessFileSharing.IDENTITY); }
            private set {}
        }

        public FileManager fm {
            owned get { return stream_interactor.get_module(FileManager.IDENTITY); }
            private set {}
        }

        public HttpFileTransfers http_ft = null;

        public static void start(StreamInteractor stream_interactor, Database db) {
            FileManager2 m = new FileManager2(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        public static string get_storage_dir() {
            return Path.build_filename(Dino.get_storage_dir(), "files");
        }

        private FileManager2(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;
            this.http_ft = new HttpFileTransfers(stream_interactor, db);

            stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new ReceivedMessageListener(this));
        }

        public async void send_files(Gee.List<File> files, Conversation conversation) {
            bool can_reference_element = conversation.type_ == Conversation.Type.CHAT || (
                // The stable stanza ID XEP is not clear about an announcing MUC having to attach stanza-ids, thus we also check for MAM, which requires this.
                stream_interactor.get_module(EntityInfo.IDENTITY).has_feature_cached(conversation.account, conversation.counterpart, Xep.UniqueStableStanzaIDs.NS_URI) &&
                stream_interactor.get_module(EntityInfo.IDENTITY).has_feature_cached(conversation.account, conversation.counterpart, Xmpp.MessageArchiveManagement.NS_URI)
            );

            // Share unencrypted files via SFS (only if we'll be able to reference messages)
            if (conversation.encryption == Encryption.NONE && can_reference_element) {
                yield send_unencrypted_sfs(files, conversation);
            } else {
                foreach (File file in files) {
                    fm.send_file(file, conversation);
                }
            }
        }

//        private async void send_file(File file, Conversation conversation) {
//            FileTransfer file_transfer = yield create_init_outgoing_file_transfer(file, conversation);
//            received_file(file_transfer, conversation);
//
//            try {
//                string file_name = file_transfer.file_name;
//                int64 file_size = file_transfer.size;
//                FileContentType? file_content_type = file_transfer.content_type;
//                print(@"$(file_name) $(file_size) $(file_content_type.get_mime_type())\n");
//
//                Omemo.OmemoHttpFileMeta? encrypted_file_meta = null;
//
//                if (conversation.encryption == Encryption.OMEMO) {
//                    encrypted_file_meta = omemo_file_encryption.encrypt_file(conversation, file_transfer);
////                    file_name = encrypted_file_meta.file_name;
//                    file_size = encrypted_file_meta.size;
//                    file_content_type = encrypted_file_meta.content_type;
//                }
//                HttpFileSlot? upload_slot = yield http_ft.request_upload_slot(conversation.account, file_name, file_size, file_content_type);
//                yield http_ft.upload(file_transfer, upload_slot.url_up, upload_slot.headers, file_size);
//
//                string url_down = upload_slot.url_down;
//
//                if (conversation.encryption == Encryption.OMEMO) {
//                    url_down = omemo_file_encryption.generate_aesgcm_url(upload_slot.url_down, encrypted_file_meta.iv, encrypted_file_meta.key);
//                }
//
//                // Update current upload progress in the FileTransfer
//                LimitInputStream? limit_stream = file_transfer.input_stream as LimitInputStream;
//                if (limit_stream == null) {
//                    limit_stream = new LimitInputStream(file_transfer.input_stream, file_size);
//                    file_transfer.input_stream = limit_stream;
//                }
//                if (limit_stream != null) {
//                    limit_stream.bind_property("retrieved-bytes", file_transfer, "transferred-bytes", BindingFlags.SYNC_CREATE);
//                }
//
//                file_transfer.state = FileTransfer.State.IN_PROGRESS;
//
//                http_ft.send_http_file_message(conversation, file_transfer, url_down, true); // TODO true
//
//                file_transfer.state = FileTransfer.State.COMPLETE;
//            } catch (Error e) {
//                warning("Send file error: %s", e.message);
//                file_transfer.state = FileTransfer.State.FAILED;
//            }
//        }

        private async void send_unencrypted_sfs(Gee.List<File> files, Conversation conversation) {
            FileTransferGroup file_transfer_group = new FileTransferGroup();
            foreach (var file in files) {
                var file_transfer = yield create_init_outgoing_file_transfer(file, conversation);
                file_transfer_group.file_transfers.add(file_transfer);
            }

            stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file_group(file_transfer_group);
            received_file_group(file_transfer_group, conversation);

            // TODO message-id not known here -> not cached by it
            var sfs_message = yield sfs.announce_files(file_transfer_group, conversation);

            foreach (var file_transfer in file_transfer_group.file_transfers) {
                upload_unencrypted_sfs_file.begin(file_transfer, conversation, sfs_message);
            }
        }

        private async void upload_unencrypted_sfs_file(FileTransfer file_transfer, Conversation conversation, Message sfs_message) {
            var upload_slot_data = yield http_ft.request_upload_slot(conversation.account, file_transfer.server_file_name, file_transfer.size, file_transfer.content_type);

            // Upload file
            yield http_ft.upload(file_transfer, upload_slot_data.url_up, upload_slot_data.headers, file_transfer.size);

            // Wait until we know the server id of the file share message (in MUCs; we get that from the reflected message)
            if (conversation.type_.is_muc_semantic()) {
                if (sfs_message.server_id == null) {
                    ulong server_id_notify_id = sfs_message.notify["server-id"].connect(() => {
                        Idle.add(upload_unencrypted_sfs_file.callback);
                    });
                    yield;
                    sfs_message.disconnect(server_id_notify_id);
                }
            }

            file_transfer.sfs_sources.add(new Xep.StatelessFileSharing.HttpSource() { url=upload_slot_data.url_down } );

            string attach_to_id = stream_interactor.get_module(MessageStorage.IDENTITY).get_reference_id(sfs_message, conversation);
            sfs.attach_source(file_transfer, conversation, upload_slot_data.url_down, attach_to_id);
        }

        private async FileTransfer? create_init_outgoing_file_transfer(File file, Conversation conversation) {
            FileTransfer file_transfer = yield create_outgoing_file_transfer(file, conversation);

            try {
                file_transfer.input_stream = yield file.read_async();
                yield save_file(file_transfer);

                stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file(file_transfer);
                conversation.last_active = file_transfer.time;

                return file_transfer;
            } catch (Error e) {
                file_transfer.state = FileTransfer.State.FAILED;
                warning("Error saving outgoing file: %s", e.message);
                return null;
            }
        }

        private async FileTransfer create_outgoing_file_transfer(File file, Conversation conversation) {
            FileTransfer file_transfer = new FileTransfer();
            file_transfer.account = conversation.account;
            file_transfer.counterpart = conversation.counterpart;
            if (conversation.type_.is_muc_semantic()) {
                file_transfer.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.bare_jid;
            } else {
                file_transfer.ourpart = conversation.account.full_jid;
            }
            file_transfer.direction = FileTransfer.DIRECTION_SENT;
            file_transfer.time = new DateTime.now_utc();
            file_transfer.local_time = new DateTime.now_utc();
            file_transfer.encryption = conversation.encryption;

            Xep.FileMetadataElement.FileMetadata metadata = new Xep.FileMetadataElement.FileMetadata();
            foreach (FileMetadataProvider file_metadata_provider in fm.file_metadata_providers) {
                if (file_metadata_provider.supports_file(file)) {
                    yield file_metadata_provider.fill_metadata(file, metadata);
                }
            }
            file_transfer.file_metadata = metadata;
            return file_transfer;
        }

        public async void save_file(FileTransfer file_transfer) throws FileSendError {
            try {
                string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
                File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));
                OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
                yield os.splice_async(file_transfer.input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);
                file_transfer.state = FileTransfer.State.COMPLETE;
                file_transfer.path = filename;
                file_transfer.input_stream = new LimitInputStream(yield file.read_async(), file_transfer.size);
            } catch (Error e) {
                throw new FileSendError.SAVE_FAILED("Saving file error: %s".printf(e.message));
            }
        }

        public bool is_sender_trustworthy(FileTransfer file_transfer, Conversation conversation) {
            if (file_transfer.direction == FileTransfer.DIRECTION_SENT) return true;

            Jid relevant_jid = conversation.counterpart;
            if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                relevant_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(file_transfer.from, conversation.account);
            }
            if (relevant_jid == null) return false;

            bool in_roster = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(conversation.account, relevant_jid) != null;
            return in_roster;
        }

        private class ReceivedMessageListener : MessageListener {

            public string[] after_actions_const = new string[]{ "STORE" };
            public override string action_group { get { return "MESSAGE_REINTERPRETING"; } }
            public override string[] after_actions { get { return after_actions_const; } }

            private FileManager2 outer;
            private StreamInteractor stream_interactor;

            public ReceivedMessageListener(FileManager2 outer) {
                this.outer = outer;
                this.stream_interactor = outer.stream_interactor;
            }

            public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
                bool is_sfs = yield outer.sfs.try_process_sfs(message, stanza, conversation);
                if (is_sfs) return true;

                bool is_http = outer.http_ft.try_parse_http_transfer(message, stanza, conversation);
                if (is_http) return true;

                return false;
            }
        }
    }
}