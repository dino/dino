using Gee;

namespace Xmpp.Xep.BlockingCommand {

private const string NS_URI = "urn:xmpp:blocking";

public class Module : XmppStreamModule, Iq.Handler {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0191_blocking_command");

    public signal void block_push_received(XmppStream stream, Gee.List<string> jids);
    public signal void unblock_push_received(XmppStream stream, Gee.List<string> jids);
    public signal void unblock_all_received(XmppStream stream);

    public bool is_blocked(XmppStream stream, string jid) {
        return stream.get_flag(Flag.IDENTITY).blocklist.contains(jid);
    }

    public bool block(XmppStream stream, Gee.List<string> jids) {
        if (jids.size == 0) return false; // This would otherwise be a bad-request error.

        StanzaNode block_node = new StanzaNode.build("block", NS_URI).add_self_xmlns();
        fill_node_with_items(block_node, jids);
        Iq.Stanza iq = new Iq.Stanza.set(block_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, null);
        return true;
    }

    public bool unblock(XmppStream stream, Gee.List<string> jids) {
        if (jids.size == 0)  return false; // This would otherwise unblock all blocked JIDs.

        StanzaNode unblock_node = new StanzaNode.build("unblock", NS_URI).add_self_xmlns();
        fill_node_with_items(unblock_node, jids);
        Iq.Stanza iq = new Iq.Stanza.set(unblock_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, null);
        return true;
    }

    public void unblock_all(XmppStream stream) {
        StanzaNode unblock_node = new StanzaNode.build("unblock", NS_URI).add_self_xmlns();
        Iq.Stanza iq = new Iq.Stanza.set(unblock_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, null);
    }

    public bool is_supported(XmppStream stream) {
        return stream.has_flag(Flag.IDENTITY);
    }

    private void on_iq_get(XmppStream stream, Iq.Stanza iq) { }
    private void on_iq_set(XmppStream stream, Iq.Stanza iq) {
        StanzaNode? block_node = iq.stanza.get_subnode("block", NS_URI);
        StanzaNode? unblock_node = iq.stanza.get_subnode("unblock", NS_URI);
        Gee.List<string> jids;
        if (block_node != null) {
            jids = get_jids_from_items(block_node);
            stream.get_flag(Flag.IDENTITY).blocklist.add_all(jids);
            block_push_received(stream, jids);
        } else if (unblock_node != null) {
            jids = get_jids_from_items(unblock_node);
            if (jids.size > 0) {
                stream.get_flag(Flag.IDENTITY).blocklist.remove_all(jids);
                unblock_push_received(stream, jids);
            } else {
                stream.get_flag(Flag.IDENTITY).blocklist.clear();
                unblock_all_received(stream);
            }
        }
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.stream_negotiated.connect(on_stream_negotiated);
    }

    public override void detach(XmppStream stream) {
        stream.stream_negotiated.disconnect(on_stream_negotiated);
        stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI, this);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_stream_negotiated(XmppStream stream) {
        stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).request_info(stream, stream.remote_name, (stream, info_result) => {
            if (info_result.features.contains(NS_URI)) {
                stream.add_flag(new Flag());
                get_blocklist(stream, (stream, jids) => {
                    stream.get_flag(Flag.IDENTITY).blocklist = jids;
                });
                return;
            }
        });
    }

    private delegate void OnBlocklist(XmppStream stream, Gee.List<string> jids);
    private void get_blocklist(XmppStream stream, owned OnBlocklist listener) {
        StanzaNode blocklist_node = new StanzaNode.build("blocklist", NS_URI).add_self_xmlns();
        Iq.Stanza iq = new Iq.Stanza.get(blocklist_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            StanzaNode? node = iq.stanza.get_subnode("blocklist", NS_URI);
            if (node != null) {
                Gee.List<string> jids = get_jids_from_items(node);
                listener(stream, jids);
            }
        });
    }

    private Gee.List<string> get_jids_from_items(StanzaNode node) {
        Gee.List<StanzaNode> item_nodes = node.get_subnodes("item", NS_URI);
        Gee.List<string> jids = new ArrayList<string>();
        foreach (StanzaNode item_node in item_nodes) {
            string? jid = item_node.get_attribute("jid", NS_URI);
            if (jid != null) {
                jids.add(jid);
            }
        }
        return jids;
    }

    private void fill_node_with_items(StanzaNode node, Gee.List<string> jids) {
        foreach (string jid in jids) {
            StanzaNode item_node = new StanzaNode.build("item", NS_URI).add_self_xmlns();
            item_node.set_attribute("jid", jid, NS_URI);
            node.put_node(item_node);
        }
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "blocking_command");

    public Gee.List<string> blocklist;

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
