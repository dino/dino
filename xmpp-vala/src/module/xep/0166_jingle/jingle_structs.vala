using Gee;
using Xmpp;

namespace Xmpp.Xep.Jingle {

    public errordomain IqError {
        BAD_REQUEST,
        NOT_ACCEPTABLE,
        NOT_IMPLEMENTED,
        UNSUPPORTED_INFO,
        OUT_OF_ORDER,
        RESOURCE_CONSTRAINT,
    }

    public errordomain Error {
        GENERAL,
        BAD_REQUEST,
        INVALID_PARAMETERS,
        UNSUPPORTED_TRANSPORT,
        UNSUPPORTED_SECURITY,
        NO_SHARED_PROTOCOLS,
        TRANSPORT_ERROR,
    }

    public enum Senders {
        BOTH,
        INITIATOR,
        NONE,
        RESPONDER;

        public string to_string() {
            switch (this) {
                case BOTH: return "both";
                case INITIATOR: return "initiator";
                case NONE: return "none";
                case RESPONDER: return "responder";
            }
            assert_not_reached();
        }

        public static Senders parse(string? senders) throws IqError {
            if (senders == null) return Senders.BOTH;
            switch (senders) {
                case "initiator": return Senders.INITIATOR;
                case "responder": return Senders.RESPONDER;
                case "both": return Senders.BOTH;
            }
            throw new IqError.BAD_REQUEST(@"invalid role $(senders)");
        }
    }

    public enum Role {
        INITIATOR,
        RESPONDER;

        public string to_string() {
            switch (this) {
                case INITIATOR: return "initiator";
                case RESPONDER: return "responder";
            }
            assert_not_reached();
        }

        public static Role parse(string role) throws IqError {
            switch (role) {
                case "initiator": return INITIATOR;
                case "responder": return RESPONDER;
            }
            throw new IqError.BAD_REQUEST(@"invalid role $(role)");
        }
    }

}