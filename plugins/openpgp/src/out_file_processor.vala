using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class OutFileProcessor : OutgoingFileProcessor, Object {

    StreamInteractor stream_interactor;

    public OutFileProcessor(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool can_process(Conversation conversation, FileTransfer file_transfer) {
        return conversation.encryption == Encryption.PGP;
    }

    public void process(Conversation conversation, FileTransfer file_transfer) {
        string uri = file_transfer.get_uri();
        GPG.Key[] keys = stream_interactor.get_module(Manager.IDENTITY).get_key_fprs(conversation);
        uint8[] enc_content = GPGHelper.encrypt_file(uri, keys, GPG.EncryptFlags.ALWAYS_TRUST);
        file_transfer.input_stream = new MemoryInputStream.from_data(enc_content, GLib.free);
        file_transfer.encryption = Encryption.PGP;
        file_transfer.server_file_name = file_transfer.server_file_name + ".pgp";
    }
}

}
