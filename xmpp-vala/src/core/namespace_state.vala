using Gee;

namespace Xmpp {

public class NamespaceState {
    private HashMap<string, string> uri_to_name = new HashMap<string, string> ();
    private HashMap<string, string> name_to_uri = new HashMap<string, string> ();
    public string current_ns_uri;

    private NamespaceState parent;

    public NamespaceState() {
        add_assoc(XMLNS_URI, "xmlns");
        add_assoc(XML_URI, "xml");
        current_ns_uri = XML_URI;
    }

    public NamespaceState.for_stanza() {
        this();
        add_assoc("http://etherx.jabber.org/streams", "stream");
        current_ns_uri = "jabber:client";
    }

    private NamespaceState.copy(NamespaceState old) {
        foreach (string key in old.uri_to_name.keys) {
            add_assoc(key, old.uri_to_name[key]);
        }
        set_current(old.current_ns_uri);
    }

    private NamespaceState.with_parent(NamespaceState parent) {
        this.copy(parent);
        this.parent = parent;
    }

    public NamespaceState.with_assoc(NamespaceState old, string ns_uri, string name) {
        this.copy(old);
        add_assoc(ns_uri, name);
    }

    public NamespaceState.with_current(NamespaceState old, string current_ns_uri) {
        this.copy(old);
        set_current(current_ns_uri);
    }

    public void add_assoc(string ns_uri, string name) {
        name_to_uri[name] = ns_uri;
        uri_to_name[ns_uri] = name;
    }

    public void set_current(string current_ns_uri) {
        this.current_ns_uri = current_ns_uri;
    }

    public string find_name(string ns_uri) throws XmlError {
        if (uri_to_name.has_key(ns_uri)) {
            return uri_to_name[ns_uri];
        }
        throw new XmlError.NS_DICT_ERROR(@"NS URI $ns_uri not found.");
    }

    public string find_uri(string name) throws XmlError {
        if (name_to_uri.has_key(name)) {
            return name_to_uri[name];
        }
        throw new XmlError.NS_DICT_ERROR(@"NS name $name not found.");
    }

    public NamespaceState push() {
        return new NamespaceState.with_parent(this);
    }

    public NamespaceState pop() {
        return parent;
    }

    public string to_string() {
        StringBuilder sb = new StringBuilder ();
        sb.append ("NamespaceState{");
        foreach (string key in uri_to_name.keys) {
            sb.append(key);
            sb.append_c('=');
            sb.append(uri_to_name[key]);
            sb.append_c(',');
        }
        sb.append("current=");
        sb.append(current_ns_uri);
        sb.append_c('}');
        return sb.str;
    }
}

}
