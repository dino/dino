namespace Xmpp.Xep.JingleContentThumbnails {
    public const string NS_URI = "urn:xmpp:thumbs:1";
    public const string STANZA_NAME = "thumbnail";

    public class Thumbnail {
        public string uri;
        public string? media_type;
        public int width;
        public int height;

        const string URI_ATTRIBUTE = "uri";
        const string MIME_ATTRIBUTE = "media-type";
        const string WIDTH_ATTRIBUTE = "width";
        const string HEIGHT_ATTRIBUTE = "height";

        public StanzaNode to_stanza_node() {
            StanzaNode node = new StanzaNode.build(STANZA_NAME, NS_URI).add_self_xmlns()
                    .put_attribute(URI_ATTRIBUTE, this.uri);
            if (this.media_type != null) {
                node.put_attribute(MIME_ATTRIBUTE, this.media_type);
            }
            if (this.width != -1) {
                node.put_attribute(WIDTH_ATTRIBUTE, this.width.to_string());
            }
            if (this.height != -1) {
                node.put_attribute(HEIGHT_ATTRIBUTE, this.height.to_string());
            }
            return node;
        }

        public static Thumbnail? from_stanza_node(StanzaNode node) {
            Thumbnail thumbnail = new Thumbnail();
            thumbnail.uri = node.get_attribute(URI_ATTRIBUTE);
            if (thumbnail.uri == null) {
                return null;
            }
            thumbnail.media_type = node.get_attribute(MIME_ATTRIBUTE);
            string? width = node.get_attribute(WIDTH_ATTRIBUTE);
            if (width != null) {
                thumbnail.width = int.parse(width);
            }
            string? height = node.get_attribute(HEIGHT_ATTRIBUTE);
            if (height != null) {
                thumbnail.height = int.parse(height);
            }
            return thumbnail;
        }
    }
}