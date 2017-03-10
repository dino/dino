using Xmpp.Core;

namespace Xmpp.Xep.VCard {
private const string NS_URI = "vcard-temp";
private const string NS_URI_UPDATE = NS_URI + ":x:update";

public class Module : XmppStreamModule {
    public const string ID = "0027_current_pgp_usage";
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

    public signal void received_avatar(XmppStream stream, string jid, string id);

    private PixbufStorage storage;

    public Module(PixbufStorage storage) {
        this.storage = storage;
    }

    public override void attach(XmppStream stream) {
        Iq.Module.require(stream);
        Presence.Module.require(stream);
        Presence.Module.get_module(stream).received_presence.connect(on_received_presence);
    }

    public override void detach(XmppStream stream) {
        Presence.Module.get_module(stream).received_presence.disconnect(on_received_presence);
    }

    public static Module? get_module(XmppStream stream) {
        return (Module?) stream.get_module(IDENTITY);
    }

    public static void require(XmppStream stream) {
        if (get_module(stream) == null) stderr.printf("VCardModule required but not attached!\n"); ;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return ID; }

    private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
        StanzaNode? update_node = presence.stanza.get_subnode("x", NS_URI_UPDATE);
        if (update_node == null) return;
        StanzaNode? photo_node = update_node.get_subnode("photo", NS_URI_UPDATE);
        if (photo_node == null) return;
        string? sha1 = photo_node.get_string_content();
        if (sha1 == null) return;
        if (storage.has_image(sha1)) {
            if (Muc.Flag.get_flag(stream).is_occupant(presence.from)) {
                received_avatar(stream, presence.from, sha1);
            } else {
                received_avatar(stream, get_bare_jid(presence.from), sha1);
            }
        } else {
            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("vCard", NS_URI).add_self_xmlns());
            if (Muc.Flag.get_flag(stream).is_occupant(presence.from)) {
                iq.to = presence.from;
            } else {
                iq.to = get_bare_jid(presence.from);
            }
            Iq.Module.get_module(stream).send_iq(stream, iq, new IqResponseListenerImpl(this, storage, sha1));
        }
    }

    private class IqResponseListenerImpl : Iq.ResponseListener, Object {
        Module outer;
        PixbufStorage storage;
        string id;
        public IqResponseListenerImpl(Module outer, PixbufStorage storage, string id) {
            this.outer = outer;
            this.id = id;
            this.storage = storage;
        }
        public void on_result(XmppStream stream, Iq.Stanza iq) {
            if (iq.is_error()) return;
            StanzaNode? vcard_node = iq.stanza.get_subnode("vCard", NS_URI);
            if (vcard_node == null) return;
            StanzaNode? photo_node = vcard_node.get_subnode("PHOTO", NS_URI);
            if (photo_node == null) return;
            StanzaNode? binary_node = photo_node.get_subnode("BINVAL", NS_URI);
            if (binary_node == null) return;
            string? content = binary_node.get_string_content();
            if (content == null) return;
            storage.store(id, Base64.decode(content));
            outer.received_avatar(stream, iq.from, id);
        }
    }
}
}
