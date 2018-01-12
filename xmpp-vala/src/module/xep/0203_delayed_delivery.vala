namespace Xmpp.Xep.DelayedDelivery {

private const string NS_URI = "urn:xmpp:delay";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0203_delayed_delivery");

    private ReceivedPipelineListener received_pipeline_listener = new ReceivedPipelineListener();

    public static void set_message_delay(MessageStanza message, DateTime datetime) {
        StanzaNode delay_node = (new StanzaNode.build("delay", NS_URI)).add_self_xmlns();
        delay_node.put_attribute("stamp", DateTimeProfiles.to_datetime(datetime));
        message.stanza.put_node(delay_node);
    }

    public static DateTime? get_time_for_message(MessageStanza message) {
        StanzaNode? delay_node = message.stanza.get_subnode("delay", NS_URI);
        if (delay_node != null) {
            return get_time_for_node(delay_node);
        }
        return null;
    }

    public static DateTime? get_time_for_node(StanzaNode node) {
        string? time = node.get_attribute("stamp");
        if (time != null) return DateTimeProfiles.parse_string(time);
        return null;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.connect(received_pipeline_listener);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.disconnect(received_pipeline_listener);
    }

    public override string get_ns() {
        return NS_URI;
    }

    public override string get_id() {
        return IDENTITY.id;
    }
}

public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {};

    public override string action_group { get { return "ADD_NODE"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async void run(XmppStream stream, MessageStanza message) {
        DateTime? datetime = Module.get_time_for_message(message);
        if (datetime != null) message.add_flag(new MessageFlag(datetime));
    }
}

public class MessageFlag : Xmpp.MessageFlag {
    public const string ID = "delayed_delivery";

    public DateTime datetime { get; private set; }

    public MessageFlag(DateTime datetime) {
        this.datetime = datetime;
    }

    public static MessageFlag? get_flag(MessageStanza message) {
        return (MessageFlag) message.get_flag(NS_URI, ID);
    }

    public override string get_ns() {
        return NS_URI;
    }

    public override string get_id() {
        return ID;
    }
}

}
