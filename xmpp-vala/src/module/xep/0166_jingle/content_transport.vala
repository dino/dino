namespace Xmpp.Xep.Jingle {

    public interface Transport : Object {
        public abstract string ns_uri { get; }
        public async abstract bool is_transport_available(XmppStream stream, uint8 components, Jid full_jid);
        public abstract TransportType type_ { get; }
        public abstract int priority { get; }
        public abstract TransportParameters create_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid) throws Error;
        public abstract TransportParameters parse_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws IqError;
    }

    public enum TransportType {
        DATAGRAM,
        STREAMING,
    }

    // Gets a null `stream` if connection setup was unsuccessful and another
    // transport method should be tried.
    public interface TransportParameters : Object {
        public abstract string ns_uri { get; }
        public abstract uint8 components { get; }

        public abstract void set_content(Content content);
        public abstract StanzaNode to_transport_stanza_node();
        public abstract void handle_transport_accept(StanzaNode transport) throws IqError;
        public abstract void handle_transport_info(StanzaNode transport) throws IqError;
        public abstract void create_transport_connection(XmppStream stream, Content content);
    }
}