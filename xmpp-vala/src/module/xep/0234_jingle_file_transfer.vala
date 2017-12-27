using Xmpp.Core;

namespace Xmpp.Xep.JingleFileTransfer {
    private const string NS_URI = "urn:xmpp:jingle:apps:file-transfer:5";

    public StanzaNode generate_file_element(string? name, string? media_type, int? size) {
        //string sha1 = Checksum.compute_for_data(ChecksumType.SHA1, image);
        StanzaNode file_node = new StanzaNode.build("file", NS_URI).add_self_xmlns();
        if (name != null) {
            StanzaNode name_node = new StanzaNode.build("name", NS_URI);
            name_node.put_node(new StanzaNode.text(name));
            file_node.put_node(name_node);
        }
        if (media_type != null) {
            StanzaNode media_type_node = new StanzaNode.build("media-type", NS_URI);
            media_type_node.put_node(new StanzaNode.text(media_type));
            file_node.put_node(media_type_node);
        }
        if (size != null) {
            StanzaNode size_node = new StanzaNode.build("size", NS_URI);
            size_node.put_node(new StanzaNode.text(size.to_string()));
            file_node.put_node(size_node);
        }
        return file_node;
    }
}
