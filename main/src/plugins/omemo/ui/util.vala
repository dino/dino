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
    return "<span font_family='monospace' font='9'>" + format_fingerprint(s) + "</span>";
}

public static string format_fingerprint(string s) {
    string markup = "";
    for (int i = 0; i < s.length; i += 4) {
        string four_chars = s.substring(i, 4).down();

        if (i % 32 == 0 && i != 0) markup += "\n";
        markup += four_chars;
        if (i % 16 == 12 && i % 32 != 28) {
            markup += " ";
        }
        if (i % 8 == 4 && i % 16 != 12) {
            markup += "\u00a0"; // Non-breaking space
        }
    }
    return markup;
}

}
