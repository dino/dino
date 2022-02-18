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

        public Pixbuf to_pixbuf(int module_size) {
            GLib.assert(module_size > 0);
            var src_w = width;
            var src   = data[0:width*width];
            var dst_w = src_w*module_size;
            var dst   = new uint8[dst_w*dst_w*3];
            for (int src_y = 0; src_y < src_w; src_y++) {
                for (int repeat_y = 0; repeat_y < module_size; repeat_y++) {
                    var dst_y = src_y*module_size + repeat_y;
                    for (int src_x = 0; src_x < src_w; src_x++) {
                        uint8 color = (src[src_y*src_w + src_x] & 1) == 1 ? 0 : 255;
                        for (int repeat_x = 0; repeat_x < module_size; repeat_x++) {
                            var dst_x = src_x*module_size + repeat_x;
                            var px_idx = dst_y*dst_w + dst_x;
                            dst[px_idx*3+0] = color;
                            dst[px_idx*3+1] = color;
                            dst[px_idx*3+2] = color;
                        }
                    }
                }
            }
            return new Pixbuf.from_data(dst, Colorspace.RGB, false, 8, dst_w, dst_w, dst_w*3);
        }
    }
}
