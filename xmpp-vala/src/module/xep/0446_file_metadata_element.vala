namespace Xmpp.Xep.FileMetadataElement {
    public const string NS_URI = "urn:xmpp:file:metadata:0";

    public class FileMetadata {
        public string? name = null;
        public string? desc = null;
        public string? mime_type = null;
        public int64 size = -1;
        public DateTime? date = null;
        public int width = -1; // Width of image in pixels
	    public int height = -1; // Height of image in pixels
	    // public hash;
	    public int length = -1; // Length of audio/video in milliseconds
	    // public thumbnail;

        public FileMetadata.file(File file) {
            FileInfo info = file.query_info("*", FileQueryInfoFlags.NONE);
            this.name = info.get_name();
            this.desc = null; //
            this.mime_type = info.get_content_type();
            this.size = info.get_size();
            this.date = info.get_modification_date_time();
        }

        public void debug_print() {
            printerr("File: '%s'\n", this.name);
            if (this.desc != null) {
                printerr("  Description: '%s'\n", this.desc);
            }
            printerr("  Mime type: %s\n", this.mime_type);
            printerr("  Size: %s bytes\n", this.size.to_string());
            printerr("  Last change: %s\n", this.date.to_string());
            if (this.width != -1 && this.height != -1) {
                printerr("  Image width: %s\n", this.width.to_string());
                printerr("  Image height: %s\n", this.height.to_string());
            }
            if (this.length != -1) {
                printerr("  Video length: %s\n", this.mime_type);
            }
        }

        public void add_to_message(MessageStanza message) {
            StanzaNode node = new StanzaNode.build("file", NS_URI).add_self_xmlns()
                    .put_node(new StanzaNode.build("name", NS_URI).put_node(new StanzaNode.text(this.name)))
                    .put_node(new StanzaNode.build("media_type", NS_URI).put_node(new StanzaNode.text(this.mime_type)))
                    .put_node(new StanzaNode.build("size", NS_URI).put_node(new StanzaNode.text(this.size.to_string())))
                    .put_node(new StanzaNode.build("date", NS_URI).put_node(new StanzaNode.text(this.date.to_string())));
            if (this.desc != null) {
                node.put_node(new StanzaNode.build("desc", NS_URI).put_node(new StanzaNode.text(this.desc)));
            }
            if (this.width != -1 && this.height != -1) {
                node.put_node(new StanzaNode.build("width", NS_URI).put_node(new StanzaNode.text(this.width.to_string())));
                node.put_node(new StanzaNode.build("height", NS_URI).put_node(new StanzaNode.text(this.height.to_string())));
            }
            if (this.length != -1) {
                node.put_node(new StanzaNode.build("length", NS_URI).put_node(new StanzaNode.text(this.length.to_string())));
            }
            message.stanza.put_node(node);
        }

        public static FileMetadata? from_message(MessageStanza message) {
            StanzaNode? node = message.stanza.get_subnode("file", NS_URI);
            FileMetadata metadata = new FileMetadata();
            if (node == null) {
                return null;
            }
            // TODO: null checks, on the subnodes as well as on the final values
            metadata.name = node.get_subnode("name", NS_URI).get_string_content();
            metadata.desc = node.get_subnode("desc", NS_URI).get_string_content();
            metadata.mime_type = node.get_subnode("media_type", NS_URI).get_string_content();
            metadata.size = int64.parse(node.get_subnode("size", NS_URI).get_string_content());
            metadata.date = new DateTime.from_iso8601(node.get_subnode("date", NS_URI).get_string_content(), null);
            StanzaNode? width_node = node.get_subnode("width", NS_URI);
            if (width_node != null) {
                metadata.width = int.parse(width_node.get_string_content());
            }
            StanzaNode? height_node = node.get_subnode("height", NS_URI);
            if (height_node != null) {
                metadata.height = int.parse(height_node.get_string_content());
            }
            StanzaNode? length_node = node.get_subnode("length", NS_URI);
            if (length_node != null) {
                metadata.length = int.parse(length_node.get_string_content());
            }
            return metadata;
        }
    }
}
