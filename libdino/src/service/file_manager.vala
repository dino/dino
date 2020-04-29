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
    private Gee.List<FileEncryptor> file_encryptors = new ArrayList<FileEncryptor>();
    private Gee.List<FileDecryptor> file_decryptors = new ArrayList<FileDecryptor>();
    private Gee.List<FileProvider> file_providers = new ArrayList<FileProvider>();

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

        this.add_provider(new JingleFileProvider(stream_interactor));
        this.add_sender(new JingleFileSender(stream_interactor));
    }

    public HashMap<int, long> get_file_size_limits(Conversation conversation) {
        HashMap<int, long> ret = new HashMap<int, long>();
        foreach (FileSender sender in file_senders) {
            ret[sender.get_id()] = sender.get_file_size_limit(conversation);
        }
        return ret;
    }

    public async void send_file(File file, Conversation conversation) {
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

        try {
            FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
            file_transfer.file_name = file_info.get_display_name();
            file_transfer.mime_type = file_info.get_content_type();
            file_transfer.size = (int)file_info.get_size();
            file_transfer.input_stream = yield file.read_async();

            yield save_file(file_transfer);

            file_transfer.persist(db);
            conversation.last_active = file_transfer.time;
            received_file(file_transfer, conversation);
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
            warning("Error saving outgoing file: %s", e.message);
            return;
        }

        try {
            var file_meta = new FileMeta();
            file_meta.size = file_transfer.size;
            file_meta.mime_type = file_transfer.mime_type;

            FileSender file_sender = null;
            FileEncryptor file_encryptor = null;
            foreach (FileSender sender in file_senders) {
                if (sender.can_send(conversation, file_transfer)) {
                    if (file_transfer.encryption == Encryption.NONE || sender.can_encrypt(conversation, file_transfer)) {
                        file_sender = sender;
                        break;
                    } else {
                        foreach (FileEncryptor encryptor in file_encryptors) {
                            if (encryptor.can_encrypt_file(conversation, file_transfer)) {
                                file_encryptor = encryptor;
                                break;
                            }
                        }
                        if (file_encryptor != null) {
                            file_sender = sender;
                            break;
                        }
                    }
                }
            }

            if (file_sender == null) {
                throw new FileSendError.UPLOAD_FAILED("No sender/encryptor combination available");
            }

            if (file_encryptor != null) {
                file_meta = file_encryptor.encrypt_file(conversation, file_transfer);
            }

            FileSendData file_send_data = yield file_sender.prepare_send_file(conversation, file_transfer, file_meta);

            if (file_encryptor != null) {
                file_send_data = file_encryptor.preprocess_send_file(conversation, file_transfer, file_send_data, file_meta);
            }

            yield file_sender.send_file(conversation, file_transfer, file_send_data, file_meta);

        } catch (Error e) {
            warning("Send file error: %s", e.message);
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

    public async void download_file(FileTransfer file_transfer) {
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(file_transfer.counterpart.bare_jid, file_transfer.account);

        FileProvider? file_provider = null;
        foreach (FileProvider fp in file_providers) {
            if (file_transfer.provider == fp.get_id()) {
                file_provider = fp;
            }
        }

        yield download_file_internal(file_provider, file_transfer, conversation);
    }

    public bool is_upload_available(Conversation? conversation) {
        if (conversation == null) return false;

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
            try {
                FileTransfer file_transfer = new FileTransfer.from_row(db, row, get_storage_dir());
                ret.insert(0, file_transfer);
            } catch (InvalidJidError e) {
                warning("Ignoring file transfer with invalid Jid: %s", e.message);
            }
        }
        return ret;
    }

    public void add_provider(FileProvider file_provider) {
        file_providers.add(file_provider);
        file_provider.file_incoming.connect((info, from, time, local_time, conversation, receive_data, file_meta) => {
            handle_incoming_file.begin(file_provider, info, from, time, local_time, conversation, receive_data, file_meta);
        });
    }

    public void add_sender(FileSender file_sender) {
        file_senders.add(file_sender);
        file_sender.upload_available.connect((account) => {
            upload_available(account);
        });
        file_senders.sort((a, b) => {
            return (int) (b.get_priority() - a.get_priority());
        });
    }

    public void add_file_encryptor(FileEncryptor encryptor) {
        file_encryptors.add(encryptor);
    }

    public void add_file_decryptor(FileDecryptor decryptor) {
        file_decryptors.add(decryptor);
    }

    public bool is_sender_trustworthy(FileTransfer file_transfer, Conversation conversation) {
        if (file_transfer.direction == FileTransfer.DIRECTION_SENT) return true;
        Jid relevant_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(file_transfer.from, conversation.account) ?? conversation.counterpart;
        bool in_roster = stream_interactor.get_module(RosterManager.IDENTITY).get_roster_item(conversation.account, relevant_jid) != null;
        return in_roster;
    }

    private async FileMeta get_file_meta(FileProvider file_provider, FileTransfer file_transfer, Conversation conversation, FileReceiveData receive_data_) throws FileReceiveError {
        FileReceiveData receive_data = receive_data_;
        FileMeta file_meta = file_provider.get_file_meta(file_transfer);

        if (file_meta.size == -1) {
            foreach (FileDecryptor file_decryptor in file_decryptors) {
                if (file_decryptor.can_decrypt_file(conversation, file_transfer, receive_data)) {
                    receive_data = file_decryptor.prepare_get_meta_info(conversation, file_transfer, receive_data);
                    break;
                }
            }

            file_meta = yield file_provider.get_meta_info(file_transfer, receive_data, file_meta);

            file_transfer.size = (int)file_meta.size;
            file_transfer.file_name = file_meta.file_name;
            file_transfer.mime_type = file_meta.mime_type;
        }
        return file_meta;
    }

    private async void download_file_internal(FileProvider file_provider, FileTransfer file_transfer, Conversation conversation) {
        try {
            // Get meta info
            FileReceiveData receive_data = file_provider.get_file_receive_data(file_transfer);
            FileDecryptor? file_decryptor = null;
            foreach (FileDecryptor decryptor in file_decryptors) {
                if (decryptor.can_decrypt_file(conversation, file_transfer, receive_data)) {
                    file_decryptor = decryptor;
                    break;
                }
            }

            if (file_decryptor != null) {
                receive_data = file_decryptor.prepare_get_meta_info(conversation, file_transfer, receive_data);
            }

            FileMeta file_meta = yield get_file_meta(file_provider, file_transfer, conversation, receive_data);


            InputStream? input_stream = null;

            // Download and decrypt file
            file_transfer.state = FileTransfer.State.IN_PROGRESS;

            if (file_decryptor != null) {
                file_meta = file_decryptor.prepare_download_file(conversation, file_transfer, receive_data, file_meta);
            }

            input_stream = yield file_provider.download(file_transfer, receive_data, file_meta);
            if (file_decryptor != null) {
                input_stream = yield file_decryptor.decrypt_file(input_stream, conversation, file_transfer, receive_data);
            }

            // Save file
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));

            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            yield os.splice_async(input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE|OutputStreamSpliceFlags.CLOSE_TARGET);
            file_transfer.path = file.get_basename();
            file_transfer.input_stream = yield file.read_async();

            FileInfo file_info = file_transfer.get_file().query_info("*", FileQueryInfoFlags.NONE);
            file_transfer.mime_type = file_info.get_content_type();

            file_transfer.state = FileTransfer.State.COMPLETE;
        } catch (Error e) {
            warning("Error downloading file: %s", e.message);
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

    private async void handle_incoming_file(FileProvider file_provider, string info, Jid from, DateTime time, DateTime local_time, Conversation conversation, FileReceiveData receive_data, FileMeta file_meta) {
        FileTransfer file_transfer = new FileTransfer();
        file_transfer.account = conversation.account;
        file_transfer.counterpart = file_transfer.direction == FileTransfer.DIRECTION_RECEIVED ? from : conversation.counterpart;
        if (conversation.type_.is_muc_semantic()) {
            file_transfer.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.bare_jid;
            file_transfer.direction = from.equals(file_transfer.ourpart) ? FileTransfer.DIRECTION_SENT : FileTransfer.DIRECTION_RECEIVED;
        } else {
            file_transfer.ourpart = conversation.account.full_jid;
            file_transfer.direction = from.equals_bare(file_transfer.ourpart) ? FileTransfer.DIRECTION_SENT : FileTransfer.DIRECTION_RECEIVED;
        }
        file_transfer.time = time;
        file_transfer.local_time = local_time;
        file_transfer.provider = file_provider.get_id();
        file_transfer.file_name = file_meta.file_name;
        file_transfer.size = (int)file_meta.size;
        file_transfer.info = info;

        file_transfer.persist(db);

        if (is_sender_trustworthy(file_transfer, conversation)) {
            try {
                yield get_file_meta(file_provider, file_transfer, conversation, receive_data);

                if (file_transfer.size >= 0 && file_transfer.size < 5000000) {
                    yield download_file_internal(file_provider, file_transfer, conversation);
                }
            } catch (Error e) {
                warning("Error downloading file: %s", e.message);
                file_transfer.state = FileTransfer.State.FAILED;
            }
        }

        conversation.last_active = file_transfer.time;
        received_file(file_transfer, conversation);
    }

    private async void save_file(FileTransfer file_transfer) throws FileSendError {
        try {
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));
            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            yield os.splice_async(file_transfer.input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE|OutputStreamSpliceFlags.CLOSE_TARGET);
            file_transfer.state = FileTransfer.State.COMPLETE;
            file_transfer.path = filename;
            file_transfer.input_stream = yield file.read_async();
        } catch (Error e) {
            throw new FileSendError.SAVE_FAILED("Saving file error: %s".printf(e.message));
        }
    }
}

