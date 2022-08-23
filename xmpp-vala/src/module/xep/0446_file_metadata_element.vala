using Xmpp.Xep.CryptographicHashes;

namespace Xmpp.Xep.FileMetadataElement {
    public const string NS_URI = "urn:xmpp:file:metadata:0";

    public class FileMetadata {
        public string name { get; set; }
        public string? mime_type { get; set; }
        public int64 size { get; set; default=-1; }
        public string? desc { get; set; }
        public DateTime? date { get; set; }
        public int width { get; set; default=-1; } // Width of image in pixels
	    public int height { get; set; default=-1; } // Height of image in pixels
	    public CryptographicHashes.Hashes hashes = new CryptographicHashes.Hashes.empty();
	    public int length { get; set; default=-1; } // Length of audio/video in milliseconds
	    public Gee.List<Xep.JingleContentThumbnails.Thumbnail> thumbnails = new Gee.ArrayList<Xep.JingleContentThumbnails.Thumbnail>();

        public StanzaNode to_stanza_node() {
            StanzaNode node = new StanzaNode.build("file", NS_URI).add_self_xmlns()
                    .put_node(new StanzaNode.build("name", NS_URI).put_node(new StanzaNode.text(this.name)));
            if (this.mime_type != null) {
                node.put_node(new StanzaNode.build("media_type", NS_URI).put_node(new StanzaNode.text(this.mime_type)));
            }
            if (this.size != -1) {
                node.put_node(new StanzaNode.build("size", NS_URI).put_node(new StanzaNode.text(this.size.to_string())));
            }
            if (this.date != null) {
                node.put_node(new StanzaNode.build("date", NS_URI).put_node(new StanzaNode.text(this.date.to_string())));
            }
            if (this.desc != null) {
                node.put_node(new StanzaNode.build("desc", NS_URI).put_node(new StanzaNode.text(this.desc)));
            }
            if (this.width != -1) {
                node.put_node(new StanzaNode.build("width", NS_URI).put_node(new StanzaNode.text(this.width.to_string())));
            }
            if (this.height != -1) {
                node.put_node(new StanzaNode.build("height", NS_URI).put_node(new StanzaNode.text(this.height.to_string())));
            }
            if (this.length != -1) {
                node.put_node(new StanzaNode.build("length", NS_URI).put_node(new StanzaNode.text(this.length.to_string())));
            }
            node.sub_nodes.add_all(this.hashes.to_stanza_nodes());
            foreach (Xep.JingleContentThumbnails.Thumbnail thumbnail in this.thumbnails) {
                node.put_node(thumbnail.to_stanza_node());
            }
            return node;
        }

        public void add_to_message(MessageStanza message) {
            StanzaNode node = this.to_stanza_node();
            printerr("Attaching file metadata:\n");
            printerr("%s\n", node.to_ansi_string(true));
            message.stanza.put_node(node);
        }

        public static FileMetadata? from_stanza_node(StanzaNode node) {
            FileMetadata metadata = new FileMetadata();
            // TODO: null checks on final values
            StanzaNode? name_node = node.get_subnode("name");
            if (name_node == null || name_node.get_string_content() == null) {
                return null;
            } else {
                metadata.name = name_node.get_string_content();
            }
            StanzaNode? desc_node = node.get_subnode("desc");
            if (desc_node != null && desc_node.get_string_content() != null) {
                metadata.desc = desc_node.get_string_content();
            }
            StanzaNode? mime_node = node.get_subnode("media_type");
            if (mime_node != null && mime_node.get_string_content() != null) {
                metadata.mime_type = mime_node.get_string_content();
            }
            StanzaNode? size_node = node.get_subnode("size");
            if (size_node != null && size_node.get_string_content() != null) {
                metadata.size = int64.parse(size_node.get_string_content());
            }
            StanzaNode? date_node = node.get_subnode("date");
            if (date_node != null && date_node.get_string_content() != null) {
                metadata.date = new DateTime.from_iso8601(date_node.get_string_content(), null);
            }
            StanzaNode? width_node = node.get_subnode("width");
            if (width_node != null && width_node.get_string_content() != null) {
                metadata.width = int.parse(width_node.get_string_content());
            }
            StanzaNode? height_node = node.get_subnode("height");
            if (height_node != null && height_node.get_string_content() != null) {
                metadata.height = int.parse(height_node.get_string_content());
            }
            StanzaNode? length_node = node.get_subnode("length");
            if (length_node != null && length_node.get_string_content() != null) {
                metadata.length = int.parse(length_node.get_string_content());
            }
            foreach (StanzaNode thumbnail_node in node.get_subnodes(Xep.JingleContentThumbnails.STANZA_NAME, Xep.JingleContentThumbnails.NS_URI)) {
                Xep.JingleContentThumbnails.Thumbnail? thumbnail = Xep.JingleContentThumbnails.Thumbnail.from_stanza_node(thumbnail_node);
                if (thumbnail != null) {
                    metadata.thumbnails.add(thumbnail);
                }
            }
            metadata.hashes = new CryptographicHashes.Hashes.from_stanza_subnodes(node);
            return metadata;
        }

        public static FileMetadata? from_message(MessageStanza message) {
            StanzaNode? node = message.stanza.get_subnode("file", NS_URI);
            if (node == null) {
                return null;
            }
            printerr("Parsing metadata from message:\n");
            printerr("%s\n", node.to_xml());
            FileMetadata metadata = FileMetadata.from_stanza_node(node);
            if (metadata != null) {
                printerr("Parsed metadata:\n");
                printerr("%s\n", metadata.to_stanza_node().to_ansi_string(true));
            } else {
                printerr("Failed to parse metadata!\n");
            }
            return FileMetadata.from_stanza_node(node);
        }
    }
}
