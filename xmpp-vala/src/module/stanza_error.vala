using Gee;

namespace Xmpp {

    private const string ERROR_NS_URI = "urn:ietf:params:xml:ns:xmpp-stanzas";

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

        public string? text {
            get { return error_node.get_deep_string_content(ERROR_NS_URI + ":text"); }
        }

        public string condition {
            get {
                Gee.List<StanzaNode> subnodes = error_node.sub_nodes;
                foreach (StanzaNode subnode in subnodes) { // TODO get subnode by ns
                    if (subnode.ns_uri == ERROR_NS_URI) {
                        return subnode.name;
                    }
                }
                return CONDITION_UNDEFINED_CONDITION; // TODO hm!
            }
        }

        public string type_ {
            get { return error_node.get_attribute("type"); }
        }

        public StanzaNode error_node;

        public ErrorStanza.from_stanza(StanzaNode stanza) {
            error_node = stanza.get_subnode("error");
        }

        public ErrorStanza.build(string type, string condition, string? human_readable, StanzaNode? application_condition) {
            error_node = new StanzaNode.build("error")
                .put_attribute("type", type)
                .put_node(new StanzaNode.build(condition, ERROR_NS_URI).add_self_xmlns());
            if (application_condition != null) {
                error_node.put_node(application_condition);
            }
            if (human_readable != null) {
                error_node.put_node(new StanzaNode.build("text", ERROR_NS_URI)
                    .add_self_xmlns()
                    .put_attribute("xml:lang", "en")
                    .put_node(new StanzaNode.text(text))
                );
            }
        }
        public ErrorStanza.bad_request(string? human_readable = null) {
            this.build(TYPE_MODIFY, CONDITION_BAD_REQUEST, human_readable, null);
        }
        public ErrorStanza.feature_not_implemented(StanzaNode? application_condition = null) {
            this.build(TYPE_MODIFY, CONDITION_FEATURE_NOT_IMPLEMENTED, null, application_condition);
        }
        public ErrorStanza.item_not_found(StanzaNode? application_condition = null) {
            this.build(TYPE_CANCEL, CONDITION_ITEM_NOT_FOUND, null, application_condition);
        }
        public ErrorStanza.not_acceptable(string? human_readable = null) {
            this.build(TYPE_MODIFY, CONDITION_NOT_ACCEPTABLE, human_readable, null);
        }
        public ErrorStanza.service_unavailable() {
            this.build(TYPE_CANCEL, CONDITION_SERVICE_UNAVAILABLE, null, null);
        }
    }
}
