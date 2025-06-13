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

    public FileManager file_manager {
        owned get { return stream_interactor.get_module(FileManager.IDENTITY); }
        private set { }
    }

    public Database db {
        owned get { return Application.get_default().db; }
        private set { }
    }

    private StatelessFileSharing(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(new ReceivedMessageListener(this));
    }

    public static void start(StreamInteractor stream_interactor, Database db) {
        StatelessFileSharing m = new StatelessFileSharing(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public async void create_file_transfer(Conversation conversation, Message message, string? file_sharing_id, Xep.FileMetadataElement.FileMetadata metadata, Gee.List<Xep.StatelessFileSharing.Source>? sources) {
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
        file_manager.received_file(file_transfer, conversation);
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
        // For now we only allow the original sender
        if (from.equals(file_transfer.from) && Xep.CryptographicHashes.get_supported_hashes(file_transfer.hashes).is_empty) {
            warning("Ignoring sfs source: Not from original sender or no known file hashes");
            return;
        }

        foreach (var source in sources) {
            file_transfer.add_sfs_source(source);
        }

        if (file_manager.is_sender_trustworthy(file_transfer, conversation) && file_transfer.state == FileTransfer.State.NOT_STARTED && file_transfer.size >= 0 && file_transfer.size < 5000000) {
            file_manager.download_file(file_transfer);
        }
    }

    /*
    public async void create_sfs_for_legacy_transfer(FileProvider file_provider, string info, Jid from, DateTime time, DateTime local_time, Conversation conversation, FileReceiveData receive_data, FileMeta file_meta) {
        FileTransfer file_transfer = file_manager.create_file_transfer_from_provider_incoming(file_provider, info, from, time, local_time, conversation, receive_data, file_meta);

        HttpFileReceiveData? http_receive_data = receive_data as HttpFileReceiveData;
        if (http_receive_data == null) return;

        var sources = new ArrayList<Xep.StatelessFileSharing.Source>();
        Xep.StatelessFileSharing.HttpSource source = new Xep.StatelessFileSharing.HttpSource();
        source.url = http_receive_data.url;
        sources.add(source);

        if (file_manager.is_jid_trustworthy(from, conversation)) {
            try {
                file_meta = yield file_provider.get_meta_info(file_transfer, http_receive_data, file_meta);
            } catch (Error e) {
                warning("Http meta request failed: %s", e.message);
            }
        }

        var metadata = new Xep.FileMetadataElement.FileMetadata();
        metadata.size = file_meta.size;
        metadata.name = file_meta.file_name;
        metadata.mime_type = file_meta.mime_type;

        file_transfer.provider = SFS_PROVIDER_ID;
        file_transfer.file_metadata = metadata;
        file_transfer.sfs_sources = sources;
    }
    */

    private class ReceivedMessageListener : MessageListener {

        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return "MESSAGE_REINTERPRETING"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StatelessFileSharing outer;
        private StreamInteractor stream_interactor;

        public ReceivedMessageListener(StatelessFileSharing outer) {
            this.outer = outer;
            this.stream_interactor = outer.stream_interactor;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            Gee.List<Xep.StatelessFileSharing.FileShare> file_shares = Xep.StatelessFileSharing.get_file_shares(stanza);
            if (file_shares != null) {
                // For now, only accept file shares that have at least one supported hash
                foreach (Xep.StatelessFileSharing.FileShare file_share in file_shares) {
                    if (!Xep.CryptographicHashes.has_supported_hashes(file_share.metadata.hashes)) {
                        return false;
                    }
                }
                foreach (Xep.StatelessFileSharing.FileShare file_share in file_shares) {
                    outer.create_file_transfer(conversation, message, file_share.id, file_share.metadata, file_share.sources);
                }
                return true;
            }

            var source_attachments = Xep.StatelessFileSharing.get_source_attachments(stanza);
            if (source_attachments != null) {
                foreach (var source_attachment in source_attachments) {
                    outer.on_received_sources(stanza.from, conversation, source_attachment.to_message_id, source_attachment.to_file_transfer_id, source_attachment.sources);
                    return true;
                }
            }

            // Don't process messages that are fallback for legacy clients
            if (Xep.StatelessFileSharing.is_sfs_fallback_message(stanza)) {
                return true;
            }

            return false;
        }
    }
}