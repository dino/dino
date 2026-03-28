using Gtk;

using Dino.Entities;
using Xmpp.Util;

namespace Dino.Plugins.OpenPgp {

public static string markup_id(string s, bool is_fingerprint) {
    string markup = is_fingerprint ? "" : "0x";
    for (int i = 0; i < s.length; i += 4) {
        string four_chars = s.substring(i, 4).down();

        if (i == 4 * 5) markup += "\n";
        markup += four_chars;
        if (is_fingerprint) markup += " ";
    }
    return "<span font_family='monospace' font='9'>" + markup + "</span>";
}

}
