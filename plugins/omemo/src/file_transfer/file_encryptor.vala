using Gee;
using Gtk;

using Crypto;
using Dino.Entities;
using Omemo;
using Xmpp;

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
            //Create a key and use it to encrypt the file
            uint8[] iv = new uint8[16];
            Plugin.get_context().randomize(iv);
            uint8[] key = new uint8[32];
            Plugin.get_context().randomize(key);

            SymmetricCipher cipher = new SymmetricCipher("AES-GCM");
            cipher.set_key(key);
            cipher.set_iv(iv);

            omemo_http_file_meta.iv = iv;
            omemo_http_file_meta.key = key;
            omemo_http_file_meta.size = file_transfer.size + 16;
            omemo_http_file_meta.mime_type = "omemo";
            file_transfer.input_stream = new ConverterInputStream(file_transfer.input_stream, new SymmetricCipherEncrypter((owned) cipher, 16));
        } catch (Crypto.Error error) {
            throw new FileSendError.ENCRYPTION_FAILED("OMEMO file encryption error: %s".printf(error.message));
        } catch (GLib.Error error) {
            throw new FileSendError.ENCRYPTION_FAILED("OMEMO file encryption error: %s".printf(error.message));
        }

        debug("Encrypting file %s as %s", file_transfer.file_name, file_transfer.server_file_name);

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
