namespace Xmpp.Xep.UserAvatars {
    private const string NS_URI = "urn:xmpp:avatar";
    private const string NS_URI_DATA = NS_URI + ":data";
    private const string NS_URI_METADATA = NS_URI + ":metadata";

    public void publish_png(XmppStream stream, uint8[] image, int width, int height) {
        string sha1 = Checksum.compute_for_data(ChecksumType.SHA1, image);
        StanzaNode data_node = new StanzaNode.build("data", NS_URI_DATA).add_self_xmlns()
                .put_node(new StanzaNode.text(Base64.encode(image)));
        stream.get_module(Pubsub.Module.IDENTITY).publish.begin(stream, null, NS_URI_DATA, sha1, data_node);

        StanzaNode metadata_node = new StanzaNode.build("metadata", NS_URI_METADATA).add_self_xmlns();
        StanzaNode info_node = new StanzaNode.build("info", NS_URI_METADATA)
                .put_attribute("bytes", image.length.to_string())
                .put_attribute("id", sha1)
                .put_attribute("width", width.to_string())
                .put_attribute("height", height.to_string())
                .put_attribute("type", "image/png");
        metadata_node.put_node(info_node);
        stream.get_module(Pubsub.Module.IDENTITY).publish.begin(stream, null, NS_URI_METADATA, sha1, metadata_node);
    }

    public async Bytes? fetch_image(XmppStream stream, Jid jid, string hash) {
        Gee.List<StanzaNode>? items = yield stream.get_module(Pubsub.Module.IDENTITY).request_all(stream, jid, NS_URI_DATA);
        if (items == null || items.size == 0 || items[0].sub_nodes.size == 0) return null;

        StanzaNode node = items[0].sub_nodes[0];
        string? id = items[0].get_attribute("id", Pubsub.NS_URI);
        if (id == null) return null;

        Bytes image = new Bytes.take(Base64.decode(node.get_string_content()));
        string sha1 = Checksum.compute_for_bytes(ChecksumType.SHA1, image);
        if (sha1 != id) {
            warning("sha sum did not match for avatar from %s expected=%s actual=%s", jid.to_string(), id, sha1);
            return null;
        }
        return image;
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0084_user_avatars");

        public signal void received_avatar_hash(XmppStream stream, Jid jid, string id);

        public override void attach(XmppStream stream) {
            stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NS_URI_METADATA, on_pupsub_event, null);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Pubsub.Module.IDENTITY).remove_filtered_notification(stream, NS_URI_METADATA);
        }


        public void on_pupsub_event(XmppStream stream, Jid jid, string hash, StanzaNode? node) {
            StanzaNode? info_node = node.get_subnode("info", NS_URI_METADATA);
            string? type = info_node == null ? null : info_node.get_attribute("type");
            if (type != "image/png" && type != "image/jpeg") return;
            received_avatar_hash(stream, jid, hash);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
