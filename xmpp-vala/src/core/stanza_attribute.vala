namespace Xmpp {

public class StanzaAttribute : StanzaEntry {

    internal const string ATTRIBUTE_STRING_FORMAT = "{%s}:%s='%s'";
    internal const string ATTRIBUTE_STRING_NO_NS_FORMAT = "%s='%s'";
    internal const string ATTRIBUTE_STRING_ANSI_FORMAT = ANSI_COLOR_GRAY+"{%s}:"+ANSI_COLOR_END+"%s="+ANSI_COLOR_GREEN+"'%s'"+ANSI_COLOR_END;
    internal const string ATTRIBUTE_STRING_ANSI_NO_NS_FORMAT = "%s="+ANSI_COLOR_GREEN+"'%s'"+ANSI_COLOR_END;
    internal const string ATTRIBUTE_XML_FORMAT = "%s:%s='%s'";
    internal const string ATTRIBUTE_XML_NO_NS_FORMAT = "%s='%s'";
    internal const string ATTRIBUTE_XML_ANSI_FORMAT = "%s:%s="+ANSI_COLOR_GREEN+"'%s'"+ANSI_COLOR_END;
    internal const string ATTRIBUTE_XML_ANSI_NO_NS_FORMAT = "%s="+ANSI_COLOR_GREEN+"'%s'"+ANSI_COLOR_END;

    internal StanzaAttribute() {
    }

    public StanzaAttribute.build(string ns_uri, string name, string val) {
        this.ns_uri = ns_uri;
        this.name = name;
        this.val = val;
    }

    public bool equals(StanzaAttribute other) {
        if (other.ns_uri != ns_uri) return false;
        if (other.name != name) return false;
        if (other.val != val) return false;
        return true;
    }

    internal string printf(string fmt, bool no_ns = false, string? ns_name = null) {
        if (no_ns) {
            return fmt.printf(name, (!)encoded_val);
        } else {
            if (ns_name == null) {
                return fmt.printf((!)ns_uri, name, (!)encoded_val);
            } else {
                return fmt.printf((!)ns_name, name, (!)encoded_val);
            }
        }
    }

    public override string to_string(int i = 0) {
        return printf(ATTRIBUTE_STRING_FORMAT);
    }

    public string to_ansi_string(bool hide_ns = false) {
        if (hide_ns) {
            return printf(ATTRIBUTE_STRING_ANSI_NO_NS_FORMAT, true);
        } else {
            return printf(ATTRIBUTE_STRING_ANSI_FORMAT);
        }
    }

    public string to_xml(NamespaceState? state_ = null) throws XmlError {
        NamespaceState state = state_ ?? new NamespaceState();
        if (ns_uri == state.current_ns_uri || (ns_uri == XMLNS_URI && name == "xmlns")) {
            return printf(ATTRIBUTE_XML_NO_NS_FORMAT, true);
        } else {
            return printf(ATTRIBUTE_XML_FORMAT, false, state.find_name((!)ns_uri));
        }
    }

    public string to_ansi_xml(NamespaceState? state_ = null) throws XmlError {
        NamespaceState state = state_ ?? new NamespaceState();
        if (ns_uri == state.current_ns_uri || (ns_uri == XMLNS_URI && name == "xmlns")) {
            return printf(ATTRIBUTE_XML_ANSI_NO_NS_FORMAT, true);
        } else {
            return printf(ATTRIBUTE_XML_ANSI_FORMAT, false, state.find_name((!)ns_uri));
        }
    }
}

}
