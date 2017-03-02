using Gee;

using Xmpp.Core;

namespace Xmpp.Roster {

public class Flag : XmppStreamFlag {
    public const string ID = "roster";
    public HashMap<string, Item> roster_items = new HashMap<string, Item>();

    internal string? iq_id;

    public Collection<Item> get_roster() {
        return roster_items.values;
    }

    public Item? get_item(string jid) {
        return roster_items[jid];
    }

    public static Flag? get_flag(XmppStream stream) { return (Flag?) stream.get_flag(NS_URI, ID); }

    public static bool has_flag(XmppStream stream) { return get_flag(stream) != null; }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return ID; }
}

}