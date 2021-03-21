using Gee;
using Xmpp;
using Xmpp.Xep;

public class Xmpp.Xep.JingleRtp.PayloadType {
    public uint8 id { get; set; }
    public string? name { get; set; }
    public uint8 channels { get; set; default = 1; }
    public uint32 clockrate { get; set; }
    public uint32 maxptime { get; set; }
    public uint32 ptime { get; set; }
    public Map<string, string> parameters = new HashMap<string, string>();

    public static PayloadType parse(StanzaNode node) {
        PayloadType payloadType = new PayloadType();
        payloadType.channels = (uint8) node.get_attribute_uint("channels", payloadType.channels);
        payloadType.clockrate = node.get_attribute_uint("clockrate");
        payloadType.id = (uint8) node.get_attribute_uint("id");
        payloadType.maxptime = node.get_attribute_uint("maxptime");
        payloadType.name = node.get_attribute("name");
        payloadType.ptime = node.get_attribute_uint("ptime");
        foreach (StanzaNode parameter in node.get_subnodes("parameter")) {
            payloadType.parameters[parameter.get_attribute("name")] = parameter.get_attribute("value");
        }
        return payloadType;
    }

    public StanzaNode to_xml() {
        StanzaNode node = new StanzaNode.build("payload-type", NS_URI)
                .put_attribute("id", id.to_string());
        if (channels != 1) node.put_attribute("channels", channels.to_string());
        if (clockrate != 0) node.put_attribute("clockrate", clockrate.to_string());
        if (maxptime != 0) node.put_attribute("maxptime", maxptime.to_string());
        if (name != null) node.put_attribute("name", name);
        if (ptime != 0) node.put_attribute("ptime", ptime.to_string());
        foreach (string parameter in parameters.keys) {
            node.put_node(new StanzaNode.build("parameter", NS_URI)
                    .put_attribute("name", parameter)
                    .put_attribute("value", parameters[parameter]));
        }
        return node;
    }

    public static bool equals_func(PayloadType a, PayloadType b) {
        return a.id == b.id &&
                a.name == b.name &&
                a.channels == b.channels &&
                a.clockrate == b.clockrate &&
                a.maxptime == b.maxptime &&
                a.ptime == b.ptime;
    }
}