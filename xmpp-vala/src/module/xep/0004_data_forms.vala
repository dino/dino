using Gee;

namespace Xmpp.Xep.DataForms {

public const string NS_URI = "jabber:x:data";

public class DataForm {

    public StanzaNode stanza_node { get; set; }
    public Gee.List<Field> fields = new ArrayList<Field>();
    public string? form_type = null;

    public StanzaNode get_submit_node() {
        stanza_node.set_attribute("type", "submit");
        return stanza_node;
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

    public class Field {
        public StanzaNode node { get; set; }
        public string? label {
            get { return node.get_attribute("label", NS_URI); }
            set { node.set_attribute("label", value); }
        }
        public virtual Type? type_ { get; internal set; default=null; }
        public string? var {
            get { return node.get_attribute("var", NS_URI); }
            set { node.set_attribute("var", value); }
        }

        public Field() {
            this.node = new StanzaNode.build("field", NS_URI);
        }

        public Field.from_node(StanzaNode node) {
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

        public string get_value_string() {
            Gee.List<string> values = get_values();
            return values.size > 0 ? values[0] : "";
        }

        public void set_value_string(string val) {
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
        public bool value {
            get { return get_value_string() == "1"; }
            set { set_value_string(value ? "1" : "0"); }
        }
        public BooleanField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.BOOLEAN;
        }
    }

    public class FixedField : Field {
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public FixedField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.FIXED;
        }
    }

    public class HiddenField : Field {
        public HiddenField() {
            base();
            type_ = Type.HIDDEN;
            node.put_attribute("type", "hidden");
        }
        public HiddenField.from_node(StanzaNode node) {
            base.from_node(node);
            type_ = Type.HIDDEN;
        }
    }

    public class JidMultiField : Field {
        public Gee.List<Option> options { owned get { return get_options(); } }
        public Gee.List<string> value { get; set; }
        public JidMultiField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.JID_MULTI;
        }
    }

    public class ListSingleField : Field {
        public Gee.List<Option> options { owned get { return get_options(); } }
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public ListSingleField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.LIST_SINGLE;
            node.set_attribute("type", "list-single");
        }
    }

    public class ListMultiField : Field {
        public Gee.List<Option> options { owned get { return get_options(); } }
        public Gee.List<string> value { get; set; }
        public ListMultiField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.LIST_MULTI;
        }
    }

    public class TextPrivateField : Field {
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public TextPrivateField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.TEXT_PRIVATE;
        }
    }

    public class TextSingleField : Field {
        public string value {
            owned get { return get_value_string(); }
            set { set_value_string(value); }
        }
        public TextSingleField(StanzaNode node) {
            base.from_node(node);
            type_ = Type.TEXT_SINGLE;
        }
    }

    // TODO text-multi

    internal DataForm.from_node(StanzaNode node) {
        this.stanza_node = node;

        Gee.List<StanzaNode> field_nodes = node.get_subnodes("field", NS_URI);
        foreach (StanzaNode field_node in field_nodes) {
            string? type = field_node.get_attribute("type", NS_URI);
            switch (type) {
                case "boolean":
                    fields.add(new BooleanField(field_node)); break;
                case "fixed":
                    fields.add(new FixedField(field_node)); break;
                case "hidden":
                    HiddenField field = new HiddenField.from_node(field_node);
                    if (field.var == "FORM_TYPE") {
                        this.form_type = field.get_value_string();
                        break;
                    }
                    fields.add(field); break;
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

    internal DataForm() {
        this.stanza_node = new StanzaNode.build("x", NS_URI).add_self_xmlns();
    }

    public static DataForm? create_from_node(StanzaNode node) {
        return new DataForm.from_node(node);
    }

    public void add_field(Field field) {
        fields.add(field);
        stanza_node.put_node(field.node);
    }
}

}
