namespace Xmpp.Xep.StatelessFileSharing {

    public const string NS_URI = "jabber:x:sfs";


    public class HttpSource {
        public string url;

        public const string HTTP_NS_URI = "http://jabber.org/protocol/url-data";
        public const string HTTP_STANZA_NAME = "url-data";
        public const string HTTP_URL_ATTRIBUTE = "url-data";

        public StanzaNode to_stanza_node() {
            StanzaNode node = new StanzaNode.build(HTTP_STANZA_NAME, HTTP_NS_URI);
            node.put_attribute(HTTP_URL_ATTRIBUTE, this.url);
            return node;
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
        public Gee.List<HttpSource> sources;

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
            StanzaNode node = new StanzaNode.build("file-sharing", NS_URI);
            node.put_node(this.metadata.to_stanza_node());
            StanzaNode sources_node = new StanzaNode.build("sources");
            Gee.List<StanzaNode> sources = new Gee.ArrayList<StanzaNode>();
            foreach (HttpSource source in this.sources) {
                sources.add(source.to_stanza_node());
            }
            sources_node.sub_nodes = sources;
            node.put_node(sources_node);
            return node;
        }
    }
}
