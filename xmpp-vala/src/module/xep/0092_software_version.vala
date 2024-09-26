namespace Xmpp.Xep.SoftwareVersion {
    private const string NS_URI = "jabber:iq:version";

    public class Module : XmppStreamModule, Iq.Handler {
        private string name;
        private string version;

        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0092_software_version");

        public Module.with_name_and_version(string name, string version) {
            this.name = name;
            this.version = version;
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_URI, this);
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Iq.Module.IDENTITY).unregister_from_namespace(NS_URI, this);
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }

        public async void on_iq_get(XmppStream stream, Iq.Stanza iq) {
            var iq_result = new Iq.Stanza.result(iq);
            StanzaNode query = new StanzaNode.build("query", NS_URI).add_self_xmlns()
                .put_node(new StanzaNode.build("name", NS_URI)
                    .put_node(new StanzaNode.text(name)))
                .put_node(new StanzaNode.build("version", NS_URI)
                    .put_node(new StanzaNode.text(version)));
            iq_result.stanza.put_node(query);
            stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq_result);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
