using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class JingleFileProvider : FileProvider, Object {

    private StreamInteractor stream_interactor;
    private HashMap<string, Xmpp.Xep.JingleFileTransfer.FileTransfer> file_transfers = new HashMap<string, Xmpp.Xep.JingleFileTransfer.FileTransfer>();

    public JingleFileProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.stream_negotiated.connect(on_stream_negotiated);
    }

    public FileMeta get_file_meta(FileTransfer file_transfer) throws FileReceiveError {
        var file_meta = new FileMeta();
        file_meta.file_name = file_transfer.file_name;
        file_meta.size = file_transfer.size;
        return file_meta;
    }

    public FileReceiveData? get_file_receive_data(FileTransfer file_transfer) {
        return new FileReceiveData();
    }

    public async FileMeta get_meta_info(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError {
        return file_meta;
    }

    public async InputStream download(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) throws FileReceiveError {
        // TODO(hrxi) What should happen if `stream == null`?
        XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        Xmpp.Xep.JingleFileTransfer.FileTransfer? jingle_file_transfer = file_transfers[file_transfer.info];
        if (jingle_file_transfer == null) {
            throw new FileReceiveError.DOWNLOAD_FAILED("Transfer data not available anymore");
        }
        try {
            jingle_file_transfer.accept(stream);
        } catch (IOError e) {
            throw new FileReceiveError.DOWNLOAD_FAILED("Establishing connection did not work");
        }
        return jingle_file_transfer.stream;
    }

    public int get_id() {
        return 1;
    }

    private void on_stream_negotiated(Account account, XmppStream stream) {
        stream_interactor.module_manager.get_module(account, Xmpp.Xep.JingleFileTransfer.Module.IDENTITY).file_incoming.connect((stream, jingle_file_transfer) => {
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jingle_file_transfer.peer.bare_jid, account);
            if (conversation == null) {
                // TODO(hrxi): What to do?
                return;
            }
            string id = random_uuid();

            file_transfers[id] = jingle_file_transfer;

            FileMeta file_meta = new FileMeta();
            file_meta.size = jingle_file_transfer.size;
            file_meta.file_name = jingle_file_transfer.file_name;

            var time = new DateTime.now_utc();
            var from = jingle_file_transfer.peer.bare_jid;

            file_incoming(id, from, time, time, conversation, new FileReceiveData(), file_meta);
        });
    }
}

public class JingleFileSender : FileSender, Object {

    private StreamInteractor stream_interactor;

    public JingleFileSender(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool is_upload_available(Conversation conversation) {
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;

        Gee.List<Jid>? resources = stream.get_flag(Presence.Flag.IDENTITY).get_resources(conversation.counterpart);
        if (resources == null) return false;

        foreach (Jid full_jid in resources) {
            if (stream.get_module(Xep.JingleFileTransfer.Module.IDENTITY).is_available(stream, full_jid)) {
                return true;
            }
        }
        return false;
    }

    public bool can_send(Conversation conversation, FileTransfer file_transfer) {
        if (conversation.encryption != Encryption.NONE) return false;

        XmppStream? stream = stream_interactor.get_stream(file_transfer.account);
        if (stream == null) return false;

        foreach (Jid full_jid in stream.get_flag(Presence.Flag.IDENTITY).get_resources(conversation.counterpart)) {
            if (stream.get_module(Xep.JingleFileTransfer.Module.IDENTITY).is_available(stream, full_jid)) {
                return true;
            }
        }
        return false;
    }

    public async FileSendData? prepare_send_file(Conversation conversation, FileTransfer file_transfer, FileMeta file_meta) throws FileSendError {
        return new FileSendData();
    }

    public async void send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data) throws FileSendError {
        // TODO(hrxi) What should happen if `stream == null`?
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

    public int get_id() { return 1; }

    public float get_priority() { return 50; }
}

}
