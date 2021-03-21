using Gee;
using Xmpp.Xep;
using Xmpp;

public class Xmpp.Xep.JingleIceUdp.Candidate {
    public uint8 component;
    public uint8 foundation;
    public uint8 generation;
    public string id;
    public string ip;
    public uint8 network;
    public uint16 port;
    public uint32 priority;
    public string protocol;
    public string? rel_addr;
    public uint16 rel_port;
    public Type type_;

    public static Candidate parse(StanzaNode node) throws Jingle.IqError {
        Candidate candidate = new Candidate();
        candidate.component = (uint8) node.get_attribute_uint("component");
        candidate.foundation = (uint8) node.get_attribute_uint("foundation");
        candidate.generation = (uint8) node.get_attribute_uint("generation");
        candidate.id = node.get_attribute("id");
        candidate.ip = node.get_attribute("ip");
        candidate.network = (uint8) node.get_attribute_uint("network");
        candidate.port = (uint16) node.get_attribute_uint("port");
        candidate.priority = (uint32) node.get_attribute_uint("priority");
        candidate.protocol = node.get_attribute("protocol");
        candidate.rel_addr = node.get_attribute("rel-addr");
        candidate.rel_port = (uint16) node.get_attribute_uint("rel-port");
        candidate.type_ = Type.parse(node.get_attribute("type"));
        return candidate;
    }

    public enum Type {
        HOST, PRFLX, RELAY, SRFLX;
        public static Type parse(string str) throws Jingle.IqError {
            switch (str) {
                case "host": return HOST;
                case "prflx": return PRFLX;
                case "relay": return RELAY;
                case "srflx": return SRFLX;
                default: throw new Jingle.IqError.BAD_REQUEST("Illegal ICE-UDP candidate type");
            }
        }
        public string to_string() {
            switch (this) {
                case HOST: return "host";
                case PRFLX: return "prflx";
                case RELAY: return "relay";
                case SRFLX: return "srflx";
                default: assert_not_reached();
            }
        }
    }

    public StanzaNode to_xml() {
        StanzaNode node = new StanzaNode.build("candidate", NS_URI)
                .put_attribute("component", component.to_string())
                .put_attribute("foundation", foundation.to_string())
                .put_attribute("generation", generation.to_string())
                .put_attribute("id", id)
                .put_attribute("ip", ip)
                .put_attribute("network", network.to_string())
                .put_attribute("port", port.to_string())
                .put_attribute("priority", priority.to_string())
                .put_attribute("protocol", protocol)
                .put_attribute("type", type_.to_string());
        if (rel_addr != null) node.put_attribute("rel-addr", rel_addr);
        if (rel_port != 0) node.put_attribute("rel-port", rel_port.to_string());
        return node;
    }

    public bool equals(Candidate c) {
        return equals_func(this, c);
    }

    public static bool equals_func(Candidate c1, Candidate c2) {
        return c1.component == c2.component &&
                c1.foundation == c2.foundation &&
                c1.generation == c2.generation &&
                c1.id == c2.id &&
                c1.ip == c2.ip &&
                c1.network == c2.network &&
                c1.port == c2.port &&
                c1.priority == c2.priority &&
                c1.protocol == c2.protocol &&
                c1.rel_addr == c2.rel_addr &&
                c1.rel_port == c2.rel_port &&
                c1.type_ == c2.type_;
    }
}