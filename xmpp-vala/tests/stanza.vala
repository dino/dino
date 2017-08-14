using Xmpp.Core;

namespace Xmpp.Test {

class StanzaTest : Gee.TestCase {
    public StanzaTest() {
        base("Stanza");

        add_test("node_one", test_node_one);
        add_test("typical_stream", test_typical_stream);
        add_test("ack_stream", test_ack_stream);
    }

    private void test_node_one() {
        var node1 = new StanzaNode.build("test", "ns1_uri")
                .add_self_xmlns()
                .put_attribute("ns2", "ns2_uri", XMLNS_URI)
                .put_attribute("bla", "blub")
                .put_node(new StanzaNode.build("testaa", "ns2_uri")
                    .put_attribute("ns3", "ns3_uri", XMLNS_URI))
                .put_node(new StanzaNode.build("testbb", "ns3_uri")
                    .add_self_xmlns());

        var xml1 = node1.to_xml();
        var node2 = new StanzaReader.for_string(xml1).read_node();
        fail_if_not(node1.equals(node2));
        fail_if_not_eq_str(node1.to_string(), node2.to_string());
    }

    private void test_typical_stream() {
        var stream = """
        <?xml version='1.0' encoding='UTF-8'?>
        <stream:stream
                to='example.com'
                xmlns='jabber:client'
                xmlns:stream='http://etherx.jabber.org/streams'
                version='1.0'>
            <message from='laurence@example.net/churchyard'
                    to='juliet@example.com'
                    xml:lang='en'>
                <body>I'll send a friar with speed, to Mantua, with my letters to thy lord.</body>
            </message>
        </stream:stream>
        """;
        var root_node_cmp = new StanzaNode.build("stream", "http://etherx.jabber.org/streams")
                .put_attribute("to", "example.com")
                .put_attribute("xmlns", "jabber:client")
                .put_attribute("stream", "http://etherx.jabber.org/streams", XMLNS_URI)
                .put_attribute("version", "1.0");
        var node_cmp = new StanzaNode.build("message")
                .put_attribute("from", "laurence@example.net/churchyard")
                .put_attribute("to", "juliet@example.com")
                .put_attribute("lang", "en", XML_URI)
                .put_node(new StanzaNode.build("body")
                        .put_node(new StanzaNode.text("I'll send a friar with speed, to Mantua, with my letters to thy lord.")));

        var reader = new StanzaReader.for_string(stream);
        fail_if_not_eq_node(root_node_cmp, reader.read_root_node());
        fail_if_not_eq_node(node_cmp, reader.read_node());
        reader.read_node();
        fail_if_not_error_code(() => reader.read_node(), 3, "end of stream should be reached");
    }

    private void test_ack_stream() {
        var stream = """
        <?xml version='1.0' encoding='UTF-8'?>
        <stream:stream
                to='example.com'
                xmlns='jabber:client'
                xmlns:stream='http://etherx.jabber.org/streams'
                xmlns:ack='http://jabber.org/protocol/ack'
                version='1.0'>
            <stream:features>
                <ack:ack/>
                <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'>
                    <required/>
                </bind>
            </stream:features>
            <ack:r/>
        </stream:stream>
        """;
        var root_node_cmp = new StanzaNode.build("stream", "http://etherx.jabber.org/streams")
                .put_attribute("to", "example.com")
                .put_attribute("xmlns", "jabber:client")
                .put_attribute("stream", "http://etherx.jabber.org/streams", XMLNS_URI)
                .put_attribute("ack", "http://jabber.org/protocol/ack", XMLNS_URI)
                .put_attribute("version", "1.0");
        var node_cmp = new StanzaNode.build("features", XmppStream.NS_URI)
                .put_node(new StanzaNode.build("ack", "http://jabber.org/protocol/ack"))
                .put_node(new StanzaNode.build("bind", "urn:ietf:params:xml:ns:xmpp-bind")
                        .add_self_xmlns()
                        .put_node(new StanzaNode.build("required", "urn:ietf:params:xml:ns:xmpp-bind")));
        var node2_cmp = new StanzaNode.build("r", "http://jabber.org/protocol/ack");

        var reader = new StanzaReader.for_string(stream);
        fail_if_not_eq_node(root_node_cmp, reader.read_root_node());
        fail_if_not_eq_node(node_cmp, reader.read_node());
        fail_if_not_eq_node(node2_cmp, reader.read_node());
        reader.read_node();
        fail_if_not_error_code(() => reader.read_node(), 3, "end of stream should be reached");
    }

}

}
