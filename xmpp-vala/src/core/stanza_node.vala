using Gee;

namespace Xmpp {

public abstract class StanzaEntry {
    protected const string ANSI_COLOR_END = "\x1b[0m";
    protected const string ANSI_COLOR_GREEN = "\x1b[32m";
    protected const string ANSI_COLOR_YELLOW = "\x1b[33m";
    protected const string ANSI_COLOR_GRAY = "\x1b[37m";

    public string? ns_uri;
    public string name;
    public string? val;

    public string? encoded_val {
        owned get {
            if (val == null) return null;
            return ((!)val).replace("&", "&amp;").replace("\"", "&quot;").replace("'", "&apos;").replace("<", "&lt;").replace(">", "&gt;");
        }
        set {
            if (value == null) {
                val = null;
                return;
            }
            string tmp = ((!)value).replace("&gt;", ">").replace("&lt;", "<").replace("&apos;","'").replace("&quot;","\"");
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

    public virtual string to_string(int i = 0) {
        return get_string_content() ?? "(null)";
    }
}

public class StanzaNode : StanzaEntry {
    public Gee.List<StanzaNode> sub_nodes = new ArrayList<StanzaNode>();
    public Gee.List<StanzaAttribute> attributes = new ArrayList<StanzaAttribute>();
    public bool has_nodes = false;
    public bool pseudo = false;

    internal StanzaNode() {
    }

    public StanzaNode.build(string name, string ns_uri = "jabber:client", ArrayList<StanzaNode>? nodes = null, ArrayList<StanzaAttribute>? attrs = null) {
        this.ns_uri = ns_uri;
        this.name = name;
        if (nodes != null) this.sub_nodes.add_all((!)nodes);
        if (attrs != null) this.attributes.add_all((!)attrs);
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
        if (ns_uri == null) return this;
        return put_attribute("xmlns", (!)ns_uri);
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
            if (attr.ns_uri == (!)_ns_uri && attr.name == _name) return attr.val;
        }
        return null;
    }

    public int get_attribute_int(string name, int def = -1, string? ns_uri = null) {
        string? res = get_attribute(name, ns_uri);
        if (res == null) return def;
        return int.parse((!)res);
    }

    public uint get_attribute_uint(string name, uint def = 0, string? ns_uri = null) {
        string? res = get_attribute(name, ns_uri);
        if (res == null) return def;
        return (uint) long.parse((!)res);
    }

    public bool get_attribute_bool(string name, bool def = false, string? ns_uri = null) {
        string? res = get_attribute(name, ns_uri);
        if (res == null) return def;
        return ((!)res).down() == "true" || res == "1";
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

    public Gee.List<StanzaAttribute> get_attributes_by_ns_uri(string ns_uri) {
        ArrayList<StanzaAttribute> ret = new ArrayList<StanzaAttribute> ();
        foreach (var attr in attributes) {
            if (attr.ns_uri == ns_uri) ret.add(attr);
        }
        return ret;
    }

    public unowned string? get_deep_attribute(...) {
        va_list l = va_list();
        StanzaAttribute? res = get_deep_attribute_(va_list.copy(l));
        if (res == null) return null;
        return ((!)res).val;
    }

    public StanzaAttribute? get_deep_attribute_(va_list l) {
        StanzaNode node = this;
        string? attribute_name = l.arg();
        if (attribute_name == null) return null;
        while (true) {
            string? s = l.arg();
            if (s == null) break;
            StanzaNode? node_tmp = node.get_subnode((!)attribute_name);
            if (node_tmp == null) return null;
            node = (!)node_tmp;
            attribute_name = s;
        }
        return node.get_attribute_raw((!)attribute_name);
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

    public Gee.List<StanzaNode> get_subnodes(string name, string? ns_uri = null, bool recurse = false) {
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
        StanzaNode node = this;
        while (true) {
            string? s = l.arg();
            if (s == null) break;
            StanzaNode? node_tmp = node.get_subnode((!)s);
            if (node_tmp == null) return null;
            node = (!)node_tmp;
        }
        return node;
    }

    public Gee.List<StanzaNode> get_deep_subnodes(...) {
        va_list l = va_list();
        return get_deep_subnodes_(va_list.copy(l));
    }

    public Gee.List<StanzaNode> get_deep_subnodes_(va_list l) {
        StanzaNode node = this;
        string? subnode_name = l.arg();
        if (subnode_name == null) return new ArrayList<StanzaNode>();
        while (true) {
            string? s = l.arg();
            if (s == null) break;
            StanzaNode? node_tmp = node.get_subnode((!)subnode_name);
            if (node_tmp == null) return new ArrayList<StanzaNode>();
            node = (!)node_tmp;
            subnode_name = s;
        }
        return node.get_subnodes((!)subnode_name);
    }

    public Gee.List<StanzaNode> get_all_subnodes() {
        return sub_nodes;
    }

    public Gee.List<StanzaNode> get_deep_all_subnodes(...) {
        va_list l = va_list();
        StanzaNode? node = get_deep_subnode_(va_list.copy(l));
        if (node != null) return ((!)node).get_all_subnodes();
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
        if (node != null) return ((!)node).get_string_content();
        return null;
    }

    public StanzaNode put_attribute(string name, string val, string? ns_uri = null) {
        string? _ns_uri = ns_uri;
        if (name == "xmlns") _ns_uri = XMLNS_URI;
        if (_ns_uri == null) _ns_uri = this.ns_uri;
        if (_ns_uri == null) return this;
        attributes.add(new StanzaAttribute.build((!)_ns_uri, name, val));
        return this;
    }

    /**
    *    Set only occurrence
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

    public bool equals(StanzaNode other) {
        if (other.name != name) return false;
        if (other.val != val) return false;
        if (name == "#text") return true;
        if (other.ns_uri != ns_uri) return false;

        if (other.sub_nodes.size != sub_nodes.size) return false;
        for (int i = 0; i < sub_nodes.size; i++) {
            if (!other.sub_nodes[i].equals(sub_nodes[i])) return false;
        }

        if (other.attributes.size != attributes.size) return false;
        for (int i = 0; i < attributes.size; i++) {
            if (!other.attributes[i].equals(attributes[i])) return false;
        }

        return true;
    }

    private const string TAG_START_BEGIN_FORMAT = "%s<{%s}:%s";
    private const string TAG_START_EMPTY_END = " />\n";
    private const string TAG_START_CONTENT_END = ">\n";
    private const string TAG_END_FORMAT = "%s</{%s}:%s>\n";
    private const string TAG_ANSI_START_BEGIN_FORMAT = "%s"+ANSI_COLOR_YELLOW+"<"+ANSI_COLOR_GRAY+"{%s}:"+ANSI_COLOR_YELLOW+"%s"+ANSI_COLOR_END;
    private const string TAG_ANSI_START_BEGIN_NO_NS_FORMAT = "%s"+ANSI_COLOR_YELLOW+"<%s"+ANSI_COLOR_END;
    private const string TAG_ANSI_START_EMPTY_END = ANSI_COLOR_YELLOW+" />"+ANSI_COLOR_END+"\n";
    private const string TAG_ANSI_START_CONTENT_END = ANSI_COLOR_YELLOW+">"+ANSI_COLOR_END+"\n";
    private const string TAG_ANSI_END_FORMAT = "%s"+ANSI_COLOR_YELLOW+"</"+ANSI_COLOR_GRAY+"{%s}:"+ANSI_COLOR_YELLOW+"%s>"+ANSI_COLOR_END+"\n";
    private const string TAG_ANSI_END_NO_NS_FORMAT = "%s"+ANSI_COLOR_YELLOW+"</%s>"+ANSI_COLOR_END+"\n";

    internal string printf(int i, string fmt_start_begin, string start_empty_end, string start_content_end, string fmt_end, string fmt_attr, bool no_ns = false) {
        string indent = string.nfill (i * 2, ' ');
        if (name == "#text") {
            return indent + ((!)val).replace("\n", indent + "\n") + "\n";
        }
        var sb = new StringBuilder();
        if (no_ns) {
            sb.append_printf(fmt_start_begin, indent, name);
        } else {
            sb.append_printf(fmt_start_begin, indent, (!)ns_uri, name);
        }
        foreach (StanzaAttribute attr in attributes) {
            sb.append_printf(" %s", attr.printf(fmt_attr, no_ns));
        }
        if (!has_nodes && sub_nodes.size == 0) {
            sb.append(start_empty_end);
        } else {
            sb.append(start_content_end);
            if (sub_nodes.size != 0) {
                foreach (StanzaNode subnode in sub_nodes) {
                    sb.append(subnode.printf(i+1, fmt_start_begin, start_empty_end, start_content_end, fmt_end, fmt_attr, no_ns));
                }
                if (no_ns) {
                    sb.append_printf(fmt_end, indent, name);
                } else {
                    sb.append_printf(fmt_end, indent, (!)ns_uri, name);
                }
            }
        }
        return sb.str;
    }

    public override string to_string(int i = 0) {
        return printf(i, TAG_START_BEGIN_FORMAT, TAG_START_EMPTY_END, TAG_START_CONTENT_END, TAG_END_FORMAT, StanzaAttribute.ATTRIBUTE_STRING_FORMAT);
    }

    public string to_ansi_string(bool hide_ns = false, int i = 0) {
        if (hide_ns) {
            return printf(i, TAG_ANSI_START_BEGIN_NO_NS_FORMAT, TAG_ANSI_START_EMPTY_END, TAG_ANSI_START_CONTENT_END, TAG_ANSI_END_NO_NS_FORMAT, StanzaAttribute.ATTRIBUTE_STRING_ANSI_NO_NS_FORMAT, true);
        } else {
            return printf(i, TAG_ANSI_START_BEGIN_FORMAT, TAG_ANSI_START_EMPTY_END, TAG_ANSI_START_CONTENT_END, TAG_ANSI_END_FORMAT, StanzaAttribute.ATTRIBUTE_STRING_ANSI_FORMAT);
        }
    }

    public string to_xml(NamespaceState? state = null) throws XmlError {
        NamespaceState my_state = state ?? new NamespaceState.for_stanza();
        if (name == "#text") return val == null ? "" : (!)encoded_val;
        my_state = my_state.push();
        foreach (var xmlns in get_attributes_by_ns_uri (XMLNS_URI)) {
            if (xmlns.val == null) continue;
            if (xmlns.name == "xmlns") {
                my_state.set_current((!)xmlns.val);
            } else {
                my_state.add_assoc((!)xmlns.val, xmlns.name);
            }
        }
        var sb = new StringBuilder();
        if (ns_uri == my_state.current_ns_uri) {
            sb.append_printf("<%s", name);
        } else {
            sb.append_printf("<%s:%s", my_state.find_name ((!)ns_uri), name);
        }
        var attr_ns_state = new NamespaceState.with_current(my_state, (!)ns_uri);
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
                    sb.append_printf("</%s:%s>", my_state.find_name ((!)ns_uri), name);
                }
            }
        }
        my_state = my_state.pop();
        return sb.str;
    }
}

}
