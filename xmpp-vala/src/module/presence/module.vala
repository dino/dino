using Gee;

namespace Xmpp.Presence {
    private const string NS_URI = "jabber:client";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "presence_module");

        public signal void received_presence(XmppStream stream, Presence.Stanza presence);
        public signal void pre_send_presence_stanza(XmppStream stream, Presence.Stanza presence);
        public signal void initial_presence_sent(XmppStream stream, Presence.Stanza presence);
        public signal void received_available(XmppStream stream, Presence.Stanza presence);
        public signal void received_available_show(XmppStream stream, Jid jid, string show);
        public signal void received_unavailable(XmppStream stream, Presence.Stanza presence);
        public signal void received_subscription_request(XmppStream stream, Jid jid);
        public signal void received_subscription_approval(XmppStream stream, Jid jid);
        public signal void received_unsubscription(XmppStream stream, Jid jid);
        public signal void mutual_subscription(XmppStream stream, Jid jid);

        public bool available_resource = true;

        private Gee.List<Jid> subscriptions = new ArrayList<Jid>(Jid.equals_bare_func);
        private Gee.List<Jid> subscribers = new ArrayList<Jid>(Jid.equals_bare_func);

        public void request_subscription(XmppStream stream, Jid bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_SUBSCRIBE;
            send_presence(stream, presence);
        }

        public void approve_subscription(XmppStream stream, Jid bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_SUBSCRIBED;
            send_presence(stream, presence);
            subscribers.add(bare_jid);
            if (subscriptions.contains(bare_jid)) mutual_subscription(stream, bare_jid);
        }

        public void deny_subscription(XmppStream stream, Jid bare_jid) {
            cancel_subscription(stream, bare_jid);
        }

        public void cancel_subscription(XmppStream stream, Jid bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_UNSUBSCRIBED;
            send_presence(stream, presence);
            subscribers.remove(bare_jid);
        }

        public void unsubscribe(XmppStream stream, Jid bare_jid) {
            Presence.Stanza presence = new Presence.Stanza();
            presence.to = bare_jid;
            presence.type_ = Presence.Stanza.TYPE_UNSUBSCRIBE;
            send_presence(stream, presence);
            subscriptions.remove(bare_jid);
        }

        public void send_presence(XmppStream stream, Presence.Stanza presence) {
            pre_send_presence_stanza(stream, presence);
            stream.write(presence.stanza);
        }

        public override void attach(XmppStream stream) {
            stream.add_flag(new Flag());
            stream.received_presence_stanza.connect(on_received_presence_stanza);
            stream.stream_negotiated.connect(on_stream_negotiated);
        }

        public override void detach(XmppStream stream) {
            stream.received_presence_stanza.disconnect(on_received_presence_stanza);
            stream.stream_negotiated.disconnect(on_stream_negotiated);
        }

        private void on_received_presence_stanza(XmppStream stream, StanzaNode node) {
            Presence.Stanza presence = new Presence.Stanza.from_stanza(node, stream.get_flag(Bind.Flag.IDENTITY).my_jid);
            received_presence(stream, presence);
            switch (presence.type_) {
                case Presence.Stanza.TYPE_AVAILABLE:
                    stream.get_flag(Flag.IDENTITY).add_presence(presence);
                    received_available(stream, presence);
                    received_available_show(stream, presence.from, presence.show);
                    break;
                case Presence.Stanza.TYPE_UNAVAILABLE:
                    stream.get_flag(Flag.IDENTITY).remove_presence(presence.from);
                    received_unavailable(stream, presence);
                    break;
                case Presence.Stanza.TYPE_SUBSCRIBE:
                    received_subscription_request(stream, presence.from);
                    break;
                case Presence.Stanza.TYPE_SUBSCRIBED:
                    received_subscription_approval(stream, presence.from);
                    subscriptions.add(presence.from);
                    if (subscribers.contains(presence.from)) mutual_subscription(stream, presence.from);
                    break;
                case Presence.Stanza.TYPE_UNSUBSCRIBE:
                    stream.get_flag(Flag.IDENTITY).remove_presence(presence.from);
                    received_unsubscription(stream, presence.from);
                    subscribers.remove(presence.from);
                    break;
                case Presence.Stanza.TYPE_UNSUBSCRIBED:
                    subscriptions.remove(presence.from);
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

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }

}
