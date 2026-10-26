using Gdk;
using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

public class Dino.StatelessFileSharing : StreamInteractionModule, Object {
    public static ModuleIdentity<StatelessFileSharing> IDENTITY = new ModuleIdentity<StatelessFileSharing>("sfs");
    public string id { get { return IDENTITY.id; } }

    public const int SFS_PROVIDER_ID = 2;

    public StreamInteractor stream_interactor {
        owned get { return Application.get_default().stream_interactor; }
        private set { }
    }

    public FileManager fm {
        owned get { return stream_interactor.get_module(FileManager.IDENTITY); }
        private set { }
    }

    public FileManager2 fm2 {
        owned get { return stream_interactor.get_module(FileManager2.IDENTITY); }
        private set { }
    }

    public Database db {
        owned get { return Application.get_default().db; }
        private set { }
    }

    private StatelessFileSharing(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.get_module(MessageProcessor.IDENTITY).build_message_stanza.connect(check_add_sfs_element);
    }

    public static void start(StreamInteractor stream_interactor, Database db) {
        StatelessFileSharing m = new StatelessFileSharing(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public async Entities.Message announce_files(FileTransferGroup file_group, Conversation conversation) {
        Entities.Message file_share_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(null, conversation);
        stream_interactor.get_module(MessageStorage.IDENTITY).add_message(file_share_message, conversation);
        file_group.message_id = file_share_message.id;

        foreach (var file_transfer in file_group.file_transfers) {
            file_transfer.provider = SFS_PROVIDER_ID;
            file_transfer.info = file_share_message.id.to_string();
            file_transfer.file_sharing_id = Xmpp.random_uuid();
        }

        stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(file_share_message, conversation);

        return file_share_message;
    }

    public async void attach_source(FileTransfer file_transfer, Conversation conversation, string http_url, string to_sfs_id) {
        MessageStanza stanza = new MessageStanza() { to = conversation.counterpart, type_ = conversation.type_ == GROUPCHAT ? MessageStanza.TYPE_GROUPCHAT : MessageStanza.TYPE_CHAT };
        stanza.body = http_url;
        Xep.OutOfBandData.add_url_to_message(stanza, http_url);
        var sources = new ArrayList<Xep.StatelessFileSharing.Source>();
        sources.add(new Xep.StatelessFileSharing.HttpSource() { url = http_url });
        Xep.StatelessFileSharing.set_sfs_attachment(stanza, to_sfs_id, file_transfer.file_sharing_id, sources);

        var stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) throw new FileSendError.UPLOAD_FAILED("No stream");

        stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, stanza);
    }

    public async bool try_process_sfs(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
        Gee.List<Xep.StatelessFileSharing.FileShare> file_shares = Xep.StatelessFileSharing.get_file_shares(stanza);
        if (file_shares != null) {
            // For now, only accept file shares that have at least one supported hash
            foreach (Xep.StatelessFileSharing.FileShare file_share in file_shares) {
                if (!Xep.CryptographicHashes.has_supported_hashes(file_share.metadata.hashes)) {
                    return false;
                }
            }

            if (file_shares.size > 0) {
                var file_transfers = new ArrayList<FileTransfer>();
                foreach (Xep.StatelessFileSharing.FileShare file_share in file_shares) {
                    var file_transfer = yield create_incoming_file_transfer(conversation, message, file_share.id, file_share.metadata, file_share.sources);
                    file_transfers.add(file_transfer);
                    stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file(file_transfer);
                }
                var file_group = new FileTransferGroup() {
                    message_id = message.id,
                    file_transfers = file_transfers
                };
                stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file_group(file_group);

                fm2.received_file_group(file_group, conversation);
            }
            return true;
        }

        var source_attachments = Xep.StatelessFileSharing.get_source_attachments(stanza);
        if (source_attachments != null) {
            foreach (var source_attachment in source_attachments) {
                on_received_sources(stanza.from, conversation, source_attachment.to_message_id, source_attachment.to_file_transfer_id, source_attachment.sources);
                return true;
            }
        }

        // Don't process messages that are fallback for legacy clients
        if (Xep.StatelessFileSharing.is_sfs_fallback_message(stanza)) {
            return true;
        }

        return false;
    }

    public async FileTransfer create_incoming_file_transfer(Conversation conversation, Message message, string? file_sharing_id, Xep.FileMetadataElement.FileMetadata metadata, Gee.List<Xep.StatelessFileSharing.Source>? sources) {
        FileTransfer file_transfer = new FileTransfer();
        file_transfer.file_sharing_id = file_sharing_id;
        file_transfer.account = message.account;
        file_transfer.counterpart = message.counterpart;
        file_transfer.ourpart = message.ourpart;
        file_transfer.direction = message.direction;
        file_transfer.time = message.time;
        file_transfer.local_time = message.local_time;
        file_transfer.provider = SFS_PROVIDER_ID;
        file_transfer.file_metadata = metadata;
        file_transfer.info = message.id.to_string();
        if (sources != null) {
            file_transfer.sfs_sources = sources;
        }

        stream_interactor.get_module(FileTransferStorage.IDENTITY).add_file(file_transfer);

        conversation.last_active = file_transfer.time;

        return file_transfer;
    }

    public void on_received_sources(Jid from, Conversation conversation, string attach_to_message_id, string? attach_to_file_id, Gee.List<Xep.StatelessFileSharing.Source> sources) {
        Message? message = stream_interactor.get_module(MessageStorage.IDENTITY).get_message_by_referencing_id(attach_to_message_id, conversation);
        if (message == null) return;

        FileTransfer? file_transfer = null;
        if (attach_to_file_id != null) {
            file_transfer = stream_interactor.get_module(FileTransferStorage.IDENTITY).get_files_by_message_and_file_id(message.id, attach_to_file_id, conversation);
        } else {
            file_transfer = stream_interactor.get_module(FileTransferStorage.IDENTITY).get_file_by_message_id(message.id, conversation);
        }
        if (file_transfer == null) return;

        // "If no <hash/> is provided or the <hash/> elements provided use unsupported algorithms, receiving clients MUST ignore
        // any attached sources from other senders and only obtain the file from the sources announced by the original sender."
        // For now we don't allow source attachments for file shares without hashes. TODO extend this
        if (Xep.CryptographicHashes.get_supported_hashes(file_transfer.hashes).is_empty) {
            warning("Ignoring sfs source: No known file hashes");
            return;
        }

        foreach (var source in sources) {
            file_transfer.add_sfs_source(source);
        }

        if (fm2.is_sender_trustworthy(file_transfer, conversation) && file_transfer.state == FileTransfer.State.NOT_STARTED && file_transfer.size >= 0 && file_transfer.size < 5000000) {
            fm.download_file(file_transfer);
        }
    }

    private void check_add_sfs_element(Entities.Message message, Xmpp.MessageStanza message_stanza, Conversation conversation) {
        if (message.encryption != Encryption.NONE) return;

        // Check if it's a FileTransferGroup
        FileTransferGroup? file_group = stream_interactor.get_module(FileTransferStorage.IDENTITY).get_file_group_by_message_id(message.id, conversation);
        if (file_group != null)  {
            print("check added file group\n");
            foreach (FileTransfer file_transfer in file_group.file_transfers) {
                Xep.StatelessFileSharing.set_sfs_element(message_stanza, file_transfer.file_sharing_id, file_transfer.file_metadata, file_transfer.sfs_sources);
            }

            Xep.MessageProcessingHints.set_message_hint(message_stanza, Xep.MessageProcessingHints.HINT_STORE);

            return;
        }

    }
}