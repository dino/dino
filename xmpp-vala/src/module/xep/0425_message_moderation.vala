namespace Xmpp.Xep.MessageModeration {

    public const string NS_URI = "urn:xmpp:message-moderate:1";


    /**
     * @return whether the moderation was successful
     */
    public static async bool moderate(XmppStream stream, Jid muc_jid, string message_id) {
        StanzaNode moderate_node = new StanzaNode.build("moderate", NS_URI)
                .add_self_xmlns()
                .put_attribute("id", message_id)
                .put_node(new StanzaNode.build("retract", Xep.MessageRetraction.NS_URI).add_self_xmlns());
        Iq.Stanza iq = new Iq.Stanza.set(moderate_node) { to = muc_jid };

        Iq.Stanza result_stanza = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
        return !result_stanza.is_error();
    }
}