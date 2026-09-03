namespace Xmpp.ResultSetManagement {
    public const string NS_URI = "http://jabber.org/protocol/rsm";
    public const int MAX_RESULTS = 20;

    public class ResultSetParameters {
        string? before { get; set; }
        string? after { get; set; }
        int? max { get; set; }
    }

    public StanzaNode create_set_rsm_node_before(string? before_id, int max_results = MAX_RESULTS) {
        var max_node = (new StanzaNode.build("max", Xmpp.ResultSetManagement.NS_URI)).put_node(new StanzaNode.text(max_results.to_string()));
        var node =  (new StanzaNode.build("set", Xmpp.ResultSetManagement.NS_URI)).add_self_xmlns()
                .put_node(max_node);
        var before_node = new StanzaNode.build("before", Xmpp.ResultSetManagement.NS_URI);
        if (before_id != null) before_node.put_node(new StanzaNode.text(before_id));
        node.put_node(before_node);
        return node;
    }

    public StanzaNode create_set_rsm_node_after(string? after_id, int max_results = MAX_RESULTS) {
        var max_node = (new StanzaNode.build("max", Xmpp.ResultSetManagement.NS_URI)).put_node(new StanzaNode.text(max_results.to_string()));
        var node =  (new StanzaNode.build("set", Xmpp.ResultSetManagement.NS_URI)).add_self_xmlns()
                .put_node(max_node);

        if (after_id != null) {
            var after_node = new StanzaNode.build("after", Xmpp.ResultSetManagement.NS_URI)
                    .put_node(new StanzaNode.text(after_id));
            node.put_node(after_node);
        }
        return node;
    }
}
