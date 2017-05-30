using Gee;

namespace Xmpp.Core {
public const string XMLNS_URI = "http://www.w3.org/2000/xmlns/";
public const string JABBER_URI = "jabber:client";

public errordomain XmlError {
    XML_ERROR,
    NS_DICT_ERROR,
    UNSUPPORTED,
    EOF,
    BAD_XML,
    IO_ERROR
}

public class StanzaReader {
    private static int BUFFER_MAX = 4096;

    private InputStream? input;
    private uint8[] buffer;
    private int buffer_fill = 0;
    private int buffer_pos = 0;
    private Cancellable cancellable = new Cancellable();

    private NamespaceState ns_state = new NamespaceState();

    public StanzaReader.for_buffer(uint8[] buffer) {
        this.buffer = buffer;
        this.buffer_fill = buffer.length;
    }

    public StanzaReader.for_string(string s) {
        this.for_buffer(s.data);
    }

    public StanzaReader.for_stream(InputStream input) {
        this.input = input;
        buffer = new uint8[BUFFER_MAX];
    }

    public void cancel() {
        cancellable.cancel();
    }

    private void update_buffer() throws XmlError {
        try {
            InputStream? input = this.input;
            if (input == null) throw new XmlError.EOF("No input stream specified and end of buffer reached.");
            if (cancellable.is_cancelled()) throw new XmlError.EOF("Input stream is canceled.");
            buffer_fill = (int) ((!)input).read(buffer, cancellable);
            if (buffer_fill == 0) throw new XmlError.EOF("End of input stream reached.");
            buffer_pos = 0;
        } catch (GLib.IOError e) {
            throw new XmlError.IO_ERROR("IOError in GLib: %s".printf(e.message));
        }
    }

    private char read_single() throws XmlError {
        if (buffer_pos >= buffer_fill) {
            update_buffer();
        }
        return (char) buffer[buffer_pos++];
    }

    private char peek_single() throws XmlError {
        var res = read_single();
        buffer_pos--;
        return res;
    }

    private bool is_ws(uint8 what) {
        return what == ' ' || what == '\t' || what == '\r' || what == '\n';
    }

    private void skip_single() {
        buffer_pos++;
    }

    private void skip_until_non_ws() throws XmlError {
        while (is_ws(peek_single())) {
            skip_single();
        }
    }

    private string read_until_ws() throws XmlError {
        var res = new StringBuilder();
        var what = peek_single();
        while(!is_ws(what)) {
            res.append_c(read_single());
            what = peek_single();
        }
        return res.str;
    }

    private string read_until_char_or_ws(char x, char y = 0) throws XmlError {
        var res = new StringBuilder();
        var what = peek_single();
        while(what != x && what != y && !is_ws(what)) {
            res.append_c(read_single());
            what = peek_single();
        }
        return res.str;
    }

    private string read_until_char(char x) throws XmlError {
        var res = new StringBuilder();
        var what = peek_single();
        while(what != x) {
            res.append_c(read_single());
            what = peek_single();
        }
       return res.str;
    }

    private StanzaAttribute read_attribute() throws XmlError {
        var res = new StanzaAttribute();
        res.name = read_until_char_or_ws('=');
        if (read_single() == '=') {
            var quot = peek_single();
            if (quot == '\'' || quot == '"') {
                skip_single();
                res.encoded_val = read_until_char(quot);
                skip_single();
            } else {
                res.encoded_val = read_until_ws();
            }
        }
        return res;
    }

    private void handle_entry_ns(StanzaEntry entry, string default_uri = ns_state.current_ns_uri) throws XmlError {
        if (entry.ns_uri != null) return;
        if (entry.name.contains(":")) {
            var split = entry.name.split(":");
            entry.ns_uri = ns_state.find_uri(split[0]);
            entry.name = split[1];
        } else {
            entry.ns_uri = default_uri;
        }
    }

