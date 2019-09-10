using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class PgpFileEncryptor : Dino.FileEncryptor, Object {

    StreamInteractor stream_interactor;

    public PgpFileEncryptor(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool can_encrypt_file(Conversation conversation, FileTransfer file_transfer) {
        return conversation.encryption == Encryption.PGP;
    }

    public FileMeta encrypt_file(Conversation conversation, FileTransfer file_transfer) throws FileSendError {
        FileMeta file_meta = new FileMeta();

        try {
            GPG.Key[] keys = stream_interactor.get_module(Manager.IDENTITY).get_key_fprs(conversation);
            uint8[] enc_content = GPGHelper.encrypt_file(file_transfer.get_file().get_path(), keys, GPG.EncryptFlags.ALWAYS_TRUST, file_transfer.file_name);
            file_transfer.input_stream = new MemoryInputStream.from_data(enc_content, GLib.free);
            file_transfer.encryption = Encryption.PGP;
            file_transfer.server_file_name = Xmpp.random_uuid() + ".pgp";
            file_meta.size = enc_content.length;
        } catch (Error e) {
            throw new FileSendError.ENCRYPTION_FAILED("PGP file encryption error: %s".printf(e.message));
        }
        debug("Encrypting file %s as %s", file_transfer.file_name, file_transfer.server_file_name);

        return file_meta;
    }

    public FileSendData? preprocess_send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) {
        HttpFileSendData? send_data = file_send_data as HttpFileSendData;
        if (send_data == null) return null;

        send_data.encrypt_message = false;

        return file_send_data;
    }
}

}
