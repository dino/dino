using Xmpp.Core;

namespace Xmpp {

    public class Stanza : Object {

        public const string ATTRIBUTE_FROM = "from";
        public const string ATTRIBUTE_ID = "id";
        public const string ATTRIBUTE_TO = "to";
        public const string ATTRIBUTE_TYPE = "type";

        public const string TYPE_ERROR = "error";

        private string? my_jid;

        public virtual string? from {
            owned get {
                string? from_attribute = stanza.get_attribute(ATTRIBUTE_FROM);
                // "when a client receives a stanza that does not include a 'from' attribute, it MUST assume that the stanza
                // is from the user's account on the server." (RFC6120 8.1.2.1)
                if (from_attribute != null) return from_attribute;
                if (my_jid != null) {
                    string my_bare_jid = get_bare_jid(my_jid); // has to be left-side value
                    return my_bare_jid;
                }
                return null;
            }
            set { stanza.set_attribute(ATTRIBUTE_FROM, value); }
        }

        public virtual string? id {
            get { return stanza.get_attribute(ATTRIBUTE_ID); }
            set { stanza.set_attribute(ATTRIBUTE_ID, value); }
        }

        public virtual string? to {
            owned get {
                string? to_attribute = stanza.get_attribute(ATTRIBUTE_TO);
                // "if the stanza does not include a 'to' address then the client MUST treat it as if the 'to' address were
                // included with a value of the client's full JID." (RFC6120 8.1.1.1)
                return to_attribute == null ? my_jid : to_attribute;
            }
            set { stanza.set_attribute(ATTRIBUTE_TO, value); }
        }

        public virtual string? type_ {
            get { return stanza.get_attribute(ATTRIBUTE_TYPE); }
            set { stanza.set_attribute(ATTRIBUTE_TYPE, value); }
        }

        public StanzaNode stanza;

        public Stanza.incoming(StanzaNode stanza, string? my_jid) {
            this.stanza = stanza;
            this.my_jid = my_jid;
        }

        public Stanza.outgoing(StanzaNode stanza) {
            this.stanza = stanza;
        }

        public bool is_error() {
            return type_ == TYPE_ERROR;
        }

        public ErrorStanza? get_error() {
            return new ErrorStanza.from_stanza(this.stanza);
        }
    }
}