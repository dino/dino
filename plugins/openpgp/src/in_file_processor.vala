using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

public class InFileProcessor : IncommingFileProcessor, Object {
    public bool can_process(FileTransfer file_transfer) {
        return file_transfer.file_name.has_suffix("pgp") || file_transfer.mime_type == "application/pgp-encrypted";
    }

    public void process(FileTransfer file_transfer) {
        uint8[] buf = new uint8[256];
        Array<uint8> data = new Array<uint8>(false, true, 0);
        size_t len = -1;
        do {
            len = file_transfer.input_stream.read(buf);
            data.append_vals(buf, (uint) len);
        } while(len > 0);

        uint8[] clear_data = GPGHelper.decrypt_data(data.data);
        file_transfer.input_stream = new MemoryInputStream.from_data(clear_data, GLib.free);
        file_transfer.encryption = Encryption.PGP;
        if (file_transfer.file_name.has_suffix(".pgp")) {
            file_transfer.file_name = file_transfer.file_name.substring(0, file_transfer.file_name.length - 4);
        }
    }
}

}
