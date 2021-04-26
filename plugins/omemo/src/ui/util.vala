using Xmpp.Util;

namespace Dino.Plugins.Omemo {

public static string fingerprint_from_base64(string b64) {
    uint8[] arr = Base64.decode(b64);

    arr = arr[1:arr.length];
    string s = "";
    foreach (uint8 i in arr) {
        string tmp = i.to_string("%x");
        if (tmp.length == 1) tmp = "0" + tmp;
        s = s + tmp;
    }

    return s;
}

public static string fingerprint_markup(string s) {
    string markup = "";
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

        markup += @"<span foreground=\"$("#%02x%02x%02x".printf(r, g, b))\">$four_chars</span>";
        if (i % 8 == 4) markup += " ";
    }

    return "<span font_family='monospace' font='8'>" + markup + "</span>";
}

}
