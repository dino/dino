namespace Xmpp.Xep.ServiceDiscovery {

public class Item {
    public string jid;
    public string? name;
    public string? node;

    public Item(string jid, string? name = null, string? node = null) {
        this.jid = jid;
        this.name = name;
        this.node = node;
    }
}

}