namespace Xmpp.Xep.VCard {
private const string NS_URI = "vcard-temp";
private const string NS_URI_UPDATE = NS_URI + ":x:update";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0153_vcard_based_avatars");

    public signal void received_avatar(XmppStream stream, Jid jid, string id);

    private PixbufStorage storage;

    public Module(PixbufStorage storage) {
        this.storage = storage;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
        StanzaNode? update_node = presence.stanza.get_subnode("x", NS_URI_UPDATE);
        if (update_node == null) return;
        StanzaNode? photo_node = update_node.get_subnode("photo", NS_URI_UPDATE);
        if (photo_node == null) return;
        string? sha1 = photo_node.get_string_content();
        if (sha1 == null) return;
        if (storage.has_image(sha1)) {
            if (stream.get_flag(Muc.Flag.IDENTITY).is_occupant(presence.from)) {
                received_avatar(stream, presence.from, sha1);
            } else {
                received_avatar(stream, presence.from.bare_jid, sha1);
            }
        } else {
            Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("vCard", NS_URI).add_self_xmlns());
            if (stream.get_flag(Muc.Flag.IDENTITY).is_occupant(presence.from)) {
                iq.to = presence.from;
            } else {
                iq.to = presence.from.bare_jid;
            }
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, on_received_vcard);
        }
    }

    private void on_received_vcard(XmppStream stream, Iq.Stanza iq) {
        if (iq.is_error()) return;
        string? res = iq.stanza.get_deep_string_content(@"$NS_URI:vCard", "PHOTO", "BINVAL");
        if (res == null) return;
        uint8[] content = Base64.decode(res);
        string sha1 = Checksum.compute_for_data(ChecksumType.SHA1, content);
        storage.store(sha1, content);
        stream.get_module(IDENTITY).received_avatar(stream, iq.from, sha1);
    }
}
}
