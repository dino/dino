namespace Xmpp.Xep.MessageArchiveManagement {

public const string NS_URI = "urn:xmpp:mam:2";
public const string NS_URI_1 = "urn:xmpp:mam:1";

private static string NS_VER(XmppStream stream) {
    return stream.get_flag(Flag.IDENTITY).ns_ver;
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0313_message_archive_management");

    public signal void feature_available(XmppStream stream);

    private ReceivedPipelineListener received_pipeline_listener = new ReceivedPipelineListener();

    public void query_archive(XmppStream stream, string? jid, DateTime? start, DateTime? end) {
        if (stream.get_flag(Flag.IDENTITY) == null) return;

        DataForms.DataForm data_form = new DataForms.DataForm();
        DataForms.DataForm.HiddenField form_type_field = new DataForms.DataForm.HiddenField() { var="FORM_TYPE" };
        form_type_field.set_value_string(NS_VER(stream));
        data_form.add_field(form_type_field);
        if (jid != null) {
            DataForms.DataForm.Field field = new DataForms.DataForm.Field() { var="with" };
            field.set_value_string(jid);
            data_form.add_field(field);
        }
        if (start != null) {
            DataForms.DataForm.Field field = new DataForms.DataForm.Field() { var="start" };
            field.set_value_string(DateTimeProfiles.to_datetime(start));
            data_form.add_field(field);
        }
        if (end != null) {
            DataForms.DataForm.Field field = new DataForms.DataForm.Field() { var="end" };
            field.set_value_string(DateTimeProfiles.to_datetime(end));
            data_form.add_field(field);
        }
        StanzaNode query_node = new StanzaNode.build("query", NS_VER(stream)).add_self_xmlns().put_node(data_form.get_submit_node());
        Iq.Stanza iq = new Iq.Stanza.set(query_node);
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, page_through_results);
    }

    public override void attach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.connect(received_pipeline_listener);
        stream.stream_negotiated.connect(query_availability);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.disconnect(received_pipeline_listener);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private static void page_through_results(XmppStream stream, Iq.Stanza iq) {
        string? last = iq.stanza.get_deep_string_content(NS_VER(stream) + ":fin", "http://jabber.org/protocol/rsm" + ":set", "last");
        if (last == null) {
            stream.get_flag(Flag.IDENTITY).cought_up = true;
            return;
        }

        Iq.Stanza paging_iq = new Iq.Stanza.set(
                new StanzaNode.build("query", NS_VER(stream)).add_self_xmlns().put_node(
                    new StanzaNode.build("set", "http://jabber.org/protocol/rsm").add_self_xmlns().put_node(
                        new StanzaNode.build("after", "http://jabber.org/protocol/rsm").put_node(new StanzaNode.text(last))
                    )
                )
            );
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, paging_iq, page_through_results);
    }

    private void query_availability(XmppStream stream) {
        stream.get_module(Xep.ServiceDiscovery.Module.IDENTITY).request_info(stream, stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid, (stream, info_result) => {
            if (info_result == null) return;
            if (info_result.features.contains(NS_URI)) {
                stream.add_flag(new Flag(NS_URI));
                feature_available(stream);
            } else if (info_result.features.contains(NS_URI_1)) {
                stream.add_flag(new Flag(NS_URI_1));
                feature_available(stream);
            }
        });
    }
}

public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {};

    public override string action_group { get { return "EXTRACT_MESSAGE_1"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async void run(XmppStream stream, MessageStanza message) {
        //        if (message.from != stream.remote_name) return;
        if (stream.get_flag(Flag.IDENTITY) == null) return;

        StanzaNode? message_node = message.stanza.get_deep_subnode(NS_VER(stream) + ":result", "urn:xmpp:forward:0:forwarded", Xmpp.NS_URI + ":message");
        if (message_node != null) {
            StanzaNode? forward_node = message.stanza.get_deep_subnode(NS_VER(stream) + ":result", "urn:xmpp:forward:0:forwarded", DelayedDelivery.NS_URI + ":delay");
            DateTime? datetime = DelayedDelivery.Module.get_time_for_node(forward_node);
            message.add_flag(new MessageFlag(datetime));

            message.stanza = message_node;
            message.rerun_parsing = true;
        }
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "message_archive_management");
    public bool cought_up { get; set; default=false; }
    public string ns_ver;

    public Flag(string ns_ver) {
        this.ns_ver = ns_ver;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class MessageFlag : Xmpp.MessageFlag {
    public const string ID = "message_archive_management";

    public DateTime? server_time { get; private set; }

    public MessageFlag(DateTime? server_time) {
        this.server_time = server_time;
    }

    public static MessageFlag? get_flag(MessageStanza message) { return (MessageFlag) message.get_flag(NS_URI, ID); }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return ID; }
}

}
