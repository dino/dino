namespace Xmpp.Xep.VCard {
private const string NS_URI = "vcard-temp";
private const string NS_URI_UPDATE = NS_URI + ":x:update";

public async Bytes? fetch_image(XmppStream stream, Jid jid, string hash) {
    Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("vCard", NS_URI).add_self_xmlns()) { to=jid };
    Iq.Stanza iq_res = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);

    if (iq_res.is_error()) return null;
    string? res = iq_res.stanza.get_deep_string_content(@"$NS_URI:vCard", "PHOTO", "BINVAL");
    if (res == null) return null;
    Bytes content = new Bytes.take(Base64.decode(res));
    string sha1 = Checksum.compute_for_bytes(ChecksumType.SHA1, content);
    if (sha1 != hash) return null;

    return content;
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0153_vcard_based_avatars");

    public signal void received_avatar_hash(XmppStream stream, Jid jid, string hash);

    public override void attach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
        if (presence.type_ != Presence.Stanza.TYPE_AVAILABLE) {
            return;
        }
        StanzaNode? update_node = presence.stanza.get_subnode("x", NS_URI_UPDATE);
        if (update_node == null) return;
        StanzaNode? photo_node = update_node.get_subnode("photo", NS_URI_UPDATE);
        if (photo_node == null) return;
        string? sha1 = photo_node.get_string_content();
        if (sha1 == null) return;
        received_avatar_hash(stream, presence.from, sha1);
    }
}
}
