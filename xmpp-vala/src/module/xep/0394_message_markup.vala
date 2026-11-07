using Gee;

namespace Xmpp.Xep.MessageMarkup {

    public const string NS_URI = "urn:xmpp:markup:0";

    public class Markup : Object {
        public int start_char { get; set; }
        public int end_char { get; set; }
    }

    public enum SpanType {
        EMPHASIS,
        STRONG_EMPHASIS,
        DELETED,
        CODE
    }

    public class Span : Markup {
        public Gee.List<SpanType> types { get; set; }
    }

    public class CodeBlock : Markup {
        public string? language { get; set; }
    }

    public class BlockQuote : Markup { }

    public Gee.List<Span> get_spans(MessageStanza stanza) {
        var ret = new ArrayList<Span>();

        foreach (StanzaNode span_node in stanza.stanza.get_deep_subnodes(NS_URI + ":markup", NS_URI + ":span")) {
            int start_char = span_node.get_attribute_int("start", -1, NS_URI);
            int end_char = span_node.get_attribute_int("end", -1, NS_URI);
            if (start_char == -1 || end_char == -1) continue;

            var types = new ArrayList<SpanType>();
            foreach (StanzaNode span_subnode in span_node.get_all_subnodes()) {
                types.add(str_to_span_type(span_subnode.name));
            }
            ret.add(new Span() { types=types, start_char=start_char, end_char=end_char });
        }
        return ret;
    }

    public void add_markups(MessageStanza stanza, Gee.List<Markup> markups) {
        if (markups.is_empty) return;

        StanzaNode markup_node = new StanzaNode.build("markup", NS_URI).add_self_xmlns();

        foreach (var markup in markups) {

            if (markup is MessageMarkup.Span) {
                MessageMarkup.Span span = (MessageMarkup.Span) markup;

                StanzaNode span_node = new StanzaNode.build("span", NS_URI)
                        .put_attribute("start", span.start_char.to_string(), NS_URI)
                        .put_attribute("end", span.end_char.to_string(), NS_URI);

                foreach (var type in span.types) {
                    span_node.put_node(new StanzaNode.build(span_type_to_str(type), NS_URI));
                }
                markup_node.put_node(span_node);
            }
        }

        stanza.stanza.put_node(markup_node);
    }

    public static string span_type_to_str(Xep.MessageMarkup.SpanType span_type) {
        switch (span_type) {
            case Xep.MessageMarkup.SpanType.EMPHASIS:
                return "emphasis";
            case Xep.MessageMarkup.SpanType.STRONG_EMPHASIS:
                return "strong";
            case Xep.MessageMarkup.SpanType.DELETED:
                return "deleted";
            case Xep.MessageMarkup.SpanType.CODE:
                return "code";
            default:
                return "";
        }
    }

    public static Xep.MessageMarkup.SpanType str_to_span_type(string span_str) {
        switch (span_str) {
            case "emphasis":
                return Xep.MessageMarkup.SpanType.EMPHASIS;
            case "strong":
                return Xep.MessageMarkup.SpanType.STRONG_EMPHASIS;
            case "deleted":
                return Xep.MessageMarkup.SpanType.DELETED;
            case "code":
                return Xep.MessageMarkup.SpanType.CODE;
            default:
                return Xep.MessageMarkup.SpanType.EMPHASIS;
        }
    }

}