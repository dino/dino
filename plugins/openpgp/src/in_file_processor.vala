using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class InFileProcessor : IncomingFileProcessor, Object {
    public bool can_process(FileTransfer file_transfer) {
        return file_transfer.file_name.has_suffix("pgp") || file_transfer.mime_type == "application/pgp-encrypted";
    }

    public void process(FileTransfer file_transfer) {
        try {
            uint8[] buf = new uint8[256];
            Array<uint8> data = new Array<uint8>(false, true, 0);
            size_t len = -1;
            do {
                len = file_transfer.input_stream.read(buf);
                data.append_vals(buf, (uint) len);
            } while(len > 0);

            GPGHelper.DecryptedData clear_data = GPGHelper.decrypt_data(data.data);
            file_transfer.input_stream = new MemoryInputStream.from_data(clear_data.data, GLib.free);
            file_transfer.encryption = Encryption.PGP;
            if (clear_data.filename != null && clear_data.filename != "") {
                file_transfer.file_name = clear_data.filename;
            } else if (file_transfer.file_name.has_suffix(".pgp")) {
                file_transfer.file_name = file_transfer.file_name.substring(0, file_transfer.file_name.length - 4);
            }
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }
}

}
