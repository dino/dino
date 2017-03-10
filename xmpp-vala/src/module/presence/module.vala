using Xmpp.Core;

namespace Xmpp.Presence {
    private const string NS_URI = "jabber:client";

    public class Module : XmppStreamModule {
        public const string ID = "presence_module";
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

        public signal void received_presence(XmppStream stream, Presence.Stanza presence);
        public signal void pre_send_presence_stanza(XmppStream stream, Presence.Stanza presence);
        public signal void initial_presence_sent(XmppStream stream, Presence.Stanza presence);
        public signal void received_available(XmppStream stream, Presence.Stanza presence);
        public signal void received_available_show(XmppStream stream, string jid, string show);
        public signal void received_unavailable(XmppStream stream, string jid);
        public signal void received_subscription_request(XmppStream stream, string jid);
        public signal void received_unsubscription(XmppStream stream, string jid);

        public bool available_resource = true;

        public void request_subscription(XmppStream stream, string bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_SUBSCRIBE;
            send_presence(stream, presence);
        }

        public void approve_subscription(XmppStream stream, string bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_SUBSCRIBED;
            send_presence(stream, presence);
        }

        public void deny_subscription(XmppStream stream, string bare_jid) {
            cancel_subscription(stream, bare_jid);
        }

        public void cancel_subscription(XmppStream stream, string bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_UNSUBSCRIBED;
            send_presence(stream, presence);
        }

        public void unsubscribe(XmppStream stream, string bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_UNSUBSCRIBE;
            send_presence(stream, presence);
        }

        public void send_presence(XmppStream stream, Presence.Stanza presence) {
            pre_send_presence_stanza(stream, presence);
            stream.write(presence.stanza);
        }

        public override void attach(XmppStream stream) {
            stream.received_presence_stanza.connect(on_received_presence_stanza);
            stream.stream_negotiated.connect(on_stream_negotiated);
            stream.add_flag(new Flag());
        }

        public override void detach(XmppStream stream) {
            stream.received_presence_stanza.disconnect(on_received_presence_stanza);
            stream.stream_negotiated.disconnect(on_stream_negotiated);
        }

        private void on_received_presence_stanza(XmppStream stream, StanzaNode node) {
            Presence.Stanza presence = new Presence.Stanza.from_stanza(node, Bind.Flag.get_flag(stream).my_jid);
            received_presence(stream, presence);
            switch (presence.type_) {
                case Presence.Stanza.TYPE_AVAILABLE:
                    Flag.get_flag(stream).add_presence(presence);
                    received_available(stream, presence);
                    received_available_show(stream, presence.from, presence.show);
                    break;
                case Presence.Stanza.TYPE_UNAVAILABLE:
                    Flag.get_flag(stream).remove_presence(presence.from);
                    received_unavailable(stream, presence.from);
                    break;
                case Presence.Stanza.TYPE_SUBSCRIBE:
                    received_subscription_request(stream, presence.from);
                    break;
                case Presence.Stanza.TYPE_UNSUBSCRIBE:
                    received_unsubscription(stream, presence.from);
                    break;
            }
        }

        private void on_stream_negotiated(XmppStream stream) {
            if (available_resource) {
                Presence.Stanza presence = new Presence.Stanza();
                send_presence(stream, presence);
                initial_presence_sent(stream, presence);
            }
        }

        public static Module? get_module(XmppStream stream) {
            return (Module?) stream.get_module(IDENTITY);
        }

        public static void require(XmppStream stream) {
            if (get_module(stream) == null) stream.add_module(new Presence.Module());
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return ID; }
    }

}
