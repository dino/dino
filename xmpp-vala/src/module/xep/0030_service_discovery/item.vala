namespace Xmpp.Xep.ServiceDiscovery {

public class Item {
    public Jid jid;
    public string? name;
    public string? node;

    public Item(Jid jid, string? name = null, string? node = null) {
        this.jid = jid;
        this.name = name;
        this.node = node;
    }
}

}