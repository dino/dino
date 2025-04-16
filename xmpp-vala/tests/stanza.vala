namespace Xmpp.Test {

class StanzaTest : Gee.TestCase {
    public StanzaTest() {
        base("Stanza");

        add_async_test("node_one", (cb) => { test_node_one.begin(cb); });
        add_async_test("typical_stream", (cb) => { test_typical_stream.begin(cb); });
        add_async_test("ack_stream", (cb) => { test_ack_stream.begin(cb); });
        add_test("get_attribute_(u)int", test_get_attribute_int);
    }

    private async void test_node_one(Gee.TestFinishedCallback cb) {
        var node1 = new StanzaNode.build("test", "ns1_uri")
                .add_self_xmlns()
                .put_attribute("ns2", "ns2_uri", XMLNS_URI)
                .put_attribute("bla", "blub")
                .put_node(new StanzaNode.build("testaa", "ns2_uri")
                    .put_attribute("ns3", "ns3_uri", XMLNS_URI))
                .put_node(new StanzaNode.build("testbb", "ns3_uri")
                    .add_self_xmlns());

        var xml1 = node1.to_xml();
        var node2 = yield new StanzaReader.for_string(xml1).read_node();
        fail_if_not(node1.equals(node2));
        fail_if_not_eq_str(node1.to_string(), node2.to_string());
        cb();
    }

    private async void test_typical_stream(Gee.TestFinishedCallback cb) {
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
                <body> I'll send a friar with speed, to Mantua, with my letters to thy lord.</body>
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
                        .put_node(new StanzaNode.text(" I'll send a friar with speed, to Mantua, with my letters to thy lord.")));

        var reader = new StanzaReader.for_string(stream);
        fail_if_not_eq_node(root_node_cmp, yield reader.read_root_node());
        fail_if_not_eq_node(node_cmp, yield reader.read_node());
        yield reader.read_node();
        yield fail_if_not_end_of_stream(reader);
        cb();
    }

    private async void fail_if_not_end_of_stream(StanzaReader reader) {
        try {
            yield reader.read_node();
            fail_if_reached("end of stream should be reached");
        } catch (IOError.CLOSED e) {
            return;
        } catch (Error e) {
            fail_if_reached("Unexpected error");
        }
    }

    private async void test_ack_stream(Gee.TestFinishedCallback cb) {
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
        fail_if_not_eq_node(root_node_cmp, yield reader.read_root_node());
        fail_if_not_eq_node(node_cmp, yield reader.read_node());
        fail_if_not_eq_node(node2_cmp, yield reader.read_node());
        yield reader.read_node();
        yield fail_if_not_end_of_stream(reader);
        cb();
    }

    private void test_get_attribute_int() {
        var stanza_node = new StanzaNode.build("test", "ns").add_self_xmlns().put_attribute("bar", "42");
        fail_if_not_eq_int(stanza_node.get_attribute_int("bar", -2), 42);
        fail_if_not_eq_uint(stanza_node.get_attribute_uint("bar", 3), 42);

        // TODO: REVERT after understanding why try_parse overflows on Windows
        #if _WIN32
        #else
        stanza_node = new StanzaNode.build("test", "ns").add_self_xmlns().put_attribute("bar", "-42");
        fail_if_not_eq_int(stanza_node.get_attribute_int("bar", -2), -42);
        fail_if_not_eq_uint(stanza_node.get_attribute_uint("bar", 3), 3);
        #endif

        stanza_node = new StanzaNode.build("test", "ns").add_self_xmlns();
        fail_if_not_eq_int(stanza_node.get_attribute_int("bar", -2), -2);
        fail_if_not_eq_uint(stanza_node.get_attribute_uint("bar", 3), 3);

        stanza_node = new StanzaNode.build("test", "ns").add_self_xmlns().put_attribute("bar", "0x42");
        fail_if_not_eq_int(stanza_node.get_attribute_int("bar", -2), -2);
        fail_if_not_eq_uint(stanza_node.get_attribute_uint("bar", 3), 3);

        stanza_node = new StanzaNode.build("test", "ns").add_self_xmlns().put_attribute("bar", "str");
        fail_if_not_eq_int(stanza_node.get_attribute_int("bar", -2), -2);
        fail_if_not_eq_uint(stanza_node.get_attribute_uint("bar", 3), 3);

    }

}

}
