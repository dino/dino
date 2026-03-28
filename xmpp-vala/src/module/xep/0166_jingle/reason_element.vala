using Gee;
using Xmpp;

namespace  Xmpp.Xep.Jingle.ReasonElement {
    public const string ALTERNATIVE_SESSION = "alternative-session";
    public const string BUSY = "busy";
    public const string CANCEL = "cancel";
    public const string CONNECTIVITY_ERROR = "connectivity-error";
    public const string DECLINE = "decline";
    public const string EXPIRED = "expired";
    public const string FAILED_APPLICATION = "failed_application";
    public const string FAILED_TRANSPORT = "failed_transport";
    public const string GENERAL_ERROR = "general-error";
    public const string GONE = "gone";
    public const string INCOMPATIBLE_PARAMETERS = "incompatible-parameters";
    public const string MEDIA_ERROR = "media-error";
    public const string SECURITY_ERROR = "security-error";
    public const string SUCCESS = "success";
    public const string TIMEOUT = "timeout";
    public const string UNSUPPORTED_APPLICATIONS = "unsupported-applications";
    public const string UNSUPPORTED_TRANSPORTS = "unsupported-transports";

    public const string[] NORMAL_TERMINATE_REASONS = {
        BUSY,
        CANCEL,
        DECLINE,
        GONE,
        SUCCESS
    };
}