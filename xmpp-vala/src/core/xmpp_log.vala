using Gee;

namespace Xmpp {

public class XmppLog {
    protected const string ANSI_COLOR_END = "\x1b[0m";
    protected const string ANSI_COLOR_WHITE = "\x1b[37;1m";

    class NodeLogDesc {
        public string? name;
        private string? ns_uri;
        private string? val;
        private Map<string, string?> attrs = new HashMap<string, string?>();
        private NodeLogDesc? inner;

        public NodeLogDesc(string desc) {
            string d = desc;

            if (d.contains("[")) {
                int start = d.index_of("[");
                int end = d.index_of("]");
                string attrs = d.substring(start + 1, end - start - 1);
                d = d.substring(0, start) + d.substring(end + 1);
                foreach (string attr in attrs.split(",")) {
                    if (attr.contains("=")) {
                        string key = attr.substring(0, attr.index_of("="));
                        string val = attr.substring(attr.index_of("=") + 1);
                        this.attrs[key] = val;
                    } else {
                        this.attrs[attr] = null;
                    }
                }
            }
            if (d.contains(":") && d.index_of("{") == 0 && d.index_of("}") != -1) {
                int end = d.index_of("}");
                this.ns_uri = d.substring(1, end - 1);
                d = d.substring(end + 2);
            }
            if (d.contains(".")) {
                inner = new NodeLogDesc(d.substring(d.index_of(".") + 1));
                d = d.substring(0, d.index_of("."));
            } else if (d.contains("=")) {
                this.val = d.substring(d.index_of("="));
                d = d.substring(0, d.index_of("="));
            }

            if (d != "") this.name = d;
        }

        public bool matches(StanzaNode node) {
            if (name != null && node.name != name) return false;
            if (ns_uri != null && node.ns_uri != ns_uri) return false;
            if (val != null && node.val != val) return false;
            foreach (var pair in attrs.entries) {
                if (pair.value == null && node.get_attribute(pair.key) == null) return false;
                        else if (pair.value != null && pair.value != node.get_attribute(pair.key)) return false;
            }
            if (inner == null) return true;
            foreach (StanzaNode snode in node.get_all_subnodes()) {
                if (((!)inner).matches(snode)) return true;
            }
            return false;
        }
    }

    private bool use_ansi;
    private bool hide_ns = true;
    private string ident;
    private string desc;
    private Gee.List<NodeLogDesc> descs = new ArrayList<NodeLogDesc>();

    public XmppLog(string? ident = null, string? desc = null) {
        this.ident = ident ?? "";
        this.desc = desc ?? "";
        this.use_ansi = is_atty(stderr.fileno());
        while (this.desc.contains(";")) {
            string opt = this.desc.substring(0, this.desc.index_of(";"));
            this.desc = this.desc.substring(opt.length + 1);
            switch (opt) {
                case "ansi": use_ansi = true; break;
                case "no-ansi": use_ansi = false; break;
                case "hide-ns": hide_ns = true; break;
                case "show-ns": hide_ns = false; break;
            }
        }
        if (desc != "") {
            foreach (string d in this.desc.split("|")) {
                descs.add(new NodeLogDesc(d));
            }
        }
    }

    public virtual bool should_log_node(StanzaNode node) {
        if (ident == "" || desc == "") return false;
        if (desc == "all") return true;
        foreach (var desc in descs) {
            if (desc.matches(node)) return true;
        }
        return false;
    }

    public virtual bool should_log_str(string str) {
        if (ident == "" || desc == "") return false;
        if (desc == "all") return true;
        foreach (var desc in descs) {
            if (desc.name == "#text") return true;
        }
        return false;
    }

    public void node(string what, StanzaNode node) {
        if (should_log_node(node)) {
            stderr.printf("%sXMPP %s [%s]%s\n%s\n", ANSI_COLOR_WHITE, what, ident, ANSI_COLOR_END, use_ansi ? node.to_ansi_string(hide_ns) : node.to_string());
        }
    }

    public void str(string what, string str) {
        if (should_log_str(str)) {
            stderr.printf("%sXMPP %s [%s]%s\n%s\n", ANSI_COLOR_WHITE, what, ident, ANSI_COLOR_END, str);
        }
    }

    [CCode (cname = "isatty")]
    private static extern bool is_atty(int fd);
}

}
