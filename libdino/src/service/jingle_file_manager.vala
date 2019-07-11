using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class JingleFileManager : StreamInteractionModule, FileProvider, FileSender, Object {
    public static ModuleIdentity<JingleFileManager> IDENTITY = new ModuleIdentity<JingleFileManager>("jingle_files");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private HashMap<string, Xmpp.Xep.JingleFileTransfer.FileTransfer> file_transfers
        = new HashMap<string, Xmpp.Xep.JingleFileTransfer.FileTransfer>();

    public static void start(StreamInteractor stream_interactor) {
        JingleFileManager m = new JingleFileManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private JingleFileManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(FileManager.IDENTITY).add_sender(this);
        stream_interactor.get_module(FileManager.IDENTITY).add_provider(this);
        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.JingleFileTransfer.Module.IDENTITY).file_incoming.connect((stream, jingle_file_transfer) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jingle_file_transfer.peer.bare_jid, account);
            if (conversation == null) {
                // TODO(hrxi): What to do?
                return;
            }
            string id = random_uuid();

            FileTransfer file_transfer = new FileTransfer();
            file_transfer.account = account;
            file_transfer.counterpart = jingle_file_transfer.peer.bare_jid;
            file_transfer.ourpart = account.bare_jid;
            file_transfer.encryption = Encryption.NONE;
            file_transfer.time = new DateTime.now_utc();
            file_transfer.local_time = new DateTime.now_utc();
            file_transfer.direction = FileTransfer.DIRECTION_RECEIVED;
            file_transfer.file_name = jingle_file_transfer.file_name;
            file_transfer.size = (int)jingle_file_transfer.size;
            file_transfer.state = FileTransfer.State.NOT_STARTED;
            file_transfer.provider = 1;
            file_transfer.info = id;
            file_transfers[id] = jingle_file_transfer;

            file_incoming(file_transfer, conversation);
        });
    }

    async void get_meta_info(FileTransfer file_transfer) {
        // In Jingle, all the metadata is provided up-front, so there's no more
        // metadata to get.
    }
    async void download(FileTransfer file_transfer, File file_) {
        // TODO(hrxi) What should happen if `stream == null`?
        XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        Xmpp.Xep.JingleFileTransfer.FileTransfer jingle_file_transfer = file_transfers[file_transfer.info];
        jingle_file_transfer.accept(stream);
        file_transfer.input_stream = jingle_file_transfer.stream;

        // TODO(hrxi): BEGIN: Copied from plugins/http-files/src/file_provider.vala
        foreach (IncomingFileProcessor processor in stream_interactor.get_module(FileManager.IDENTITY).incoming_processors) {
            if (processor.can_process(file_transfer)) {
                processor.process(file_transfer);
            }
        }

        // TODO(hrxi): should this be an &&?
        File file = file_;
        if (file_transfer.encryption == Encryption.PGP || file.get_path().has_suffix(".pgp")) {
            file = File.new_for_path(file.get_path().substring(0, file.get_path().length - 4));
        }
        // TODO(hrxi): END: Copied from plugins/http-files/src/file_provider.vala

        try {
            OutputStream os = file.create(FileCreateFlags.REPLACE_DESTINATION);
            yield os.splice_async(file_transfer.input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE|OutputStreamSpliceFlags.CLOSE_TARGET);
            file_transfer.path = file.get_basename();
            file_transfer.input_stream = yield file.read_async();

            file_transfer.state = FileTransfer.State.COMPLETE;
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
            return;
        }
    }

    public bool is_upload_available(Conversation conversation) {
        // TODO(hrxi) Here and in `send_file`: What should happen if `stream == null`?
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        foreach (Jid full_jid in stream.get_flag(Presence.Flag.IDENTITY).get_resources(conversation.counterpart)) {
            if (stream.get_module(Xep.JingleFileTransfer.Module.IDENTITY).is_available(stream, full_jid)) {
                return true;
            }
        }
        return false;
    }
    public bool can_send(Conversation conversation, FileTransfer file_transfer) {
        return file_transfer.encryption != Encryption.OMEMO;
    }
    public void send_file(Conversation conversation, FileTransfer file_transfer) {
        XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        foreach (Jid full_jid in stream.get_flag(Presence.Flag.IDENTITY).get_resources(conversation.counterpart)) {
            // TODO(hrxi): Prioritization of transports (and resources?).
            if (!stream.get_module(Xep.JingleFileTransfer.Module.IDENTITY).is_available(stream, full_jid)) {
                continue;
            }
            stream.get_module(Xep.JingleFileTransfer.Module.IDENTITY).offer_file_stream.begin(stream, full_jid, file_transfer.input_stream, file_transfer.file_name, file_transfer.size);
            return;
        }
    }
}

}
