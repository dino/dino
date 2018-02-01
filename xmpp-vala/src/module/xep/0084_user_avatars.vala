namespace Xmpp.Xep.UserAvatars {
    private const string NS_URI = "urn:xmpp:avatar";
    private const string NS_URI_DATA = NS_URI + ":data";
    private const string NS_URI_METADATA = NS_URI + ":metadata";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0084_user_avatars");

        public signal void received_avatar(XmppStream stream, Jid jid, string id);

        private PixbufStorage storage;

        public Module(PixbufStorage storage) {
            this.storage = storage;
        }

        public void publish_png(XmppStream stream, uint8[] image, int width, int height) {
            string sha1 = Checksum.compute_for_data(ChecksumType.SHA1, image);
            StanzaNode data_node = new StanzaNode.build("data", NS_URI_DATA).add_self_xmlns()
                    .put_node(new StanzaNode.text(Base64.encode(image)));
            stream.get_module(Pubsub.Module.IDENTITY).publish(stream, null, NS_URI_DATA, NS_URI_DATA, sha1, data_node);

            StanzaNode metadata_node = new StanzaNode.build("metadata", NS_URI_METADATA).add_self_xmlns();
            StanzaNode info_node = new StanzaNode.build("info", NS_URI_METADATA)
                .put_attribute("bytes", image.length.to_string())
                .put_attribute("id", sha1)
                .put_attribute("width", width.to_string())
                .put_attribute("height", height.to_string())
                .put_attribute("type", "image/png");
            metadata_node.put_node(info_node);
            stream.get_module(Pubsub.Module.IDENTITY).publish(stream, null, NS_URI_METADATA, NS_URI_METADATA, sha1, metadata_node);
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NS_URI_METADATA, on_pupsub_event);
        }

        public override void detach(XmppStream stream) { }


        public void on_pupsub_event(XmppStream stream, Jid jid, string id, StanzaNode? node) {
            StanzaNode? info_node = node.get_subnode("info", NS_URI_METADATA);
            if (info_node == null || info_node.get_attribute("type") != "image/png") return;
            if (storage.has_image(id)) {
                stream.get_module(Module.IDENTITY).received_avatar(stream, jid, id);
            } else {
                stream.get_module(Pubsub.Module.IDENTITY).request(stream, jid, NS_URI_DATA, on_pubsub_data_response);
            }
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void on_pubsub_data_response(XmppStream stream, Jid jid, string? id, StanzaNode? node) {
            if (node == null) return;
            storage.store(id, Base64.decode(node.get_string_content()));
            stream.get_module(Module.IDENTITY).received_avatar(stream, jid, id);
        }
    }
}
