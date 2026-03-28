using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Jingle {

    public interface ContentType : Object {
        public abstract string ns_uri { get; }
        public abstract TransportType required_transport_type { get; }
        public abstract uint8 required_components { get; }
        public abstract ContentParameters parse_content_parameters(StanzaNode description) throws IqError;
    }

    public interface ContentParameters : Object {
        /** Called when the counterpart proposes the content */
        public abstract async void handle_proposed_content(XmppStream stream, Jingle.Session session, Content content);

        /** Called when we accept the content that was proposed by the counterpart */
        public abstract void accept(XmppStream stream, Jingle.Session session, Jingle.Content content);
        /** Called when the counterpart accepts the content that was proposed by us*/
        public abstract void handle_accept(XmppStream stream, Jingle.Session session, Jingle.Content content, StanzaNode description_node);

        public abstract void terminate(bool we_terminated, string? reason_name, string? reason_text);

        public abstract StanzaNode get_description_node();
    }
}