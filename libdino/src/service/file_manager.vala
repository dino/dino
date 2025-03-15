using Gdk;
using Gee;

using Xmpp;
using Xmpp.Xep;
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
    private Gee.List<FileMetadataProvider> file_metadata_providers = new ArrayList<FileMetadataProvider>();

    public StatelessFileSharing sfs {
        owned get { return stream_interactor.get_module(StatelessFileSharing.IDENTITY); }
        private set { }
    }

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
        this.add_metadata_provider(new GenericFileMetadataProvider());
        this.add_metadata_provider(new ImageFileMetadataProvider());
    }

    public const int HTTP_PROVIDER_ID = 0;
    public const int SFS_PROVIDER_ID = 2;

    public FileProvider? select_file_provider(FileTransfer file_transfer) {
        bool http_usable = file_transfer.provider == SFS_PROVIDER_ID;
        foreach (FileProvider file_provider in this.file_providers) {
            if (file_transfer.provider == file_provider.get_id()) {
                return file_provider;
            }
            if (http_usable && file_provider.get_id() == HTTP_PROVIDER_ID) {
                return file_provider;
            }
        }
        return null;
    }

    public async HashMap<int, long> get_file_size_limits(Conversation conversation) {
        HashMap<int, long> ret = new HashMap<int, long>();
        foreach (FileSender sender in file_senders) {
            ret[sender.get_id()] = yield sender.get_file_size_limit(conversation);
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

        Xep.FileMetadataElement.FileMetadata metadata = new Xep.FileMetadataElement.FileMetadata();
        foreach (FileMetadataProvider file_metadata_provider in this.file_metadata_providers) {
            if (file_metadata_provider.supports_file(file)) {
                yield file_metadata_provider.fill_metadata(file, metadata);
            }
        }
        file_transfer.file_metadata = metadata;

        try {
            file_transfer.input_stream = yield file.read_async();

            yield save_file(file_transfer);

            stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file(file_transfer);
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
                if (yield sender.can_send(conversation, file_transfer)) {
                    if (file_transfer.encryption == Encryption.NONE || yield sender.can_encrypt(conversation, file_transfer)) {
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

            file_transfer.state = FileTransfer.State.IN_PROGRESS;

            // Update current download progress in the FileTransfer
            LimitInputStream? limit_stream = file_transfer.input_stream as LimitInputStream;
            if (limit_stream == null) {
                limit_stream = new LimitInputStream(file_transfer.input_stream, file_meta.size);
                file_transfer.input_stream = limit_stream;
            }
            if (limit_stream != null) {
                limit_stream.bind_property("retrieved-bytes", file_transfer, "transferred-bytes", BindingFlags.SYNC_CREATE);
            }

            yield file_sender.send_file(conversation, file_transfer, file_send_data, file_meta);
            file_transfer.state = FileTransfer.State.COMPLETE;

        } catch (Error e) {
            warning("Send file error: %s", e.message);
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

    public async void download_file(FileTransfer file_transfer) {
        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(file_transfer.counterpart.bare_jid, file_transfer.account);

        FileProvider? file_provider = this.select_file_provider(file_transfer);

        yield download_file_internal(file_provider, file_transfer, conversation);
    }

    public async bool is_upload_available(Conversation? conversation) {
        if (conversation == null) return false;

        foreach (FileSender file_sender in file_senders) {
            if (yield file_sender.is_upload_available(conversation)) return true;
        }
        return false;
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

    public void add_metadata_provider(FileMetadataProvider file_metadata_provider) {
        file_metadata_providers.add(file_metadata_provider);
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
            FileReceiveData? receive_data = file_provider.get_file_receive_data(file_transfer);
            if (receive_data == null) {
                warning("Don't have download data (yet)");
                return;
            }
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

            // Download and decrypt file
            file_transfer.state = FileTransfer.State.IN_PROGRESS;

            if (file_decryptor != null) {
                file_meta = file_decryptor.prepare_download_file(conversation, file_transfer, receive_data, file_meta);
            }

            InputStream download_input_stream = yield file_provider.download(file_transfer, receive_data, file_meta);
            InputStream input_stream = download_input_stream;
            if (file_decryptor != null) {
                input_stream = yield file_decryptor.decrypt_file(input_stream, conversation, file_transfer, receive_data);
            }

            // Update current download progress in the FileTransfer
            LimitInputStream? limit_stream = download_input_stream as LimitInputStream;
            if (limit_stream != null) {
                limit_stream.bind_property("retrieved-bytes", file_transfer, "transferred-bytes", BindingFlags.SYNC_CREATE);
            }

            // Save file
            string filename = Random.next_int().to_string("%x") + "_" + file_transfer.file_name;
            File file = File.new_for_path(Path.build_filename(get_storage_dir(), filename));

            // libsoup doesn't properly support splicing
            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            uint8[] buffer = new uint8[1024];
            ssize_t read;
            while ((read = yield input_stream.read_async(buffer, Priority.LOW, file_transfer.cancellable)) > 0) {
                buffer.length = (int) read;
                yield os.write_async(buffer, Priority.LOW, file_transfer.cancellable);
                buffer.length = 1024;
            }
            yield input_stream.close_async(Priority.LOW, file_transfer.cancellable);
            yield os.close_async(Priority.LOW, file_transfer.cancellable);

            // Verify the hash of the downloaded file, if it is known
            var supported_hashes = Xep.CryptographicHashes.get_supported_hashes(file_transfer.hashes);
            if (!supported_hashes.is_empty) {
                var checksum_types = new ArrayList<ChecksumType>();
                var hashes = new HashMap<ChecksumType, string>();
                foreach (var hash in supported_hashes) {
                    var checksum_type = Xep.CryptographicHashes.hash_string_to_type(hash.algo);
                    checksum_types.add(checksum_type);
                    hashes[checksum_type] = hash.val;
                }

                var computed_hashes = yield compute_file_hashes(file, checksum_types);
                foreach (var checksum_type in hashes.keys) {
                    if (hashes[checksum_type] != computed_hashes[checksum_type]) {
                        warning("Hash of downloaded file does not equal advertised hash, discarding: %s. %s should be %s, was %s",
                                file_transfer.file_name, checksum_type.to_string(), hashes[checksum_type], computed_hashes[checksum_type]);
                        FileUtils.remove(file.get_path());
                        file_transfer.state = FileTransfer.State.FAILED;
                        return;
                    }
                }
            }

            file_transfer.path = file.get_basename();
            file_transfer.state = FileTransfer.State.COMPLETE;

#if _WIN32 // Add Zone.Identifier so Windows knows this file was downloaded from the internet
            var file_alternate_stream = File.new_for_path(Path.build_filename(get_storage_dir(), filename + ":Zone.Identifier"));
            var os_alternate_stream = file_alternate_stream.create(FileCreateFlags.REPLACE_DESTINATION);
            os_alternate_stream.write("[ZoneTransfer]\r\nZoneId=3".data);
#endif

        } catch (IOError.CANCELLED e) {
            print("cancelled\n");
        } catch (Error e) {
            warning("Error downloading file: %s", e.message);
            if (file_transfer.provider == 0 || file_transfer.provider == FileManager.SFS_PROVIDER_ID) {
                file_transfer.state = FileTransfer.State.NOT_STARTED;
            } else {
                file_transfer.state = FileTransfer.State.FAILED;
            }
        }
    }

    public FileTransfer create_file_transfer_from_provider_incoming(FileProvider file_provider, string info, Jid from, DateTime time, DateTime local_time, Conversation conversation, FileReceiveData receive_data, FileMeta file_meta) {
        FileTransfer file_transfer = new FileTransfer();
        file_transfer.account = conversation.account;
        file_transfer.counterpart = file_transfer.direction == FileTransfer.DIRECTION_RECEIVED ? from : conversation.counterpart;
        if (conversation.type_.is_muc_semantic()) {
            file_transfer.ourpart = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account) ?? conversation.account.bare_jid;
            file_transfer.direction = from.equals(file_transfer.ourpart) ? FileTransfer.DIRECTION_SENT : FileTransfer.DIRECTION_RECEIVED;
        } else {
            if (from.equals_bare(conversation.account.bare_jid)) {
                file_transfer.ourpart = from;
                file_transfer.direction = FileTransfer.DIRECTION_SENT;
            } else {
                file_transfer.ourpart = conversation.account.full_jid;
                file_transfer.direction = FileTransfer.DIRECTION_RECEIVED;
            }
        }
        file_transfer.time = time;
        file_transfer.local_time = local_time;
        file_transfer.provider = file_provider.get_id();
        file_transfer.file_name = file_meta.file_name;
        file_transfer.size = (int)file_meta.size;
        file_transfer.info = info;

        var encryption = file_provider.get_encryption(file_transfer, receive_data, file_meta);
        if (encryption != Encryption.NONE) file_transfer.encryption = encryption;

        foreach (FileDecryptor decryptor in file_decryptors) {
            if (decryptor.can_decrypt_file(conversation, file_transfer, receive_data)) {
                file_transfer.encryption = decryptor.get_encryption();
            }
        }

        return file_transfer;
    }

    private async void handle_incoming_file(FileProvider file_provider, string info, Jid from, DateTime time, DateTime local_time, Conversation conversation, FileReceiveData receive_data, FileMeta file_meta) {
        FileTransfer file_transfer = create_file_transfer_from_provider_incoming(file_provider, info, from, time, local_time, conversation, receive_data, file_meta);
        stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file(file_transfer);

        if (is_sender_trustworthy(file_transfer, conversation)) {
            try {
                yield get_file_meta(file_provider, file_transfer, conversation, receive_data);
            } catch (Error e) {
                warning("Error downloading file: %s", e.message);
                file_transfer.state = FileTransfer.State.FAILED;
            }
            if (file_transfer.size >= 0 && file_transfer.size < 5000000) {
                download_file_internal.begin(file_provider, file_transfer, conversation, (_, res) => {
                    download_file_internal.end(res);
                });
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
            yield os.splice_async(file_transfer.input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);
            file_transfer.state = FileTransfer.State.COMPLETE;
            file_transfer.path = filename;
            file_transfer.input_stream = new LimitInputStream(yield file.read_async(), file_transfer.size);
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

// Get rid of this Error and pass IoErrors instead - DOWNLOAD_FAILED already removed
public errordomain FileReceiveError {
    GET_METADATA_FAILED,
    DECRYPTION_FAILED
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

    public abstract Encryption get_encryption(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta);
    public abstract FileMeta get_file_meta(FileTransfer file_transfer) throws FileReceiveError;
    public abstract FileReceiveData? get_file_receive_data(FileTransfer file_transfer);

    public abstract async FileMeta get_meta_info(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError;
    public abstract async InputStream download(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws IOError;

    public abstract int get_id();
}

public interface FileSender : Object {
    public signal void upload_available(Account account);

    public abstract async bool is_upload_available(Conversation conversation);
    public abstract async long get_file_size_limit(Conversation conversation);
    public abstract async bool can_send(Conversation conversation, FileTransfer file_transfer);
    public abstract async FileSendData? prepare_send_file(Conversation conversation, FileTransfer file_transfer, FileMeta file_meta) throws FileSendError;
    public abstract async void send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) throws FileSendError;
    public abstract async bool can_encrypt(Conversation conversation, FileTransfer file_transfer);

    public abstract int get_id();
    public abstract float get_priority();
}

public interface FileEncryptor : Object {
    public abstract bool can_encrypt_file(Conversation conversation, FileTransfer file_transfer);
    public abstract FileMeta encrypt_file(Conversation conversation, FileTransfer file_transfer) throws FileSendError;
    public abstract FileSendData? preprocess_send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) throws FileSendError;
}

public interface FileDecryptor : Object {
    public abstract Encryption get_encryption();
    public abstract FileReceiveData prepare_get_meta_info(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data);
    public abstract FileMeta prepare_download_file(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta);
    public abstract bool can_decrypt_file(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data);
    public abstract async InputStream decrypt_file(InputStream encrypted_stream, Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data) throws FileReceiveError;
}

}
