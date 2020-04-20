using Gtk;

using Dino.Entities;
using Xmpp.Util;

namespace Dino.Plugins.OpenPgp {

/* Adapted from OpenKeychain */
public static string markup_colorize_id(string s, bool is_fingerprint) {
    string markup = is_fingerprint ? "" : "0x";
    for (int i = 0; i < s.length; i += 4) {
        string four_chars = s.substring(i, 4).down();

        int raw = (int) from_hex(four_chars);
        uint8[] bytes = {(uint8) ((raw >> 8) & 0xff - 128), (uint8) (raw & 0xff - 128)};

        Checksum checksum = new Checksum(ChecksumType.SHA1);
        checksum.update(bytes, bytes.length);
        uint8[] digest = new uint8[20];
        size_t len = 20;
        checksum.get_digest(digest, ref len);

        uint8 r = digest[0];
        uint8 g = digest[1];
        uint8 b = digest[2];

        if (r == 0 && g == 0 && b == 0) r = g = b = 1;

        double brightness = 0.2126 * r + 0.7152 * g + 0.0722 * b;

        if (brightness < 80) {
            double factor = 80.0 / brightness;
            r = uint8.min(255, (uint8) (r * factor));
            g = uint8.min(255, (uint8) (g * factor));
            b = uint8.min(255, (uint8) (b * factor));

        } else if (brightness > 180) {
            double factor = 180.0 / brightness;
            r = (uint8) (r * factor);
            g = (uint8) (g * factor);
            b = (uint8) (b * factor);
        }

        if (i == 4 * 5) markup += "\n";
        markup += @"<span foreground=\"$("#%02x%02x%02x".printf(r, g, b))\">$four_chars</span>";
        if (is_fingerprint) markup += " ";
    }
    return "<span font_family='monospace' font='8'>" + markup + "</span>";
}

}
