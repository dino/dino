namespace Xmpp.Xep.Hats {
private const string NS_URI = "urn:xmpp:hats:0";

public class Hat {
    public StanzaNode stanza_node { get; set; }

    public string? uri {
        get {
            return stanza_node.get_attribute("uri");
        }
    }

    public string? title {
        get {
            return stanza_node.get_attribute("title");
        }
    }

    internal Hat.from_node(StanzaNode node) {
        this.stanza_node = node;
    }
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0317_hats");

    public signal void hats_received(XmppStream stream, Jid jid, Gee.List<Hat> hats);

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
        var hats_node = presence.stanza.get_subnode("hats", NS_URI);
        if (hats_node != null) {
            var hats = new Gee.ArrayList<Hat>();

            foreach (var node in hats_node.get_all_subnodes()) {
                if (node.name == "hat") {
                    hats.add(new Hat.from_node(node));
                }
            }

            debug("received %d hats for %s", hats.size, presence.from.to_string());

            hats_received(stream, presence.from, hats);
        }
    }
}
}
