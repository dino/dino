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
            var dst_width = width*module_size;
            var dst_data  = new uint8[dst_width*dst_width*3];
            expand_and_upsample(data,width,width, dst_data,dst_width,dst_width);
            return new Pixbuf.from_data(dst_data,
                Colorspace.RGB, false, 8, dst_width, dst_width, dst_width*3);
        }

        /**  Does 2D nearest-neighbor upsampling of an array of single-byte
         * samples, while expanding the least significant bit of each sample
         * to three 0-or-255 bytes.
         */
        private void expand_and_upsample(
            uint8[] src, uint src_w, uint src_h,
            uint8[] dst, uint dst_w, uint dst_h) {
            GLib.assert(dst_w % src_w == 0);
            GLib.assert(dst_h % src_h == 0);
            var scale_x = dst_w/src_w,
                scale_y = dst_h/src_h;
            /*   Doing the iteration in the order of destination samples for
             * improved cache-friendliness (dst is 48 times larger than src in
             * the typical case of scaling by 4x4).
             *   The choice of multiple nested loops over a single one is for
             * avoiding a ton of divisions by non-constants.
             */
            for (uint src_y = 0; src_y < src_h; ++src_y) {
                for (uint repeat_y = 0; repeat_y < scale_y; ++repeat_y) {
                    var dst_y = src_y*scale_y + repeat_y;
                    for (uint src_x = 0; src_x < src_w; ++src_x) {
                        uint8 value = (src[src_y*src_w + src_x] & 1)==1 ? 0:255;
                        for (uint repeat_x = 0; repeat_x < scale_x; ++repeat_x){
                            var dst_x = src_x*scale_x + repeat_x;
                            var dst_idx = dst_y*dst_w + dst_x;
                            dst[dst_idx*3+0] = value;
                            dst[dst_idx*3+1] = value;
                            dst[dst_idx*3+2] = value;
                        }
                    }
                }
            }
        }
    }
}
