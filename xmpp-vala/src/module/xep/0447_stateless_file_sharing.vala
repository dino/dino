using Xmpp;

namespace Xmpp.Xep.StatelessFileSharing {


    public const string STANZA_NAME = "file-transfer";

    public interface SfsSource: Object {
        public abstract string type();
        public abstract string serialize();

        public abstract StanzaNode to_stanza_node();
    }

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

        public static async HttpSource deserialize(string data) {
            StanzaNode node = yield new StanzaReader.for_string(data).read_stanza_node();
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
        public Xep.FileMetadataElement.FileMetadata metadata = new Xep.FileMetadataElement.FileMetadata();
        public Gee.List<SfsSource> sources = new Gee.ArrayList<SfsSource>();

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

    public class SfsSourceAttachment {
        public string sfs_id;
        public Gee.List<SfsSource> sources = new Gee.ArrayList<SfsSource>();

        public const string ATTACHMENT_NS_URI = "urn:xmpp:message-attaching:1";
        public const string ATTACH_TO_STANZA_NAME = "attach-to";
        public const string SOURCES_STANZA_NAME = "sources";
        public const string ID_ATTRIBUTE_NAME = "id";


        public static SfsSourceAttachment? from_message_stanza(MessageStanza stanza) {
            StanzaNode? attach_to = stanza.stanza.get_subnode(ATTACH_TO_STANZA_NAME, ATTACHMENT_NS_URI);
            StanzaNode? sources = stanza.stanza.get_subnode(SOURCES_STANZA_NAME, NS_URI);
            if (attach_to == null || sources == null) {
                return null;
            }
            string? id = attach_to.get_attribute(ID_ATTRIBUTE_NAME, ATTACHMENT_NS_URI);
            if (id == null) {
                return null;
            }
            SfsSourceAttachment attachment = new SfsSourceAttachment();
            attachment.sfs_id = id;
            Gee.List<HttpSource> http_sources = HttpSource.extract_sources(sources);
            if (http_sources.is_empty) {
                return null;
            }
            attachment.sources = http_sources;
            return attachment;
        }

        public MessageStanza to_message_stanza(Jid to, string message_type) {
            MessageStanza stanza = new MessageStanza() { to=to, type_=message_type };
            Xep.MessageProcessingHints.set_message_hint(stanza, Xep.MessageProcessingHints.HINT_STORE);

            StanzaNode attach_to = new StanzaNode.build(ATTACH_TO_STANZA_NAME, ATTACHMENT_NS_URI);
            attach_to.add_attribute(new StanzaAttribute.build(ATTACHMENT_NS_URI, "id", this.sfs_id));
            stanza.stanza.put_node(attach_to);

            StanzaNode sources = new StanzaNode.build(SOURCES_STANZA_NAME, NS_URI);
            Gee.List<StanzaNode> sources_nodes = new Gee.ArrayList<StanzaNode>();
            foreach (SfsSource source in this.sources) {
                sources_nodes.add(source.to_stanza_node());
            }
            sources.sub_nodes = sources_nodes;
            stanza.stanza.put_node(sources);

            return stanza;
        }
    }

    public class MessageFlag : Xmpp.MessageFlag {
        public const string ID = "stateless_file_sharing";

        public static MessageFlag? get_flag(MessageStanza message) {
            return (MessageFlag) message.get_flag(NS_URI, ID);
        }

        public override string get_ns() {
            return NS_URI;
        }

        public override string get_id() {
            return ID;
        }
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "stateless_file_sharing");

        public signal void received_sfs(Jid from, Jid to, SfsElement sfs_element, MessageStanza message);
        public signal void received_sfs_attachment(Jid from, Jid to, SfsSourceAttachment attachment, MessageStanza message);

        public void send_stateless_file_transfer(XmppStream stream, MessageStanza sfs_message, SfsElement sfs_element) {
            StanzaNode sfs_node = sfs_element.to_stanza_node();
            printerr(sfs_node.to_ansi_string(true));

            sfs_message.stanza.put_node(sfs_node);
            printerr("Sending message:\n");
            printerr(sfs_message.stanza.to_ansi_string(true));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, sfs_message);
        }

        public void send_stateless_file_transfer_attachment(XmppStream stream, Jid to, string message_type, SfsSourceAttachment attachment) {
            MessageStanza message = attachment.to_message_stanza(to, message_type);

            printerr("Sending message:\n");
            printerr(message.stanza.to_ansi_string(true));
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
        }

        private void on_received_message(XmppStream stream, MessageStanza message) {
            StanzaNode? sfs_node = message.stanza.get_subnode(STANZA_NAME, NS_URI);
            if (sfs_node != null) {
                SfsElement? sfs_element = SfsElement.from_stanza_node(sfs_node);
                if (sfs_element == null) {
                    return;
                }
                message.add_flag(new MessageFlag());
                received_sfs(message.from, message.to, sfs_element, message);
            }
            SfsSourceAttachment? attachment = SfsSourceAttachment.from_message_stanza(message);
            if (attachment != null) {
                received_sfs_attachment(message.from, message.to, attachment, message);
            }

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
