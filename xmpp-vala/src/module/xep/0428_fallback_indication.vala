using Gee;

namespace Xmpp.Xep.FallbackIndication {

    public const string NS_URI = "urn:xmpp:fallback:0";

    public class Fallback {
        public string ns_uri { get; set; }
        public FallbackLocation[] locations;


        public Fallback(string ns_uri, FallbackLocation[] locations) {
            this.ns_uri = ns_uri;
            this.locations = locations;
        }
    }

    public class FallbackLocation {
        public bool is_whole { get { return from_char == -1 && to_char == -1; } }
        public int from_char { get; set; }
        public int to_char { get; set; }

        public FallbackLocation.partial_body(int from_char, int to_char) {
            this.from_char = from_char;
            this.to_char = to_char;
        }

        public FallbackLocation.whole_body() {
            this.from_char = -1;
            this.to_char = -1;
        }
    }

    public static void set_fallback(MessageStanza message, Fallback fallback) {
        StanzaNode fallback_node = (new StanzaNode.build("fallback", NS_URI))
                .add_self_xmlns()
                .put_attribute("for", fallback.ns_uri);
        foreach (FallbackLocation location in fallback.locations) {
            var node = new StanzaNode.build("body", NS_URI).add_self_xmlns();
            if (!location.is_whole) {
                node.put_attribute("start", location.from_char.to_string())
                        .put_attribute("end", location.to_char.to_string());
            }
            fallback_node.put_node(node);
        }
        message.stanza.put_node(fallback_node);
    }

    public Gee.List<Fallback> get_fallbacks(MessageStanza message) {
        var ret = new ArrayList<Fallback>();

        Gee.List<StanzaNode> fallback_nodes = message.stanza.get_subnodes("fallback", NS_URI);
        if (fallback_nodes.is_empty) return ret;

        foreach (StanzaNode fallback_node in fallback_nodes) {
            string? ns_uri = fallback_node.get_attribute("for");
            if (ns_uri == null) continue;

            var locations = new ArrayList<FallbackLocation>();
            if (fallback_node.get_all_subnodes().is_empty) {
                locations.add(new FallbackLocation.whole_body());
            } else {
                Gee.List<StanzaNode> body_nodes = fallback_node.get_subnodes("body", NS_URI);
                foreach (StanzaNode body_node in body_nodes) {
                    int start_char = body_node.get_attribute_int("start", -1);
                    int end_char = body_node.get_attribute_int("end", -1);
                    if (start_char == -1 && end_char == -1) {
                        locations.add(new FallbackLocation.whole_body());
                        continue;
                    }
                    if (start_char == -1 || end_char == -1) continue;
                    locations.add(new FallbackLocation.partial_body(start_char, end_char));
                }
            }
            if (locations.is_empty) continue;
            ret.add(new Fallback(ns_uri, locations.to_array()));
        }

        return ret;
    }
}