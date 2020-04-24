using Gee;

namespace Xmpp.Roster {

private const string NS_URI = "jabber:iq:roster";

public class Module : XmppStreamModule, Iq.Handler {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "roster_module");

    public signal void received_roster(XmppStream stream, Collection<Item> roster, Iq.Stanza stanza);
    public signal void pre_get_roster(XmppStream stream, Iq.Stanza iq);
    public signal void item_removed(XmppStream stream, Item item, Iq.Stanza iq);
    public signal void item_updated(XmppStream stream, Item item, Iq.Stanza iq);
    public signal void mutual_subscription(XmppStream stream, Jid jid);

    public bool interested_resource = true;

    public void add_jid(XmppStream stream, Jid jid, string? handle = null) {
        Item roster_item = new Item();
        roster_item.jid = jid;
        if (handle != null) {
            roster_item.name = handle;
        }
        roster_set(stream, roster_item);
    }

    public void remove_jid(XmppStream stream, Jid jid) {
        Item roster_item = new Item();
        roster_item.jid = jid;
        roster_item.subscription = Item.SUBSCRIPTION_REMOVE;

        roster_set(stream, roster_item);
    }

    /**
     * Set a handle for a jid
     * @param   handle  Handle to be set. If null, any handle will be removed.
     */
    public void set_jid_handle(XmppStream stream, Jid jid, string? handle) {
        Flag flag = stream.get_flag(Flag.IDENTITY);
        Item item = flag.get_item(jid) ?? new Item() { jid=jid };
        item.name = handle != null ? handle : "";

        roster_set(stream, item);
    }

    public async void on_iq_set(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI);
        if (query_node == null) return;
        if (!iq.from.equals(stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid)) {
            warning("Received alleged roster push from %s, ignoring", iq.from.to_string());
            return;
        }

        Flag flag = stream.get_flag(Flag.IDENTITY);
        Item item = new Item.from_stanza_node(query_node.get_subnode("item", NS_URI));
        switch (item.subscription) {
            case Item.SUBSCRIPTION_REMOVE:
                flag.roster_items.unset(item.jid);
                item_removed(stream, item, iq);
                break;
            default:
                bool is_new = false;
                Item old = flag.get_item(item.jid);
                is_new = item.subscription == Item.SUBSCRIPTION_BOTH && (old == null || old.subscription == Item.SUBSCRIPTION_BOTH);
                flag.roster_items[item.jid] = item;
                item_updated(stream, item,  iq);
                if(is_new) mutual_subscription(stream, item.jid);
                break;
        }
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
        stream.get_module(Presence.Module.IDENTITY).initial_presence_sent.connect(roster_get);
        stream.add_flag(new Flag());
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).initial_presence_sent.disconnect(roster_get);
    }

    internal override string get_ns() { return NS_URI; }
    internal override string get_id() { return IDENTITY.id; }

    private void roster_get(XmppStream stream) {
        stream.get_flag(Flag.IDENTITY).iq_id = random_uuid();
        StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns();
        Iq.Stanza iq = new Iq.Stanza.get(query_node, stream.get_flag(Flag.IDENTITY).iq_id);

        pre_get_roster(stream, iq);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, on_roster_get_received);
    }

    private static void on_roster_get_received(XmppStream stream, Iq.Stanza iq) {
        Flag flag = stream.get_flag(Flag.IDENTITY);
        if (iq.id == flag.iq_id) {
            StanzaNode? query_node = iq.stanza.get_subnode("query", NS_URI);
            if (query_node != null) {
                foreach (StanzaNode item_node in query_node.sub_nodes) {
                    Item item = new Item.from_stanza_node(item_node);
                    flag.roster_items[item.jid] = item;
                }
            }
            stream.get_module(Module.IDENTITY).received_roster(stream, flag.roster_items.values, iq);
        }
    }

    private void roster_set(XmppStream stream, Item roster_item) {
        StanzaNode query_node = new StanzaNode.build("query", NS_URI).add_self_xmlns()
                                .put_node(roster_item.stanza_node);
        Iq.Stanza iq = new Iq.Stanza.set(query_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq);
    }
}

}
