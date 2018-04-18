using Dino.Entities;
using Signal;

namespace Dino.Plugins.Omemo {

public class InFileProcessor : IncommingFileProcessor, Object {
    private Regex url_regex;

    public InFileProcessor () {
        this.url_regex = new Regex("""^aesgcm://(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$""");
    }

    public bool can_process(FileTransfer file_transfer) {
        string url = file_transfer.info.substring(file_transfer.info.index_of(":")+1);
        return this.url_regex.match(url);
    }

    public void process(FileTransfer file_transfer) {
        try {
            // Decode IV and key
            MatchInfo match_info;
            string url = file_transfer.info.substring(file_transfer.info.index_of(":")+1);
            this.url_regex.match(url, 0, out match_info);
            uint8[] iv_and_key = hex_to_bin(match_info.fetch(2).up());
            uint8[] iv, key;
            if (iv_and_key.length == 44) {
                iv = iv_and_key[0:12];
                key = iv_and_key[12:44];
            } else {
                iv = iv_and_key[0:16];
                key = iv_and_key[16:48];
            }

            // Read data
            uint8[] buf = new uint8[256];
            Array<uint8> data = new Array<uint8>(false, true, 0);
            size_t len = -1;
            do {
                len = file_transfer.input_stream.read(buf);
                data.append_vals(buf, (uint) len);
            } while(len > 0);
            // Decrypt
            file_transfer.input_stream = new MemoryInputStream.from_data(aes_decrypt(Cipher.AES_GCM_NOPADDING, key, iv, data.data));
            file_transfer.encryption = Encryption.OMEMO;
        } catch (Error e) {
            file_transfer.state = FileTransfer.State.FAILED;
        }
    }

  private uint8[] hex_to_bin(string hex) {
    uint8[] bin = new uint8[hex.length / 2];
    const string HEX = "0123456789ABCDEF";
    for (int i = 0; i < hex.length / 2; i++)
      bin[i] = (uint8) (HEX.index_of_char(hex[i*2]) << 4) | HEX.index_of_char(hex[i*2+1]);
    return bin;
  }

}

}