public errordomain FileSendError {
    ENCRYPTION_FAILED,
    UPLOAD_FAILED,
    SAVE_FAILED
}

public errordomain FileReceiveError {
    GET_METADATA_FAILED,
    DECRYPTION_FAILED,
    DOWNLOAD_FAILED
}

public class FileMeta {
    public int64 size = -1;
    public string? mime_type = null;
    public string? file_name = null;
    public Encryption encryption = Encryption.NONE;
}

public class HttpFileMeta : FileMeta {
    public Message message;
}

public class FileSendData { }

public class HttpFileSendData : FileSendData {
    public string url_down { get; set; }
    public string url_up { get; set; }
    public HashMap<string, string> headers { get; set; }

    public bool encrypt_message { get; set; default=true; }
}

public class FileReceiveData { }

public class HttpFileReceiveData : FileReceiveData {
    public string url { get; set; }
}

public interface FileProvider : Object {
    public signal void file_incoming(string info, Jid from, DateTime time, DateTime local_time, Conversation conversation, FileReceiveData receive_data, FileMeta file_meta);

    public abstract FileMeta get_file_meta(FileTransfer file_transfer) throws FileReceiveError;
    public abstract FileReceiveData? get_file_receive_data(FileTransfer file_transfer);

    public abstract async FileMeta get_meta_info(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError;
    public abstract async InputStream download(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError;

    public abstract int get_id();
}

public interface FileSender : Object {
    public signal void upload_available(Account account);

    public abstract bool is_upload_available(Conversation conversation);
    public abstract long get_file_size_limit(Conversation conversation);
    public abstract bool can_send(Conversation conversation, FileTransfer file_transfer);
    public abstract async FileSendData? prepare_send_file(Conversation conversation, FileTransfer file_transfer, FileMeta file_meta) throws FileSendError;
    public abstract async void send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) throws FileSendError;
    public abstract bool can_encrypt(Conversation conversation, FileTransfer file_transfer);

    public abstract int get_id();
    public abstract float get_priority();
}

public interface FileEncryptor : Object {
    public abstract bool can_encrypt_file(Conversation conversation, FileTransfer file_transfer);
    public abstract FileMeta encrypt_file(Conversation conversation, FileTransfer file_transfer) throws FileSendError;
    public abstract FileSendData? preprocess_send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) throws FileSendError;
}

public interface FileDecryptor : Object {
    public abstract FileReceiveData prepare_get_meta_info(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data);
    public abstract FileMeta prepare_download_file(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta);
    public abstract bool can_decrypt_file(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data);
    public abstract async InputStream decrypt_file(InputStream encrypted_stream, Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data) throws FileReceiveError;
}

}
