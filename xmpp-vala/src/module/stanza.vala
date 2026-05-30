namespace Xmpp {

public class Stanza : Object {

    public const string ATTRIBUTE_FROM = "from";
    public const string ATTRIBUTE_ID = "id";
    public const string ATTRIBUTE_TO = "to";
    public const string ATTRIBUTE_TYPE = "type";

    public const string TYPE_ERROR = "error";

    private Jid? my_jid;
    private Jid? from_;
    private Jid? to_;

    public Jid? from {
        get {
            if (from_ == null) {
                string? from_attribute = stanza.get_attribute(ATTRIBUTE_FROM);
                if (from_attribute != null) {
                    try {
                        from_ = Jid.from_string(from_attribute);
                    } catch (InvalidJidError e) {
                        warning("Ignoring invalid from Jid: %s", e.message);
                    }
                }
                // "when a client receives a stanza that does not include a 'from' attribute, it MUST assume that the stanza
                // is from the user's account on the server." (RFC6120 8.1.2.1)
                if (from_ == null && my_jid != null) {
                    from_ = my_jid.bare_jid;
                }
            }
            return from_;
        }
        set {
            from_ = value;
            stanza.set_attribute(ATTRIBUTE_FROM, value.to_string());
        }
    }

    public string? id {
        get { return stanza.get_attribute(ATTRIBUTE_ID); }
        set { stanza.set_attribute(ATTRIBUTE_ID, value); }
    }

    public Jid? to {
        get {
            if (to_ == null) {
                string? to_attribute = stanza.get_attribute(ATTRIBUTE_TO);
                if (to_attribute != null) {
                    try {
                        to_ = Jid.from_string(to_attribute);
                    } catch (InvalidJidError e) {
                        warning("Ignoring invalid to Jid: %s", e.message);
                    }
                }
                // "if the stanza does not include a 'to' address then the client MUST treat it as if the 'to' address were
                // included with a value of the client's full JID." (RFC6120 8.1.1.1)
                if (to_ == null) {
                    to_ = my_jid;
                }
            }
            return to_;
        }
        set {
            to_ = value;
            stanza.set_attribute(ATTRIBUTE_TO, value.to_string());
        }
    }

    public virtual string? type_ {
        get { return stanza.get_attribute(ATTRIBUTE_TYPE); }
        set { stanza.set_attribute(ATTRIBUTE_TYPE, value); }
    }

    private StanzaNode stanza_;
    public StanzaNode stanza {
        get { return stanza_; }
        set {
            stanza_ = value;
            // Invalidate caches
            from_ = null;
            to_ = null;
        }
    }

    public Stanza.incoming(StanzaNode stanza, Jid? my_jid) {
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
        return ErrorStanza.from_stanza(this.stanza);
    }
}

}