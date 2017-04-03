using Gee;

namespace Xmpp.Core {

public abstract class StanzaEntry {
    protected const string ANSI_COLOR_END = "\x1b[0m";
    protected const string ANSI_COLOR_GREEN = "\x1b[32m";
    protected const string ANSI_COLOR_YELLOW = "\x1b[33m";
    protected const string ANSI_COLOR_GRAY = "\x1b[37m";

    public string? ns_uri;
    public string name;
    public string? val;

    public string encoded_val {
        owned get {
            return val != null ? val.replace("&", "&amp;").replace("\"", "&quot;").replace("'", "&apos;").replace("<", "&lt;").replace(">", "&gt;") : null;
        }
        set {
            string tmp = value.replace("&gt;", ">").replace("&lt;", "<").replace("&apos;","'").replace("&quot;","\"");
            while (tmp.contains("&#")) {
                int start = tmp.index_of("&#");
                int end = tmp.index_of(";", start);
                if (end < start) break;
                unichar num = -1;
                if (tmp[start+2]=='x') {
                    tmp.substring(start+3, start-end-3).scanf("%x", &num);
                } else {
                    num = int.parse(tmp.substring(start+2, start-end-2));
                }
                tmp = tmp.splice(start, end, num.to_string());
            }
            val = tmp.replace("&amp;", "&");
        }
    }

    public virtual unowned string? get_string_content() {
        return val;
    }
}

public class NoStanza : StanzaEntry {
    public NoStanza(string? name) {
        this.name = name;
    }
}

public class StanzaNode : StanzaEntry {
    public ArrayList<StanzaNode> sub_nodes = new ArrayList<StanzaNode>();
    public ArrayList<StanzaAttribute> attributes = new ArrayList<StanzaAttribute>();
    public bool has_nodes = false;
    public bool pseudo = false;

    public StanzaNode() {
    }

    public StanzaNode.build(string name, string ns_uri = "jabber:client", ArrayList<StanzaNode>? nodes = null, ArrayList<StanzaAttribute>? attrs = null) {
        this.ns_uri = ns_uri;
        this.name = name;
        if (nodes != null) this.sub_nodes.add_all(nodes);
        if (attrs != null) this.attributes.add_all(attrs);
    }

    public StanzaNode.text(string text) {
        this.name = "#text";
        this.val = text;
    }

    public StanzaNode.encoded_text(string text) {
        this.name = "#text";
        this.encoded_val = text;
    }

    public StanzaNode add_self_xmlns() {
        return put_attribute("xmlns", ns_uri);
    }

    public unowned string? get_attribute(string name, string? ns_uri = null) {
        string _name = name;
        string? _ns_uri = ns_uri;
        if (_ns_uri == null) {
            if (_name.contains(":")) {
                var lastIndex = _name.last_index_of_char(':');
                _ns_uri = _name.substring(0, lastIndex);
                _name = _name.substring(lastIndex + 1);
            } else {
                _ns_uri = this.ns_uri;
            }
        }
        foreach (var attr in attributes) {
            if (attr.ns_uri == _ns_uri && attr.name == _name) return attr.val;
        }
        return null;
    }

    public int get_attribute_int(string name, int def = -1, string? ns_uri = null) {
        string? res = get_attribute(name, ns_uri);
        if (res == null) return def;
        return int.parse(res);
    }

    public uint get_attribute_uint(string name, uint def = 0, string? ns_uri = null) {
        string? res = get_attribute(name, ns_uri);
        if (res == null) return def;
        return (uint) long.parse(res);
    }

    public bool get_attribute_bool(string name, bool def = false, string? ns_uri = null) {
        string? res = get_attribute(name, ns_uri);
        if (res == null) return def;
        return res.down() == "true" || res == "1";
    }

    public StanzaAttribute? get_attribute_raw(string name, string? ns_uri = null) {
        string _name = name;
        string? _ns_uri = ns_uri;
        if (_ns_uri == null) {
            if (_name.contains(":")) {
                var lastIndex = _name.last_index_of_char(':');
                _ns_uri = _name.substring(0, lastIndex);
                _name = _name.substring(lastIndex + 1);
            } else {
                _ns_uri = this.ns_uri;
            }
        }
        foreach (var attr in attributes) {
            if (attr.ns_uri == _ns_uri && attr.name == _name) return attr;
        }
        return null;
    }

    public ArrayList<StanzaAttribute> get_attributes_by_ns_uri(string ns_uri) {
        ArrayList<StanzaAttribute> ret = new ArrayList<StanzaAttribute> ();
        foreach (var attr in attributes) {
            if (attr.ns_uri == ns_uri) ret.add(attr);
        }
        return ret;
    }

