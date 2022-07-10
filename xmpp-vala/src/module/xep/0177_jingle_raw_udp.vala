using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.JingleRawUdp {

    public const string NS_URI = "urn:xmpp:jingle:transports:raw-udp:1";

    public delegate Gee.List<string> GetLocalIpAddresses();

    public class Module : XmppStreamModule, Jingle.Transport {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0177_jingle_raw_udp");

        private GetLocalIpAddresses? get_local_ip_addresses_impl = null;

        public override void attach(XmppStream stream) {
            stream.get_module(Jingle.Module.IDENTITY).register_transport(this);
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }
        public override void detach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        public async bool is_transport_available(XmppStream stream, uint8 components, Jid full_jid) {
            return yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
        }

        public string ns_uri{ get { return NS_URI; } }
        public Jingle.TransportType type_{ get { return Jingle.TransportType.DATAGRAM; } }
        public int priority { get { return 1; } }

        public void set_local_ip_address_handler(owned GetLocalIpAddresses get_local_ip_addresses) {
            get_local_ip_addresses_impl = (owned)get_local_ip_addresses;
        }

        public Gee.List<string> get_local_ip_addresses() {
            if (get_local_ip_addresses_impl == null) {
                return Gee.List.empty();
            }
            return get_local_ip_addresses_impl();
        }

        public Jingle.TransportParameters create_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid) {
            return new TransportParameters(components, null);
        }

        public Jingle.TransportParameters parse_transport_parameters(XmppStream stream, uint8 components, Jid local_full_jid, Jid peer_full_jid, StanzaNode transport) throws Jingle.IqError {
            return new TransportParameters(components, transport);
        }
    }

    public class TransportParameters : Jingle.TransportParameters, Object {
        public string ns_uri { get { return NS_URI; } }
        public uint8 components { get; }

        public Gee.List<Candidate> remote_candidates = new ArrayList<Candidate>();
        public Gee.List<Candidate> own_candidates = new ArrayList<Candidate>();

        public TransportParameters(uint8 components, StanzaNode? node = null) {
//            this.components = components;
            if (node != null) {
                foreach (StanzaNode candidate_node in node.get_subnodes("candidate")) {
                    Candidate candidate = new Candidate();
                    string component_str = candidate_node.get_attribute("component");
                    candidate.component = int.parse(component_str);
                    string generation_str = candidate_node.get_attribute("generation");
                    candidate.generation = int.parse(generation_str);
                    candidate.id = candidate_node.get_attribute("generation");
                    string ip_str = candidate_node.get_attribute("ip");
                    candidate.ip = new InetAddress.from_string(ip_str);
                    string port_str = candidate_node.get_attribute("port");
                    candidate.port = int.parse(port_str);

                    remote_candidates.add(candidate);
                }
            }
        }

        public void set_content(Jingle.Content content) {

        }

        public StanzaNode to_transport_stanza_node(string action_type) {
            StanzaNode transport_node = new StanzaNode.build("transport", NS_URI).add_self_xmlns();
            foreach (Candidate candidate in own_candidates) {
                transport_node.put_node(new StanzaNode.build("candidate", NS_URI)
                        .put_attribute("generation", candidate.generation.to_string())
                        .put_attribute("id", candidate.id)
                        .put_attribute("ip", candidate.ip.to_string())
                        .put_attribute("port", candidate.port.to_string()));
            }
            return transport_node;
        }

        public void handle_transport_accept(StanzaNode transport) throws Jingle.IqError {

        }

        public void handle_transport_info(StanzaNode transport) throws Jingle.IqError {

        }

        public void create_transport_connection(XmppStream stream, Jingle.Content content) {

        }
    }

    public class Candidate : Object {
        public int component { get; set; }
        public int generation { get; set; }
        public string id { get; set; }
        public InetAddress ip { get; set; }
        public uint port { get; set; }
    }
}