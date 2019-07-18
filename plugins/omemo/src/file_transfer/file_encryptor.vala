using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;
using Signal;

namespace Dino.Plugins.Omemo {

public class OmemoHttpFileMeta : HttpFileMeta {
    public uint8[] iv;
    public uint8[] key;
}

public class OmemoFileEncryptor : Dino.FileEncryptor, Object {

    public bool can_encrypt_file(Conversation conversation, FileTransfer file_transfer) {
        return file_transfer.encryption == Encryption.OMEMO;
    }

    public FileMeta encrypt_file(Conversation conversation, FileTransfer file_transfer) throws FileSendError {
        var omemo_http_file_meta = new OmemoHttpFileMeta();

        try {
            uint8[] buf = new uint8[256];
            Array<uint8> data = new Array<uint8>(false, true, 0);
            size_t len = -1;
            do {
                len = file_transfer.input_stream.read(buf);
                data.append_vals(buf, (uint) len);
            } while(len > 0);

            //Create a key and use it to encrypt the file
            uint8[] iv = new uint8[16];
            Plugin.get_context().randomize(iv);
            uint8[] key = new uint8[32];
            Plugin.get_context().randomize(key);
            uint8[] ciphertext = aes_encrypt(Cipher.AES_GCM_NOPADDING, key, iv, data.data);

            omemo_http_file_meta.iv = iv;
            omemo_http_file_meta.key = key;
            omemo_http_file_meta.size = ciphertext.length;
            omemo_http_file_meta.mime_type = "pgp";
            file_transfer.input_stream = new MemoryInputStream.from_data(ciphertext, GLib.free);
        } catch (Error error) {
            throw new FileSendError.ENCRYPTION_FAILED("HTTP upload: Error encrypting stream: %s".printf(error.message));
        }

        return omemo_http_file_meta;
    }

    public FileSendData? preprocess_send_file(Conversation conversation, FileTransfer file_transfer, FileSendData file_send_data, FileMeta file_meta) {
        HttpFileSendData? send_data = file_send_data as HttpFileSendData;
        if (send_data == null) return null;

        OmemoHttpFileMeta? omemo_http_file_meta = file_meta as OmemoHttpFileMeta;
        if (omemo_http_file_meta == null) return null;

        // Convert iv and key to hex
        string iv_and_key = "";
        foreach (uint8 byte in omemo_http_file_meta.iv) iv_and_key += byte.to_string("%02x");
        foreach (uint8 byte in omemo_http_file_meta.key) iv_and_key += byte.to_string("%02x");

        string aesgcm_link = send_data.url_down + "#" + iv_and_key;
        aesgcm_link = "aesgcm://" + aesgcm_link.substring(8); // replace https:// by aesgcm://

        send_data.url_down = aesgcm_link;
        send_data.encrypt_message = true;

        return file_send_data;
    }
}

}
