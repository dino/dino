using Gee;

namespace Xmpp.Xep.ExternalServiceDiscovery {

    private const string NS_URI = "urn:xmpp:extdisco:2";

    public static async Gee.List<Service> request_services(XmppStream stream) {
        Iq.Stanza request_iq = new Iq.Stanza.get((new StanzaNode.build("services", NS_URI)).add_self_xmlns()) { to=stream.remote_name };
        Iq.Stanza response_iq = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, request_iq);

        ArrayList<Service> ret = new ArrayList<Service>();
        if (response_iq.is_error()) return ret;
        StanzaNode? services_node = response_iq.stanza.get_subnode("services", NS_URI);
        if (services_node == null) return ret;

        Gee.List<StanzaNode> service_nodes = services_node.get_subnodes("service", NS_URI);
        foreach (StanzaNode service_node in service_nodes) {
            Service service = new Service();
            service.host = service_node.get_attribute("host", NS_URI);
            string? port_str = service_node.get_attribute("port", NS_URI);
            if (port_str != null) service.port = int.parse(port_str);
            service.ty = service_node.get_attribute("type", NS_URI);

            if (service.host == null || service.ty == null || port_str == null) continue;

            service.username = service_node.get_attribute("username", NS_URI);
            service.password = service_node.get_attribute("password", NS_URI);
            service.transport = service_node.get_attribute("transport", NS_URI);
            service.name = service_node.get_attribute("name", NS_URI);
            string? restricted_str = service_node.get_attribute("restricted", NS_URI);
            if (restricted_str != null) service.restricted = bool.parse(restricted_str);
            ret.add(service);
        }
        return ret;
    }

    public class Service {
        public string host { get; set; }
        public uint port { get; set; }
        public string ty { get; set; }

        public string username { get; set; }
        public string password { get; set; }

        public string transport { get; set; }
        public string name { get; set; }
        public bool restricted { get; set; }
    }
}
