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
                    .put_attribute("date", this.date.to_string())
                    .put_attribute("media_type", this.mime_type)
                    .put_attribute("name", this.name)
                    .put_attribute("size", this.size.to_string());
            if (this.desc != null) {
                node.put_attribute("desc", this.desc);
            }
            if (this.width != -1) { // Checks if file is a image
            node.put_attribute("width", this.width.to_string());
                node.put_attribute("height", this.height.to_string());
            }
            if (this.length != -1) { // Checks if file is a video
            node.put_attribute("length", this.length.to_string());
            }
            message.stanza.put_node(node);
        }

        public static FileMetadata? from_message(MessageStanza message) {
            StanzaNode? node = message.stanza.get_subnode("file", NS_URI);
            FileMetadata metadata = new FileMetadata();
            if (node == null) {
                return null;
            }
            metadata.name = node.get_attribute("name");
            metadata.desc = node.get_attribute("desc");
            metadata.mime_type = node.get_attribute("media_type");
            metadata.size = node.get_attribute_uint("size");
            metadata.date = new DateTime.from_iso8601(node.get_attribute("date"), null);
            metadata.width = node.get_attribute_int("width", -1);
            metadata.height = node.get_attribute_int("height", -1);
            metadata.length = node.get_attribute_int("length", -1);
            return metadata;
        }
    }
}
