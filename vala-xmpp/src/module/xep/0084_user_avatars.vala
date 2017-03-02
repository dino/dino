using Xmpp.Core;

namespace Xmpp.Xep.UserAvatars {
    private const string NS_URI = "urn:xmpp:avatar";
    private const string NS_URI_DATA = NS_URI + ":data";
    private const string NS_URI_METADATA = NS_URI + ":metadata";

    public class Module : XmppStreamModule {
        public const string ID = "0084_user_avatars";

        public signal void received_avatar(XmppStream stream, string jid, string id);

        private PixbufStorage storage;

        public Module(PixbufStorage storage) {
            this.storage = storage;
        }

        public void publish_png(XmppStream stream, uint8[] image, int width, int height) {
            string sha1 = Checksum.compute_for_data(ChecksumType.SHA1, image);
            StanzaNode data_node = new StanzaNode.build("data", NS_URI_DATA).add_self_xmlns()
                    .put_node(new StanzaNode.text(Base64.encode(image)));
            Pubsub.Module.get_module(stream).publish(stream, null, NS_URI_DATA, NS_URI_DATA, sha1, data_node);

            StanzaNode metadata_node = new StanzaNode.build("metadata", NS_URI_METADATA).add_self_xmlns();
            StanzaNode info_node = new StanzaNode.build("info", NS_URI_METADATA)
                .put_attribute("bytes", image.length.to_string())
                .put_attribute("id", sha1)
                .put_attribute("width", width.to_string())
                .put_attribute("height", height.to_string())
                .put_attribute("type", "image/png");
            metadata_node.put_node(info_node);
            Pubsub.Module.get_module(stream).publish(stream, null, NS_URI_METADATA, NS_URI_METADATA, sha1, metadata_node);
        }

        private class PublishResponseListenerImpl : Pubsub.PublishResponseListener, Object {
            PublishResponseListener listener;
            PublishResponseListenerImpl other;
            public PublishResponseListenerImpl(PublishResponseListener listener, PublishResponseListenerImpl other) {
                this.listener = listener;
                this.other = other;
            }
            public void on_success(XmppStream stream) { listener.on_success(stream); }
            public void on_error(XmppStream stream) { listener.on_error(stream); }
        }

        public override void attach(XmppStream stream) {
            Pubsub.Module.require(stream);
            Pubsub.Module.get_module(stream).add_filtered_notification(stream, NS_URI_METADATA, new PubsubEventListenerImpl(storage));
        }

        public override void detach(XmppStream stream) { }

        class PubsubEventListenerImpl : Pubsub.EventListener, Object {
            PixbufStorage storage;
            public PubsubEventListenerImpl(PixbufStorage storage) { this.storage = storage; }
            public void on_result(XmppStream stream, string jid, string id, StanzaNode node) {
                StanzaNode info_node = node.get_subnode("info", NS_URI_METADATA);
                if (info_node.get_attribute("type") != "image/png") return;
                if (storage.has_image(id)) {
                    Module.get_module(stream).received_avatar(stream, jid, id);
                } else {
                    Pubsub.Module.get_module(stream).request(stream, jid, NS_URI_DATA, new PubsubRequestResponseListenerImpl(storage));
                }
            }
        }

        class PubsubRequestResponseListenerImpl : Pubsub.RequestResponseListener, Object {
            PixbufStorage storage;
            public PubsubRequestResponseListenerImpl(PixbufStorage storage) { this.storage = storage; }
            public void on_result(XmppStream stream, string jid, string id, StanzaNode node) {
                storage.store(id, Base64.decode(node.get_string_content()));
                Module.get_module(stream).received_avatar(stream, jid, id);
            }
        }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(NS_URI, ID);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stderr.printf("UserAvatarsModule required but not attached!\n");
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }

    public interface PublishResponseListener : Object {
        public abstract void on_success(XmppStream stream);
        public abstract void on_error(XmppStream stream);
    }
}
