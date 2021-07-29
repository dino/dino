using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Jingle {

    public interface SecurityPrecondition : Object {
        public abstract string security_ns_uri();
        public abstract SecurityParameters? create_security_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, Object options) throws Jingle.Error;
        public abstract SecurityParameters? parse_security_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode security) throws IqError;
    }

    public interface SecurityParameters : Object {
        public abstract string security_ns_uri();
        public abstract StanzaNode to_security_stanza_node(XmppStream stream, Jid local_full_jid, Jid peer_full_jid);
        public abstract IOStream wrap_stream(IOStream stream);
    }
}