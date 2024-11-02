using Gee;
using Xmpp;

namespace Xmpp.Xep.StatelessFileSharing {

    public const string NS_URI = "urn:xmpp:sfs:0";

    public static Gee.List<FileShare> get_file_shares(MessageStanza message) {
        var ret = new ArrayList<FileShare>();
        foreach (StanzaNode file_sharing_node in message.stanza.get_subnodes("file-sharing", NS_URI)) {
            var metadata = Xep.FileMetadataElement.get_file_metadata(file_sharing_node);
            if (metadata == null) continue;

            var sources_node = message.stanza.get_subnode("sources", NS_URI);

            ret.add(new FileShare() {
                id = file_sharing_node.get_attribute("id", NS_URI),
                metadata = Xep.FileMetadataElement.get_file_metadata(file_sharing_node),
                sources = sources_node != null ? get_sources(sources_node) : null
            });
        }

        if (ret.size == 0) return null;

        return ret;
    }

    public static Gee.List<SourceAttachment>? get_source_attachments(MessageStanza message) {
        Gee.List<StanzaNode> sources_nodes = message.stanza.get_subnodes("sources", NS_URI);
        if (sources_nodes.is_empty) return null;

        string? attach_to_id = MessageAttaching.get_attach_to(message.stanza);
        if (attach_to_id == null) return null;

        var ret = new ArrayList<SourceAttachment>();

        foreach (StanzaNode sources_node in sources_nodes) {
            ret.add(new SourceAttachment() {
                to_message_id = attach_to_id,
                to_file_transfer_id = sources_node.get_attribute("id", NS_URI),
                sources = get_sources(sources_node)
            });
        }
        return ret;
    }

    // Currently only returns a single http source
    private static Gee.List<Source>? get_sources(StanzaNode sources_node) {
        string? url = HttpSchemeForUrlData.get_url(sources_node);
        if (url == null) return null;

        var http_source = new HttpSource() { url=url };
        var sources = new Gee.ArrayList<Source>();
        sources.add(http_source);

        return sources;
    }

    public static void set_sfs_element(MessageStanza message, string file_sharing_id, FileMetadataElement.FileMetadata metadata, Gee.List<Xep.StatelessFileSharing.Source>? sources) {
        var file_sharing_node = new StanzaNode.build("file-sharing", NS_URI).add_self_xmlns()
                .put_attribute("id", file_sharing_id, NS_URI)
                .put_node(metadata.to_stanza_node());
        if (sources != null && !sources.is_empty) {
            file_sharing_node.put_node(create_sources_node(file_sharing_id, sources));
        }
        message.stanza.put_node(file_sharing_node);
    }

    public static void set_sfs_attachment(MessageStanza message, string attach_to_id, string attach_to_file_id, Gee.List<Xep.StatelessFileSharing.Source> sources) {
        message.stanza.put_node(MessageAttaching.to_stanza_node(attach_to_id));
        message.stanza.put_node(create_sources_node(attach_to_file_id, sources).add_self_xmlns());
    }

    private static StanzaNode create_sources_node(string file_sharing_id, Gee.List<Xep.StatelessFileSharing.Source> sources) {
        StanzaNode sources_node = new StanzaNode.build("sources", NS_URI)
                .put_attribute("id", file_sharing_id, NS_URI);
        foreach (var source in sources) {
            sources_node.put_node(source.to_stanza_node());
        }
        return sources_node;
    }

    public class FileShare : Object {
        public string? id { get; set; }
        public Xep.FileMetadataElement.FileMetadata metadata { get; set; }
        public Gee.List<Source>? sources { get; set; }
    }

    public class SourceAttachment : Object {
        public string to_message_id { get; set; }
        public string? to_file_transfer_id { get; set; }
        public Gee.List<Source>? sources { get; set; }
    }

    public interface Source: Object {
        public abstract string type();
        public abstract StanzaNode to_stanza_node();
        public abstract bool equals(Source source);

        public static bool equals_func(Source s1, Source s2) {
            return s1.equals(s2);
        }
    }

    public class HttpSource : Object, Source {
        public string url { get; set; }

        public string type() {
            return "http";
        }

        public StanzaNode to_stanza_node() {
            return HttpSchemeForUrlData.to_stanza_node(url);
        }

        public bool equals(Source source) {
            HttpSource? http_source = source as HttpSource;
            if (http_source == null) return false;
            return http_source.url == this.url;
        }
    }
}
