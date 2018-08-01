using Gee;

namespace Xmpp.Roster {

public class VersioningModule : XmppStreamModule {
    private const string NS_URI_FEATURE = "urn:xmpp:features:rosterver";

    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "roster_versioning");

    private Storage storage;

    public VersioningModule(Storage storage) {
        this.storage = storage;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Module.IDENTITY).pre_get_roster.connect(on_pre_get_roster);
        stream.get_module(Module.IDENTITY).received_roster.connect(on_received_roster);
        stream.get_module(Module.IDENTITY).item_updated.connect(on_item_updated);
        stream.get_module(Module.IDENTITY).item_removed.connect(on_item_removed);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Module.IDENTITY).pre_get_roster.disconnect(on_pre_get_roster);
    }

    internal override string get_ns() { return NS_URI; }
    internal override string get_id() { return IDENTITY.id; }

    private void on_pre_get_roster(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? ver_feature = stream.features.get_subnode("ver", NS_URI_FEATURE);
        if (ver_feature != null) {
            iq.stanza.get_subnode("query", NS_URI).set_attribute("ver", storage.get_roster_version() ?? "");
        }
    }

    private void on_received_roster(XmppStream stream, Collection<Item> roster, Iq.Stanza iq) {
        string? ver = iq.stanza.get_deep_attribute(NS_URI + ":query", NS_URI + ":ver");
        if (ver != null) storage.set_roster_version(ver);
        if (iq.stanza.get_subnode("query", NS_URI) != null) {
            storage.set_roster(roster);
        } else {
            Flag flag = stream.get_flag(Flag.IDENTITY);
            foreach (Item item in storage.get_roster()) {
                flag.roster_items[item.jid] = item;
            }
        }
    }

    private void on_item_updated(XmppStream stream, Item item, Iq.Stanza iq) {
        string? ver = iq.stanza.get_deep_attribute(NS_URI + ":query", NS_URI + ":ver");
        if (ver != null) storage.set_roster_version(ver);
        storage.set_item(item);
    }

    private void on_item_removed(XmppStream stream, Item item, Iq.Stanza iq) {
        string? ver = iq.stanza.get_deep_attribute(NS_URI + ":query", NS_URI + ":ver");
        if (ver != null) storage.set_roster_version(ver);
        storage.remove_item(item);
    }
}

public interface Storage : Object {
    public abstract string? get_roster_version();
    public abstract Collection<Roster.Item> get_roster();
    public abstract void set_roster_version(string version);
    public abstract void set_roster(Collection<Roster.Item> items);
    public abstract void set_item(Roster.Item item);
    public abstract void remove_item(Roster.Item item);
}

}
