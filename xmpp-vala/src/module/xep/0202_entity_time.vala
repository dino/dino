using Gee;

namespace Xmpp.Xep.EntityTime {
    public const string NS_URI = "urn:xmpp:time";

    public class Module : XmppStreamModule, Iq.Handler {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0202_entity_time");
        public bool enabled { get; set; default = false; }

        private HashMap<Jid, Future<DateTime?>> active_time_requests = new HashMap<Jid, Future<DateTime?>>(Jid.hash_func, Jid.equals_func);

        public async DateTime? query_time(XmppStream stream, Jid jid) {
            if (!enabled) return null;

            var future = active_time_requests[jid];
            if (future != null) {
                try {
                    return yield future.wait_async();
                } catch (FutureError error) {
                    return null;
                }
            }

            var promise = new Promise<DateTime?>();
            active_time_requests[jid] = promise.future;

            DateTime? res = null;
            try {
                Iq.Stanza iq = new Iq.Stanza.get(new StanzaNode.build("time", NS_URI).add_self_xmlns()) { to=jid };
                var cancellable = new Cancellable();
                var timeout_id = Timeout.add_seconds_once(10, () => cancellable.cancel());
                Iq.Stanza result = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq, Priority.HIGH, cancellable);
                Source.remove(timeout_id);
                StanzaNode time_node = result.stanza.get_subnode("time", NS_URI);
                if (time_node == null) return null;
                StanzaNode tzo_node = time_node.get_subnode("tzo", NS_URI);
                StanzaNode utc_node = time_node.get_subnode("utc", NS_URI);
                TimeZone? tzo = null;
                if (utc_node != null) res = DateTimeProfiles.parse_time(utc_node.get_string_content());
                if (tzo_node != null) tzo = DateTimeProfiles.parse_tzd(tzo_node.get_string_content());
                if (res != null && tzo != null) res = res.to_timezone(tzo);
                promise.set_value(res);
            } catch (IOError e) {
                debug("Error while fetching time: %s", e.message);
            }
            return res;
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
            var roster_flag = stream.get_flag(Roster.Flag.IDENTITY);
            if (!enabled || roster_flag == null || roster_flag.get_item(iq.from.bare_jid) == null) {
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.error(iq, new ErrorStanza.forbidden()), null, Priority.LOW);
            } else {
                DateTime time = new DateTime.now_local();
                StanzaNode time_node = new StanzaNode.build("time", NS_URI).add_self_xmlns();
                time_node.put_node(new StanzaNode.build("utc", NS_URI).put_node(new StanzaNode.text(DateTimeProfiles.format_time(time))));
                time_node.put_node(new StanzaNode.build("tzo", NS_URI).put_node(new StanzaNode.text(DateTimeProfiles.format_tzd(time))));
                stream.get_module(Iq.Module.IDENTITY).send_iq(stream, new Iq.Stanza.result(iq, time_node), null, Priority.LOW);
            }
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}
