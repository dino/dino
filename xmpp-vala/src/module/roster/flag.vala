using Gee;

using Xmpp.Core;

namespace Xmpp.Roster {

public class Flag : XmppStreamFlag {
    public const string ID = "roster";
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, ID);

    public HashMap<string, Item> roster_items = new HashMap<string, Item>();

    public string? iq_id;

    public Collection<Item> get_roster() {
        return roster_items.values;
    }

    public Item? get_item(string jid) {
        return roster_items[jid];
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}