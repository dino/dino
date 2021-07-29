using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Jingle {

    public interface SessionInfoNs : Object {
        public abstract string ns_uri { get; }

        public abstract void handle_content_session_info(XmppStream stream, Session session, StanzaNode info, Iq.Stanza iq) throws IqError;
    }
}