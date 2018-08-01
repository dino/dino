using Gee;

namespace Xmpp {

    public class ErrorStanza {
        public const string CONDITION_BAD_REQUEST = "bad-request";
        public const string CONDITION_CONFLICT = "conflict";
        public const string CONDITION_FEATURE_NOT_IMPLEMENTED = "feature-not-implemented";
        public const string CONDITION_FORBIDDEN = "forbidden";
        public const string CONDITION_GONE = "gone";
        public const string CONDITION_INTERNAL_SERVER_ERROR = "internal-server-error";
        public const string CONDITION_ITEM_NOT_FOUND = "item-not-found";
        public const string CONDITION_JID_MALFORMED = "jid-malformed";
        public const string CONDITION_NOT_ACCEPTABLE = "not-acceptable";
        public const string CONDITION_NOT_ALLOWED = "not-allowed";
        public const string CONDITION_NOT_AUTHORIZED = "not-authorized";
        public const string CONDITION_POLICY_VIOLATION = "policy-violation";
        public const string CONDITION_RECIPIENT_UNAVAILABLE = "recipient-unavailable";
        public const string CONDITION_REDIRECT = "redirect";
        public const string CONDITION_REGISTRATION_REQUIRED = "registration-required";
        public const string CONDITION_REMOTE_SERVER_NOT_FOUND = "remote-server-not-found";
        public const string CONDITION_REMOTE_SERVER_TIMEOUT = "remote-server-timeout";
        public const string CONDITION_RESOURCE_CONSTRAINT = "resource-constraint";
        public const string CONDITION_SERVICE_UNAVAILABLE = "service-unavailable";
        public const string CONDITION_SUBSCRIPTION_REQUIRED = "subscription-required";
        public const string CONDITION_UNDEFINED_CONDITION = "undefined-condition";
        public const string CONDITION_UNEXPECTED_REQUEST = "unexpected-request";

        public const string TYPE_AUTH = "auth";
        public const string TYPE_CANCEL = "cancel";
        public const string TYPE_CONTINUE = "continue";
        public const string TYPE_MODIFY = "modify";
        public const string TYPE_WAIT = "wait";

        public string? by {
            get { return error_node.get_attribute("by"); }
        }

        public string condition {
            get {
                Gee.List<StanzaNode> subnodes = error_node.sub_nodes;
                foreach (StanzaNode subnode in subnodes) { // TODO get subnode by ns
                    if (subnode.ns_uri == "urn:ietf:params:xml:ns:xmpp-stanzas") {
                        return subnode.name;
                    }
                }
                return CONDITION_UNDEFINED_CONDITION; // TODO hm!
            }
        }

        public string? original_id {
            get { return stanza.get_attribute("id"); }
        }

        public string type_ {
            get { return error_node.get_attribute("type"); }
        }

        public StanzaNode stanza;
        private StanzaNode error_node;

        public ErrorStanza.from_stanza(StanzaNode stanza) {
            this.stanza = stanza;
            error_node = stanza.get_subnode("error");
        }
    }
}
