namespace Xmpp.Xep.MessageArchiveManagement {

public const string NS_URI = "urn:xmpp:mam:2";
public const string NS_URI_2 = "urn:xmpp:mam:2";
public const string NS_URI_1 = "urn:xmpp:mam:1";

private static string NS_VER(XmppStream stream) {
    return stream.get_flag(Flag.IDENTITY).ns_ver;
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0313_message_archive_management");

    public signal void feature_available(XmppStream stream);

    private ReceivedPipelineListener received_pipeline_listener = new ReceivedPipelineListener();

    private StanzaNode crate_base_query(XmppStream stream, string? jid, string? queryid, DateTime? start, DateTime? end) {
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
        if (queryid != null) {
            query_node.put_attribute("queryid", queryid);
        }
        return query_node;
    }

    private StanzaNode create_set_rsm_node(string? before_id) {
        var before_node = new StanzaNode.build("before", "http://jabber.org/protocol/rsm");
        if (before_id != null) {
            before_node.put_node(new StanzaNode.text(before_id));
        }
        var max_node = (new StanzaNode.build("max", "http://jabber.org/protocol/rsm")).put_node(new StanzaNode.text("20"));
        return (new StanzaNode.build("set", "http://jabber.org/protocol/rsm")).add_self_xmlns()
                .put_node(before_node)
                .put_node(max_node);
    }

    public async Iq.Stanza? query_archive(XmppStream stream, string? jid, string? query_id, DateTime? start_time, string? start_id, DateTime? end_time, string? end_id) {
        if (stream.get_flag(Flag.IDENTITY) == null) return null;

        var query_node = crate_base_query(stream, jid, query_id, start_time, end_time);
        query_node.put_node(create_set_rsm_node(end_id));
        Iq.Stanza iq = new Iq.Stanza.set(query_node);

        return yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);
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

    public async Iq.Stanza? page_through_results(XmppStream stream, string? jid, string? query_id, DateTime? start_time, DateTime? end_time, Iq.Stanza iq) {

        string? complete = iq.stanza.get_deep_attribute("urn:xmpp:mam:2:fin", "complete");
        if (complete == "true") {
            return null;
        }
        string? first = iq.stanza.get_deep_string_content(NS_VER(stream) + ":fin", "http://jabber.org/protocol/rsm" + ":set", "first");
        if (first == null) {
            return null;
        }

        var query_node = crate_base_query(stream, jid, query_id, start_time, end_time);
        query_node.put_node(create_set_rsm_node(first));

        Iq.Stanza paging_iq = new Iq.Stanza.set(query_node);

        return yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, paging_iq);
    }

    private async void query_availability(XmppStream stream) {
        Jid own_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid;

        bool ver_2_available = yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, own_jid, NS_URI);
        if (ver_2_available) {
            stream.add_flag(new Flag(NS_URI));
            feature_available(stream);
            return;
        }

        bool ver_1_available = yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, own_jid, NS_URI_1);
        if (ver_1_available) {
            stream.add_flag(new Flag(NS_URI_1));
            feature_available(stream);
            return;
        }
    }
}

public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {};

    public override string action_group { get { return "EXTRACT_MESSAGE_1"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(XmppStream stream, MessageStanza message) {
        if (stream.get_flag(Flag.IDENTITY) == null) return false;

        StanzaNode? message_node = message.stanza.get_deep_subnode(NS_VER(stream) + ":result", "urn:xmpp:forward:0:forwarded", Xmpp.NS_URI + ":message");
        if (message_node != null) {
            // MAM messages must come from our server // TODO or a MUC server
            if (!message.from.equals(stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid)) {
                warning("Received alleged MAM message from %s, ignoring", message.from.to_string());
                return true;
            }

            StanzaNode? forward_node = message.stanza.get_deep_subnode(NS_VER(stream) + ":result", "urn:xmpp:forward:0:forwarded", DelayedDelivery.NS_URI + ":delay");
            DateTime? datetime = DelayedDelivery.get_time_for_node(forward_node);
            string? mam_id = message.stanza.get_deep_attribute(NS_VER(stream) + ":result", NS_VER(stream) + ":id");
            string? query_id = message.stanza.get_deep_attribute(NS_VER(stream) + ":result", NS_VER(stream) + ":queryid");
            message.add_flag(new MessageFlag(datetime, mam_id, query_id));

            message.stanza = message_node;
            message.rerun_parsing = true;
        }
        return false;
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
    public string? mam_id { get; private set; }
    public string? query_id { get; private set; }

    public MessageFlag(DateTime? server_time, string? mam_id, string? query_id) {
        this.server_time = server_time;
        this.mam_id = mam_id;
        this.query_id = query_id;
    }

    public static MessageFlag? get_flag(MessageStanza message) { return (MessageFlag) message.get_flag(NS_URI, ID); }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return ID; }
}

}
