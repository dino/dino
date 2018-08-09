using Gdk;

[CCode (cheader_filename = "qrencode.h")]
namespace Qrencode {

    [CCode (cname = "QRecLevel", cprefix = "QR_ECLEVEL_")]
    public enum ECLevel {
        L,
        M,
        Q,
        H
    }

    [CCode (cname = "QRencodeMode", cprefix = "QR_MODE_")]
    public enum EncodeMode {
        NUL,
        NUM,
        AN,
        [CCode (cname = "QR_MODE_8")]
        EIGHT_BIT,
        KANJI,
        STRUCTURE,
        ECI,
        FNC1FIRST,
        FNC1SECOND
    }

    [CCode (cname = "QRcode", free_function = "QRcode_free", has_type_id = false)]
    [Compact]
    public class QRcode {
        private int version;
        private int width;
        [CCode (array_length = false)]
        private uint8[] data;

        [CCode (cname = "QRcode_encodeString")]
        public QRcode (string str, int version = 0, ECLevel level = ECLevel.L, EncodeMode hint = EncodeMode.EIGHT_BIT, bool casesensitive = true);

        public Pixbuf to_pixbuf() {
            uint8[] bitmap = new uint8[3*width*width];
            for (int i = 0; i < width*width; i++) {
                uint8 color = (data[i] & 1) == 1 ? 0 : 255;
                bitmap[i*3] = color;
                bitmap[i*3+1] = color;
                bitmap[i*3+2] = color;
            }
            return new Pixbuf.from_data(bitmap, Colorspace.RGB, false, 8, width, width, width*3);
        }
    }
}