    public StanzaEntry get(...) {
        va_list l = va_list();
        StanzaEntry? res = get_deep_attribute_(va_list.copy(l));
        if (res != null) return res;
        res = get_deep_subnode_(va_list.copy(l));
        if (res != null) return res;
        return new NoStanza("-");
    }

    public unowned string? get_deep_attribute(...) {
        va_list l = va_list();
        var res = get_deep_attribute_(va_list.copy(l));
        if (res == null) return null;
        return res.val;
    }

    public StanzaAttribute? get_deep_attribute_(va_list l) {
        StanzaNode? node = this;
        string? attribute_name = l.arg();
        if (attribute_name == null) return null;
        while (true) {
            string? s = l.arg();
            if (s == null) break;
            node = node.get_subnode(attribute_name);
            if (node == null) return null;
            attribute_name = s;
        }
        return node.get_attribute_raw(attribute_name);
    }

    public StanzaNode? get_subnode(string name, string? ns_uri = null, bool recurse = false) {
        string _name = name;
        string? _ns_uri = ns_uri;
        if (ns_uri == null) {
            if (_name.contains(":")) {
                var lastIndex = _name.last_index_of_char(':');
                _ns_uri = _name.substring(0, lastIndex);
                _name = _name.substring(lastIndex + 1);
            } else {
                _ns_uri = this.ns_uri;
            }
        }
        foreach (var node in sub_nodes) {
            if (node.ns_uri == _ns_uri && node.name == _name) return node;
            if (recurse) {
                var x = node.get_subnode(_name, _ns_uri, recurse);
                if (x != null) return x;
            }
        }
        return null;
    }

    public ArrayList<StanzaNode> get_subnodes(string name, string? ns_uri = null, bool recurse = false) {
        ArrayList<StanzaNode> ret = new ArrayList<StanzaNode>();
        string _name = name;
        string? _ns_uri = ns_uri;
        if (ns_uri == null) {
            if (_name.contains(":")) {
                var lastIndex = _name.last_index_of_char(':');
                _ns_uri = _name.substring(0, lastIndex);
                _name = _name.substring(lastIndex + 1);
            } else {
                _ns_uri = this.ns_uri;
            }
        }
        foreach (var node in sub_nodes) {
            if (node.ns_uri == _ns_uri && node.name == _name) ret.add(node);
            if (recurse) {
                ret.add_all(node.get_subnodes(_name, _ns_uri, recurse));
            }
        }
        return ret;
    }

    public StanzaNode? get_deep_subnode(...) {
        va_list l = va_list();
        return get_deep_subnode_(va_list.copy(l));
    }

    public StanzaNode? get_deep_subnode_(va_list l) {
        StanzaNode? node = this;
        while (true) {
            string? s = l.arg();
            if (s == null) break;
            node = node.get_subnode(s);
            if (node == null) return null;
        }
        return node;
    }

    public ArrayList<StanzaNode> get_deep_subnodes(...) {
        va_list l = va_list();
        var res = get_deep_subnodes_(va_list.copy(l));
        if (res != null) return res;
        return new ArrayList<StanzaNode>();
    }

    public ArrayList<StanzaNode> get_deep_subnodes_(va_list l) {
        StanzaNode? node = this;
        string? subnode_name = l.arg();
        if (subnode_name == null) return new ArrayList<StanzaNode>();
        while (true) {
            string? s = l.arg();
            if (s == null) break;
            node = node.get_subnode(subnode_name);
            if (node == null) return new ArrayList<StanzaNode>();
            subnode_name = s;
        }
        return node.get_subnodes(subnode_name);
    }

    public ArrayList<StanzaNode> get_all_subnodes() {
        return sub_nodes;
    }

    public ArrayList<StanzaNode> get_deep_all_subnodes(...) {
        va_list l = va_list();
        StanzaNode? node = get_deep_subnode_(va_list.copy(l));
        if (node != null) return node.get_all_subnodes();
        return new ArrayList<StanzaNode>();
    }

    public void add_attribute(StanzaAttribute attr) {
        attributes.add(attr);
    }

    public override unowned string? get_string_content() {
        if (val != null) return val;
        if (sub_nodes.size == 1) return sub_nodes[0].get_string_content();
        return null;
    }

    public unowned string? get_deep_string_content(...) {
        va_list l = va_list();
        StanzaNode? node = get_deep_subnode_(va_list.copy(l));
        if (node != null) return node.get_string_content();
        return null;
    }