    private void handle_stanza_ns(StanzaNode res) throws XmlError {
        foreach (StanzaAttribute attr in res.attributes) {
            if (attr.name == "xmlns" && attr.val != null) {
                attr.ns_uri = XMLNS_URI;
                ns_state.set_current((!)attr.val);
            } else if (attr.name.contains(":") && attr.val != null) {
                var split = attr.name.split(":");
                if (split[0] == "xmlns") {
                    attr.ns_uri = XMLNS_URI;
                    attr.name = split[1];
                    ns_state.add_assoc((!)attr.val, attr.name);
                }
            }
        }
        handle_entry_ns(res);
        foreach (StanzaAttribute attr in res.attributes) {
            handle_entry_ns(attr, res.ns_uri ?? ns_state.current_ns_uri);
        }
    }

    public StanzaNode read_node_start() throws XmlError {
        var res = new StanzaNode();
        res.attributes = new ArrayList<StanzaAttribute>();
        var eof = false;
        if (peek_single() == '<') skip_single();
        if (peek_single() == '?') res.pseudo = true;
        if (peek_single() == '/') {
            eof = true;
            skip_single();
            res.name = read_until_char_or_ws('>');
            while(peek_single() != '>') {
                skip_single();
            }
            skip_single();
            res.has_nodes = false;
            res.pseudo = false;
            handle_stanza_ns(res);
            return res;
        }
        res.name = read_until_char_or_ws('>', '/');
        skip_until_non_ws();
        while (peek_single() != '/' && peek_single() != '>' && peek_single() != '?') {
            res.attributes.add(read_attribute());
            skip_until_non_ws();
        }
        if (read_single() == '/' || res.pseudo ) {
            res.has_nodes = false;
            skip_single();
        } else {
            res.has_nodes = true;
        }
        handle_stanza_ns(res);
        return res;
    }

    public StanzaNode read_text_node() throws XmlError {
        var res = new StanzaNode();
        res.name = "#text";
        res.ns_uri = ns_state.current_ns_uri;
        res.encoded_val = read_until_char('<').strip();
        return res;
    }

    public StanzaNode read_root_node() throws XmlError {
        skip_until_non_ws();
        if (peek_single() == '<') {
            var res = read_node_start();
            if (res.pseudo) {
                return read_root_node();
            }
            return res;
        } else {
            throw new XmlError.BAD_XML("Content before root node");
        }
    }

    public StanzaNode read_stanza_node(NamespaceState? baseNs = null) throws XmlError {
        ns_state = baseNs ?? new NamespaceState.for_stanza();
        var res = read_node_start();
        if (res.has_nodes) {
            bool finishNodeSeen = false;
            do {
                skip_until_non_ws();
                if (peek_single() == '<') {
                    skip_single();
                    if (peek_single() == '/') {
                        skip_single();
                        string desc = read_until_char('>');
                        skip_single();
                        if (desc.contains(":")) {
                            var split = desc.split(":");
                            if (split[0] != ns_state.find_name((!)res.ns_uri)) throw new XmlError.BAD_XML("");
                            if (split[1] != res.name) throw new XmlError.BAD_XML("");
                        } else {
                            if (ns_state.current_ns_uri != res.ns_uri) throw new XmlError.BAD_XML("");
                            if (desc != res.name) throw new XmlError.BAD_XML("");
                        }
                        finishNodeSeen = true;
                    } else {
                        res.sub_nodes.add(read_stanza_node(ns_state.clone()));
                        ns_state = baseNs ?? new NamespaceState.for_stanza();
                    }
                } else {
                    res.sub_nodes.add(read_text_node());
                }
            } while (!finishNodeSeen);
            if (res.sub_nodes.size == 0) res.has_nodes = false;
        }
        return res;
    }

    public StanzaNode read_node(NamespaceState? baseNs = null) throws XmlError {
        skip_until_non_ws();
        if (peek_single() == '<') {
            return read_stanza_node(baseNs ?? new NamespaceState.for_stanza());
        } else {
            return read_text_node();
        }
    }
}
}
