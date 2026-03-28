namespace Xmpp.Xep.MucSelfPing {

    public static async bool is_joined(XmppStream stream, Jid jid) {
        Iq.Stanza iq_result = yield stream.get_module(Xmpp.Xep.Ping.Module.IDENTITY).send_ping(stream, jid);

        if (!iq_result.is_error()) {
            return true;
        } else {
            var error_stanza = iq_result.get_error();
            if (error_stanza.condition in new string[] {ErrorStanza.CONDITION_SERVICE_UNAVAILABLE, ErrorStanza.CONDITION_FEATURE_NOT_IMPLEMENTED}) {
                // the client is joined, but the pinged client does not implement XMPP Ping
                return true;
            }
        }
        return false;
    }

}