    public StanzaNode put_attribute(string name, string val, string? ns_uri = null) {
        if (name == "xmlns") ns_uri = XMLNS_URI;
        if (ns_uri == null) ns_uri = this.ns_uri;
        attributes.add(new StanzaAttribute.build(ns_uri, name, val));
        return this;
    }

    /**
    *    Set only occurence
    **/
    public void set_attribute(string name, string val, string? ns_uri = null) {
        if (ns_uri == null) ns_uri = this.ns_uri;
        foreach (var attr in attributes) {
            if (attr.ns_uri == ns_uri && attr.name == name) {
                attr.val = val;
                return;
            }
        }
        put_attribute(name, val, ns_uri);
    }

    public StanzaNode put_node(StanzaNode node) {
        sub_nodes.add(node);
        return this;
    }

    public string to_string(int i = 0) {
        string indent = string.nfill (i * 2, ' ');
        if (name == "#text") {
            return @"$indent$val\n";
        }
        var sb = new StringBuilder();
        sb.append(@"$indent<{$ns_uri}:$name");
        foreach (StanzaAttribute attr in attributes) {
            sb.append_printf(" %s", attr.to_string());
        }
        if (!has_nodes && sub_nodes.size == 0) {
            sb.append(" />\n");
        } else {
            sb.append(">\n");
            if (sub_nodes.size != 0) {
                foreach (StanzaNode subnode in sub_nodes) {
                    sb.append(subnode.to_string(i+1));
                }
                sb.append(@"$indent</{$ns_uri}:$name>\n");
            }
        }
        return sb.str;
    }

    public string to_ansi_string(bool hide_ns = false, int i = 0) {
        string indent = string.nfill (i * 2, ' ');
        if (name == "#text") {
            return @"$indent$val\n";
        }
        var sb = new StringBuilder();
        sb.append(@"$indent$ANSI_COLOR_YELLOW<");
        if (!hide_ns) sb.append(@"$ANSI_COLOR_GRAY{$ns_uri}:$ANSI_COLOR_YELLOW");
        sb.append(@"$name$ANSI_COLOR_END");
        foreach (StanzaAttribute attr in attributes) {
            sb.append_printf(" %s", attr.to_ansi_string(hide_ns));
        }
        if (!has_nodes && sub_nodes.size == 0) {
            sb.append(@" $ANSI_COLOR_YELLOW/>$ANSI_COLOR_END\n");
        } else {
            sb.append(@"$ANSI_COLOR_YELLOW>$ANSI_COLOR_END\n");
            if (sub_nodes.size != 0) {
                foreach (StanzaNode subnode in sub_nodes) {
                    sb.append(subnode.to_ansi_string(hide_ns, i + 1));
                }
                sb.append(@"$indent$ANSI_COLOR_YELLOW</");
                if (!hide_ns) sb.append(@"$ANSI_COLOR_GRAY{$ns_uri}:$ANSI_COLOR_YELLOW");
                sb.append(@"$name>$ANSI_COLOR_END\n");
            }
        }
        return sb.str;
    }

    public string to_xml(NamespaceState? state = null) throws XmlError {
        NamespaceState my_state = state ?? new NamespaceState.for_stanza();
        if (name == "#text") return @"$encoded_val";
        foreach (var xmlns in get_attributes_by_ns_uri (XMLNS_URI)) {
            if (xmlns.name == "xmlns") {
                my_state = new NamespaceState.with_current(my_state, xmlns.val);
            } else {
                my_state = new NamespaceState.with_assoc(my_state, xmlns.val, xmlns.name);
            }
        }
        var sb = new StringBuilder();
        if (ns_uri == my_state.current_ns_uri) {
            sb.append(@"<$name");
        } else {
            sb.append_printf("<%s:%s", my_state.find_name (ns_uri), name);
        }
        var attr_ns_state = new NamespaceState.with_current(my_state, ns_uri);
        foreach (StanzaAttribute attr in attributes) {
            sb.append_printf(" %s", attr.to_xml(attr_ns_state));
        }
        if (!has_nodes && sub_nodes.size == 0) {
            sb.append("/>");
        } else {
            sb.append(">");
            if (sub_nodes.size != 0) {
                foreach (StanzaNode subnode in sub_nodes) {
                    sb.append(subnode.to_xml(my_state));
                }
                if (ns_uri == my_state.current_ns_uri) {
                    sb.append(@"</$name>");
                } else {
                    sb.append_printf("</%s:%s>", my_state.find_name (ns_uri), name);
                }
            }
        }
        return sb.str;
    }
}

}
