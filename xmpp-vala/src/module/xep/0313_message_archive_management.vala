using Gee;
using Xmpp.Xep;

namespace Xmpp.MessageArchiveManagement {

public const string NS_URI = "urn:xmpp:mam:2";
public const string NS_URI_2 = "urn:xmpp:mam:2";
public const string NS_URI_1 = "urn:xmpp:mam:1";

public class QueryResult {
    public bool error { get; set; default=false; }
    public bool malformed { get; set; default=false; }
    public bool complete { get; set; default=false; }
    public string first { get; set; }
    public string last { get; set; }
}

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0313_message_archive_management");

    public signal void feature_available(XmppStream stream);

    private ReceivedPipelineListener received_pipeline_listener = new ReceivedPipelineListener();

    public override void attach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.connect(received_pipeline_listener);
        stream.stream_negotiated.connect(query_availability);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(MessageModule.IDENTITY).received_pipeline.disconnect(received_pipeline_listener);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

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

    internal StanzaNode create_base_query(XmppStream stream, string ns, string? queryid, Gee.List<DataForms.DataForm.Field> fields) {
        DataForms.DataForm data_form = new DataForms.DataForm();

        DataForms.DataForm.HiddenField form_type_field = new DataForms.DataForm.HiddenField() { var="FORM_TYPE" };
        form_type_field.set_value_string(NS_VER(stream));
        data_form.add_field(form_type_field);

        foreach (var field in fields) {
            data_form.add_field(field);
        }

        StanzaNode query_node = new StanzaNode.build("query", NS_VER(stream)).add_self_xmlns().put_node(data_form.get_submit_node());
        if (queryid != null) {
            query_node.put_attribute("queryid", queryid);
        }
        return query_node;
    }

    internal async QueryResult query_archive(XmppStream stream, string ns, Jid? mam_server, StanzaNode query_node) {
        var res = new QueryResult();

        if (stream.get_flag(Flag.IDENTITY) == null) { res.error = true; return res; }

        // Build and send query
        Iq.Stanza iq = new Iq.Stanza.set(query_node) { to=mam_server };

        print(@"OUT:\n$(iq.stanza.to_string())\n");
        Iq.Stanza result_iq = yield stream.get_module(Iq.Module.IDENTITY).send_iq_async(stream, iq);

        print(result_iq.stanza.to_string() + "\n");

        // Parse the response IQ into a QueryResult.
        StanzaNode? fin_node = result_iq.stanza.get_subnode("fin", ns);
        if (fin_node == null) { print(@"$ns a1\n"); res.malformed = true; return res; }

        StanzaNode? rsm_node = fin_node.get_subnode("set", Xmpp.ResultSetManagement.NS_URI);
        if (rsm_node == null) { print("a2\n"); res.malformed = true; return res; }

        res.first = rsm_node.get_deep_string_content("first");
        res.last = rsm_node.get_deep_string_content("last");
        if ((res.first == null) != (res.last == null)) { print("a3\n"); res.malformed = true; }
        res.complete = fin_node.get_attribute_bool("complete", false, ns);

        return res;
    }

public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private string[] after_actions_const = {};

    public override string action_group { get { return "EXTRACT_MESSAGE_1"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(XmppStream stream, MessageStanza message) {
        if (stream.get_flag(Flag.IDENTITY) == null) return false;

        StanzaNode? message_node = message.stanza.get_deep_subnode(NS_VER(stream) + ":result", StanzaForwarding.NS_URI + ":forwarded", Xmpp.NS_URI + ":message");
        if (message_node != null) {
            StanzaNode? forward_node = message.stanza.get_deep_subnode(NS_VER(stream) + ":result", StanzaForwarding.NS_URI + ":forwarded", DelayedDelivery.NS_URI + ":delay");
            DateTime? datetime = DelayedDelivery.get_time_for_node(forward_node);
            string? mam_id = message.stanza.get_deep_attribute(NS_VER(stream) + ":result", NS_VER(stream) + ":id");
            string? query_id = message.stanza.get_deep_attribute(NS_VER(stream) + ":result", NS_VER(stream) + ":queryid");
            message.add_flag(new MessageFlag(message.from, datetime, mam_id, query_id));

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

    public Jid sender_jid { get; private set; }
    public DateTime? server_time { get; private set; }
    public string? mam_id { get; private set; }
    public string? query_id { get; private set; }

    public MessageFlag(Jid sender_jid, DateTime? server_time, string? mam_id, string? query_id) {
        this.sender_jid = sender_jid;
        this.server_time = server_time;
        this.mam_id = mam_id;
        this.query_id = query_id;
    }

    public static MessageFlag? get_flag(MessageStanza message) { return (MessageFlag) message.get_flag(NS_URI, ID); }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return ID; }
}

private static string NS_VER(XmppStream stream) {
    return stream.get_flag(Flag.IDENTITY).ns_ver;
}

}