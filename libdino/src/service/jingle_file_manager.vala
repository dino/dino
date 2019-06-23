using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class JingleFileManager : StreamInteractionModule, FileSender, Object {
    public static ModuleIdentity<JingleFileManager> IDENTITY = new ModuleIdentity<JingleFileManager>("jingle_files");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;

    public static void start(StreamInteractor stream_interactor) {
        JingleFileManager m = new JingleFileManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private JingleFileManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(FileManager.IDENTITY).add_sender(this);
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
            stream.get_module(Xep.JingleFileTransfer.Module.IDENTITY).offer_file_stream(stream, full_jid, file_transfer.input_stream, file_transfer.file_name, file_transfer.size);
            return;
        }
    }
}

}
