using Dino.Entities;

using Crypto;
using Signal;

namespace Dino.Plugins.Omemo {

public class OmemoHttpFileReceiveData : HttpFileReceiveData {
    public string original_url;
}

public class OmemoFileDecryptor : FileDecryptor, Object {

    private Regex url_regex = /^aesgcm:\/\/(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$/;

    public Encryption get_encryption() {
        return Encryption.OMEMO;
    }

    public FileReceiveData prepare_get_meta_info(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data) {
        HttpFileReceiveData? http_receive_data = receive_data as HttpFileReceiveData;
        if (http_receive_data == null) assert(false);
        if ((receive_data as OmemoHttpFileReceiveData) != null) return receive_data;

        var omemo_http_receive_data = new OmemoHttpFileReceiveData();
        omemo_http_receive_data.url = aesgcm_to_https_link(http_receive_data.url);
        omemo_http_receive_data.original_url = http_receive_data.url;

        return omemo_http_receive_data;
    }

    public FileMeta prepare_download_file(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data, FileMeta file_meta) {
        if (file_meta.file_name != null) {
            file_meta.file_name = file_meta.file_name.split("#")[0];
        }
        return file_meta;
    }

    public bool can_decrypt_file(Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data) {
        HttpFileReceiveData? http_file_receive = receive_data as HttpFileReceiveData;
        if (http_file_receive == null) return false;

        return this.url_regex.match(http_file_receive.url) || (receive_data as OmemoHttpFileReceiveData) != null;
    }

    public async InputStream decrypt_file(InputStream encrypted_stream, Conversation conversation, FileTransfer file_transfer, FileReceiveData receive_data) throws FileReceiveError {
        try {
            OmemoHttpFileReceiveData? omemo_http_receive_data = receive_data as OmemoHttpFileReceiveData;
            if (omemo_http_receive_data == null) assert(false);

            // Decode IV and key
            MatchInfo match_info;
            this.url_regex.match(omemo_http_receive_data.original_url, 0, out match_info);
            uint8[] iv_and_key = hex_to_bin(match_info.fetch(2).up());
            uint8[] iv, key;
            if (iv_and_key.length == 44) {
                iv = iv_and_key[0:12];
                key = iv_and_key[12:44];
            } else {
                iv = iv_and_key[0:16];
                key = iv_and_key[16:48];
            }

            file_transfer.encryption = Encryption.OMEMO;
            debug("Decrypting file %s from %s", file_transfer.file_name, file_transfer.server_file_name);

            SymmetricCipher cipher = new SymmetricCipher("AES-GCM");
            cipher.set_key(key);
            cipher.set_iv(iv);
            return new ConverterInputStream(encrypted_stream, new SymmetricCipherDecrypter((owned) cipher, 16));

        } catch (Crypto.Error e) {
            throw new FileReceiveError.DECRYPTION_FAILED("OMEMO file decryption error: %s".printf(e.message));
        } catch (GLib.Error e) {
            throw new FileReceiveError.DECRYPTION_FAILED("OMEMO file decryption error: %s".printf(e.message));
        }
    }

    private uint8[] hex_to_bin(string hex) {
        uint8[] bin = new uint8[hex.length / 2];
        const string HEX = "0123456789ABCDEF";
        for (int i = 0; i < hex.length / 2; i++) {
            bin[i] = (uint8) (HEX.index_of_char(hex[i*2]) << 4) | HEX.index_of_char(hex[i*2+1]);
        }
        return bin;
    }

    private string aesgcm_to_https_link(string aesgcm_link) {
        MatchInfo match_info;
        this.url_regex.match(aesgcm_link, 0, out match_info);
        return "https://" + match_info.fetch(1);
    }
}

}
