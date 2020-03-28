using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.JetOmemo {
public class EncryptionHelper : JingleFileEncryptionHelper, Object {
    private StreamInteractor stream_interactor;

    public EncryptionHelper(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool can_transfer(Conversation conversation) {
        return true;
    }

    public bool can_encrypt(Conversation conversation, FileTransfer file_transfer, Jid? full_jid) {
        XmppStream? stream = stream_interactor.get_stream(conversation.account);
        if (stream == null) return false;

        Gee.List<Jid>? resources = stream.get_flag(Presence.Flag.IDENTITY).get_resources(conversation.counterpart);
        if (resources == null) return false;

        if (full_jid == null) {
            foreach (Jid test_jid in resources) {
                if (stream.get_module(Module.IDENTITY).is_available(stream, test_jid)) {
                    return true;
                }
            }
        } else {
            if (stream.get_module(Module.IDENTITY).is_available(stream, full_jid)) {
                return true;
            }
        }
        return false;
    }

    public string? get_precondition_name(Conversation conversation, FileTransfer file_transfer) {
        return Xep.Jet.NS_URI;
    }

    public Object? get_precondition_options(Conversation conversation, FileTransfer file_transfer) {
        return new Xep.Jet.Options(Omemo.Legacy.NS_URI, AES_128_GCM_URI);
    }

    public FileMeta complete_meta(FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta, Xmpp.Xep.JingleFileTransfer.FileTransfer jingle_transfer) {
        Xep.Jet.SecurityParameters? security = jingle_transfer.security as Xep.Jet.SecurityParameters;
        if (security != null && security.encoding.get_type_uri() == Omemo.Legacy.NS_URI) {
            file_transfer.encryption = Encryption.OMEMO;
        }
        return file_meta;
    }
}
}