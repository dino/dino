using Gtk;

using Dino.Entities;
using Xmpp;

public class Dino.Ui.Util : GLib.Object {

    private const string[] tango_colors_light = {"FCE94F", "FCAF3E", "E9B96E", "8AE234", "729FCF", "AD7FA8", "EF2929"};
    private const string[] tango_colors_medium = {"EDD400", "F57900", "C17D11", "73D216", "3465A4", "75507B", "CC0000"};
    private const string[] material_colors_500 = {"F44336", "E91E63", "9C27B0", "673AB7", "3f51B5", "2196F3", "03A9f4", "00BCD4", "009688", "4CAF50", "8BC34a", "CDDC39", "FFEB3B", "FFC107", "FF9800", "FF5722", "795548"};
    private const string[] material_colors_300 = {"E57373", "F06292", "BA68C8", "9575CD", "7986CB", "64B5F6", "4FC3F7", "4DD0E1", "4DB6AC", "81C784", "AED581", "DCE775", "FFF176", "FFD54F", "FFB74D", "FF8A65", "A1887F"};
    private const string[] material_colors_200 = {"EF9A9A", "F48FB1", "CE93D8", "B39DDB", "9FA8DA", "90CAF9", "81D4FA", "80DEEA", "80CBC4", "A5D6A7", "C5E1A5", "E6EE9C", "FFF59D", "FFE082", "FFCC80", "FFAB91", "BCAAA4"};

    public static string get_avatar_hex_color(string name) {
        return material_colors_300[name.hash() % material_colors_300.length];
//        return tango_colors_light[name.hash() % tango_colors_light.length];
    }

    public static string get_name_hex_color(string name) {
        return material_colors_500[name.hash() % material_colors_500.length];
//        return tango_colors_medium[name.hash() % tango_colors_medium.length];
    }

    public static string color_for_show(string show) {
        switch(show) {
            case "online": return "#9CCC65";
            case "away": return "#FFCA28";
            case "chat": return "#66BB6A";
            case "xa": return "#EF5350";
            case "dnd": return "#EF5350";
            default: return "#BDBDBD";
        }
    }

    public static string get_conversation_display_name(StreamInteractor stream_interactor, Conversation conversation) {
        return get_display_name(stream_interactor, conversation.counterpart, conversation.account);
    }

    public static string get_display_name(StreamInteractor stream_interactor, Jid jid, Account account) {
        if (MucManager.get_instance(stream_interactor).is_groupchat_occupant(jid, account)) {
            return jid.resourcepart;
        } else {
            if (jid.bare_jid.equals(account.bare_jid.bare_jid)) {
                if (account.alias == null || account.alias == "") {
                    return account.bare_jid.to_string();
                } else {
                    return account.alias;
                }
            }
            Roster.Item roster_item = RosterManager.get_instance(stream_interactor).get_roster_item(account, jid);
            if (roster_item != null && roster_item.name != null) {
                return roster_item.name;
            }
            return jid.bare_jid.to_string();
        }
    }

    public static string get_message_display_name(StreamInteractor stream_interactor, Entities.Message message, Account account) {
        Jid? real_jid = MucManager.get_instance(stream_interactor).get_message_real_jid(message);
        if (real_jid != null) {
            return get_display_name(stream_interactor, real_jid, account);
        } else {
            return get_display_name(stream_interactor, message.from, account);
        }
    }

    public static void image_set_from_scaled_pixbuf(Image image, Gdk.Pixbuf pixbuf, int scale = 0) {
        if (scale == 0) scale = image.get_scale_factor();
        image.set_from_surface(Gdk.cairo_surface_create_from_pixbuf(pixbuf, scale, image.get_window()));
    }
}
