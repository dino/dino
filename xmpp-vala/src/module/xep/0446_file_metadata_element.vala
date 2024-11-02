namespace Xmpp.Xep.FileMetadataElement {
    public const string NS_URI = "urn:xmpp:file:metadata:0";

    public class FileMetadata {
        public string? name { get; set; }
        public string? mime_type { get; set; }
        public int64 size { get; set; default=-1; }
        public string? desc { get; set; }
        public DateTime? date { get; set; }
        public int width { get; set; default=-1; } // Width of image in pixels
        public int height { get; set; default=-1; } // Height of image in pixels
        public Gee.List<CryptographicHashes.Hash> hashes = new Gee.ArrayList<CryptographicHashes.Hash>();
        public int64 length { get; set; default=-1; } // Length of audio/video in milliseconds
        public Gee.List<Xep.JingleContentThumbnails.Thumbnail> thumbnails = new Gee.ArrayList<Xep.JingleContentThumbnails.Thumbnail>();

        public StanzaNode to_stanza_node() {
            StanzaNode node = new StanzaNode.build("file", NS_URI).add_self_xmlns();

            if (this.name != null) {
                node.put_node(new StanzaNode.build("name", NS_URI).put_node(new StanzaNode.text(this.name)));
            }
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
            foreach (var hash in hashes) {
                node.put_node(hash.to_stanza_node());
            }
            foreach (Xep.JingleContentThumbnails.Thumbnail thumbnail in this.thumbnails) {
                node.put_node(thumbnail.to_stanza_node());
            }
            return node;
        }
    }

    public static FileMetadata? get_file_metadata(StanzaNode node) {
        StanzaNode? file_node = node.get_subnode("file", Xep.FileMetadataElement.NS_URI);
        if (file_node == null) return null;

        FileMetadata metadata = new FileMetadata();

        StanzaNode? name_node = file_node.get_subnode("name");
        if (name_node != null && name_node.get_string_content() != null) {
            metadata.name = name_node.get_string_content();
        }

        StanzaNode? desc_node = file_node.get_subnode("desc");
        if (desc_node != null && desc_node.get_string_content() != null) {
            metadata.desc = desc_node.get_string_content();
        }
        StanzaNode? mime_node = file_node.get_subnode("media_type");
        if (mime_node != null && mime_node.get_string_content() != null) {
            metadata.mime_type = mime_node.get_string_content();
        }
        StanzaNode? size_node = file_node.get_subnode("size");
        if (size_node != null && size_node.get_string_content() != null) {
            metadata.size = int64.parse(size_node.get_string_content());
        }
        StanzaNode? date_node = file_node.get_subnode("date");
        if (date_node != null && date_node.get_string_content() != null) {
            metadata.date = new DateTime.from_iso8601(date_node.get_string_content(), null);
        }
        StanzaNode? width_node = file_node.get_subnode("width");
        if (width_node != null && width_node.get_string_content() != null) {
            metadata.width = int.parse(width_node.get_string_content());
        }
        StanzaNode? height_node = file_node.get_subnode("height");
        if (height_node != null && height_node.get_string_content() != null) {
            metadata.height = int.parse(height_node.get_string_content());
        }
        StanzaNode? length_node = file_node.get_subnode("length");
        if (length_node != null && length_node.get_string_content() != null) {
            metadata.length = int.parse(length_node.get_string_content());
        }
        metadata.thumbnails = Xep.JingleContentThumbnails.get_thumbnails(file_node);
        metadata.hashes = CryptographicHashes.get_hashes(file_node);
        return metadata;
    }
}
