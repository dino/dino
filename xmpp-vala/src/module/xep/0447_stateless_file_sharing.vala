namespace Xmpp.Xep.StatelessFileSharing {

    public const string NS_URI = "jabber:x:sfs";
    public const string STANZA_NAME = "file-transfer";

    public interface SfsSource: Object {
        public abstract string type();
        public abstract string serialize();

        public abstract StanzaNode to_stanza_node();
    }

    // to add more sources, this should be exchanged with a interface
    public class HttpSource: Object, SfsSource {
        public string url;

        public const string HTTP_NS_URI = "http://jabber.org/protocol/url-data";
        public const string HTTP_STANZA_NAME = "url-data";
        public const string HTTP_URL_ATTRIBUTE = "target";
        public const string SOURCE_TYPE = "http";

        public string type() {
            return SOURCE_TYPE;
        }

        public string serialize() {
            return this.to_stanza_node().to_xml();
        }

        public StanzaNode to_stanza_node() {
            StanzaNode node = new StanzaNode.build(HTTP_STANZA_NAME, HTTP_NS_URI).add_self_xmlns();
            node.put_attribute(HTTP_URL_ATTRIBUTE, this.url);
            return node;
        }

        public static HttpSource deserialize(string data) {
            printerr(data);
            StanzaReader reader = new StanzaReader.for_string(data);
            assert(reader != null);
            StanzaNode node = new StanzaNode();
            printerr(node.to_ansi_string(true));
            assert(node != null);
            reader.read_stanza_node.begin ((obj, res) => {
                node = reader.read_stanza_node.end (res);
            });
            assert(node != null);
            printerr(node.to_ansi_string(true));
            HttpSource source = HttpSource.from_stanza_node(node);
            assert(source != null);
            return source;
        }

        public static HttpSource? from_stanza_node(StanzaNode node) {
            string? url = node.get_attribute(HTTP_URL_ATTRIBUTE);
            if (url == null) {
                return null;
            }
            HttpSource source = new HttpSource();
            source.url = url;
            return source;
        }

        public static Gee.List<HttpSource> extract_sources(StanzaNode node) {
            Gee.List<HttpSource> sources = new Gee.ArrayList<HttpSource>();
            foreach (StanzaNode http_node in node.get_subnodes(HTTP_STANZA_NAME, HTTP_NS_URI)) {
                HttpSource? source = HttpSource.from_stanza_node(http_node);
                if (source != null) {
                    sources.add(source);
                }
            }
            return sources;
        }
    }

    public class SfsElement {
        public Xep.FileMetadataElement.FileMetadata metadata;
        public Gee.List<SfsSource> sources;

        public static SfsElement? from_stanza_node(StanzaNode node) {
            SfsElement element = new SfsElement();
            StanzaNode? metadata_node = node.get_subnode("file", Xep.FileMetadataElement.NS_URI);
            if (metadata_node == null) {
                return null;
            }
            Xep.FileMetadataElement.FileMetadata metadata = Xep.FileMetadataElement.FileMetadata.from_stanza_node(metadata_node);
            if (metadata == null) {
                return null;
            }
            element.metadata = metadata;
            StanzaNode? sources_node = node.get_subnode("sources");
            if (sources_node == null) {
                return null;
            }
            Gee.List<HttpSource> sources = HttpSource.extract_sources(sources_node);
            if (sources.is_empty) {
                return null;
            }
            element.sources = sources;
            return element;
        }

        public StanzaNode to_stanza_node() {
            StanzaNode node = new StanzaNode.build(STANZA_NAME, NS_URI).add_self_xmlns();
            node.put_node(this.metadata.to_stanza_node());
            StanzaNode sources_node = new StanzaNode.build("sources", NS_URI);
            Gee.List<StanzaNode> sources = new Gee.ArrayList<StanzaNode>();
            foreach (SfsSource source in this.sources) {
                sources.add(source.to_stanza_node());
            }
            sources_node.sub_nodes = sources;
            node.put_node(sources_node);
            return node;
        }
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "stateless_file_sharing");

        public signal void received_sfs(Jid from, Jid to, SfsElement sfs_element, MessageStanza message);

        public void send_stateless_file_transfer(XmppStream stream, SfsElement sfs_element, Jid dst, string message_type) {
            // TODO: add fallback body
            StanzaNode sfs_node = sfs_element.to_stanza_node();
            printerr("Sending sfs node:");
            printerr(sfs_node.to_ansi_string(true));
            MessageStanza sfs_message = new MessageStanza() { to=dst, type_=message_type };
            MessageProcessingHints.set_message_hint(sfs_message, MessageProcessingHints.HINT_STORE);
            sfs_message.stanza.put_node(sfs_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, sfs_message);
        }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            StanzaNode? sfs_node = message.stanza.get_subnode(STANZA_NAME, NS_URI);
            if (sfs_node == null) {
                return;
            }
            SfsElement? sfs_element = SfsElement.from_stanza_node(sfs_node);
            if (sfs_element == null) {
                return;
            }
            // TODO: add message flag
            received_sfs(message.from, message.to, sfs_element, message);
        }

        public override void attach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
