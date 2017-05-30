using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.DataForms {

public const string NS_URI = "jabber:x:data";

public class DataForm {

    public StanzaNode stanza_node { get; set; }
    public Gee.List<Field> fields = new ArrayList<Field>();

    public XmppStream stream;
    public OnResult on_result;
    public Object? store;

    public void cancel() {
        StanzaNode stanza_node = new StanzaNode.build("x", NS_URI);
        stanza_node.add_self_xmlns().set_attribute("type", "cancel");
        on_result(stream, stanza_node, store);
    }

    public void submit() {
        stanza_node.set_attribute("type", "submit");
        on_result(stream, stanza_node, store);
    }

    public enum Type {
        BOOLEAN,
        FIXED,
        HIDDEN,
        JID_MULTI,
        LIST_SINGLE,
        LIST_MULTI,
        TEXT_PRIVATE,
        TEXT_SINGLE,
    }

    public class Option {
        public string label { get; set; }
        public string value { get; set; }

        public Option(string label, string value) {
            this.label = label;
            this.value = value;
        }
    }

    public abstract class Field {
        public string label {
            get { return node.get_attribute("label", NS_URI); }
            set { node.set_attribute("label", value); }
        }
        public StanzaNode node { get; set; }
        public abstract Type type_ { get; internal set; }
        public string var {
            get { return node.get_attribute("var", NS_URI); }
            set { node.set_attribute("var", value); }
        }

        public Field(StanzaNode node) {
            this.node = node;
        }

        internal Gee.List<string> get_values() {
            Gee.List<string> ret = new ArrayList<string>();
            Gee.List<StanzaNode> value_nodes = node.get_subnodes("value", NS_URI);
            foreach (StanzaNode node in value_nodes) {
                ret.add(node.get_string_content());
            }
            return ret;
        }

        internal string get_value_string() {
            Gee.List<string> values = get_values();
            return values.size > 0 ? values[0] : "";
        }

        internal void set_value_string(string val) {
            StanzaNode? value_node = node.get_subnode("value", NS_URI);
            if (value_node == null) {
                value_node = new StanzaNode.build("value", NS_URI);
                node.put_node(value_node);
            }
            value_node.sub_nodes.clear();
            value_node.put_node(new StanzaNode.text(val));
        }

        internal void add_value_string(string val) {
            StanzaNode node = new StanzaNode.build("value");
            node.put_node(new StanzaNode.text(val));
        }

        internal Gee.List<Option>? get_options() {
            Gee.List<Option> ret = new ArrayList<Option>();
            Gee.List<StanzaNode> option_nodes = node.get_subnodes("option", NS_URI);
            foreach (StanzaNode node in option_nodes) {
                Option option = new Option(node.get_attribute("label", NS_URI), node.get_subnode("value").get_string_content());
                ret.add(option);
            }
            return ret;
        }
    }

    public class BooleanField : Field {
        public override Type type_ { get; internal set; default=Type.BOOLEAN; }
        public bool value {
            get { return get_value_string() == "1"; }
            set { set_value_string(value ? "1" : "0"); }
        }
        public BooleanField(StanzaNode node) { base(node); }
    }

    public class FixedField : Field {
        public override Type type_ { get; internal set; default=Type.FIXED; }
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public FixedField(StanzaNode node) { base(node); }
    }

    public class HiddenField : Field {
        public override Type type_ { get; internal set; default=Type.HIDDEN; }
        public HiddenField(StanzaNode node) { base(node); }
    }

    public class JidMultiField : Field {
        public Gee.List<Option> options { owned get { return get_options(); } }
        public override Type type_ { get; internal set; default=Type.JID_MULTI; }
        public Gee.List<string> value { get; set; }
        public JidMultiField(StanzaNode node) { base(node); }
    }

    public class ListSingleField : Field {
        public Gee.List<Option> options { owned get { return get_options(); } }
        public override Type type_ { get; internal set; default=Type.LIST_SINGLE; }
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public ListSingleField(StanzaNode node) { base(node); }
    }

    public class ListMultiField : Field {
        public Gee.List<Option> options { owned get { return get_options(); } }
        public override Type type_ { get; internal set; default=Type.LIST_MULTI; }
        public Gee.List<string> value { get; set; }
        public ListMultiField(StanzaNode node) { base(node); }
    }

    public class TextPrivateField : Field {
        public override Type type_ { get; internal set; default=Type.TEXT_PRIVATE; }
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public TextPrivateField(StanzaNode node) { base(node); }
    }

    public class TextSingleField : Field {
        public override Type type_ { get; internal set; default=Type.TEXT_SINGLE; }
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public TextSingleField(StanzaNode node) { base(node); }
    }

    // TODO text-multi

    internal DataForm(StanzaNode node, XmppStream stream, OnResult on_result, Object? store) {
        this.stanza_node = node;
        this.stream = stream;
        this.on_result = on_result;
        this.store = store;
        Gee.List<StanzaNode> field_nodes = node.get_subnodes("field", NS_URI);
        foreach (StanzaNode field_node in field_nodes) {
            string? type = field_node.get_attribute("type", NS_URI);
            switch (type) {
                case "boolean":
                    fields.add(new BooleanField(field_node)); break;
                case "fixed":
                    fields.add(new FixedField(field_node)); break;
                case "hidden":
                    fields.add(new HiddenField(field_node)); break;
                case "jid-multi":
                    fields.add(new JidMultiField(field_node)); break;
                case "list-single":
                    fields.add(new ListSingleField(field_node)); break;
                case "list-multi":
                    fields.add(new ListMultiField(field_node)); break;
                case "text-private":
                    fields.add(new TextPrivateField(field_node)); break;
                case "text-single":
                    fields.add(new TextSingleField(field_node)); break;
            }
        }
    }

    [CCode (has_target = false)] public delegate void OnResult(XmppStream stream, StanzaNode node, Object? store);
    public static DataForm? create(XmppStream stream, StanzaNode node, OnResult on_result, Object? store) {
        return new DataForm(node, stream, on_result, store);
    }
}

}