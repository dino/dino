using Xmpp;
using Xmpp.Xep;
using Gee;

namespace Xmpp.Xep.HttpFileUpload {

private const string NS_URI = "urn:xmpp:http:upload:0";

public errordomain HttpFileTransferError {
    SLOT_REQUEST
}

public class Module : XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0363_http_file_upload");

    public signal void feature_available(XmppStream stream, long max_file_size);
    public signal void received_url(XmppStream stream, MessageStanza message);

    public delegate void OnSlotOk(XmppStream stream, string url_get, string url_put);
    public delegate void OnError(XmppStream stream, string error);
    public struct SlotResult {
        public string url_get { get; set; }
        public string url_put { get; set; }
        public HashMap<string, string> headers { get; set; }
    }
    public async SlotResult request_slot(XmppStream stream, string filename, int64 file_size, string? content_type) throws HttpFileTransferError {
        Flag? flag = stream.get_flag(Flag.IDENTITY);
        if (flag == null) {
            throw new HttpFileTransferError.SLOT_REQUEST("No flag");
        }

        StanzaNode request_node = new StanzaNode.build("request", NS_URI).add_self_xmlns();
        request_node.put_attribute("filename", filename).put_attribute("size", file_size.to_string());
        if (content_type != null)
            request_node.put_attribute("content-type", content_type);

        SourceFunc callback = request_slot.callback;
        var slot_result = SlotResult();

        Iq.Stanza iq = new Iq.Stanza.get(request_node) { to=flag.file_store_jid };

        HttpFileTransferError? e = null;
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            if (iq.is_error()) {
                e = new HttpFileTransferError.SLOT_REQUEST("Error getting upload/download url (Error Iq)");
                Idle.add((owned) callback);
                return;
            }
            string? url_get = iq.stanza.get_deep_attribute(NS_URI + ":slot", NS_URI + ":get", NS_URI + ":url");
            string? url_put = iq.stanza.get_deep_attribute(NS_URI + ":slot", NS_URI + ":put", NS_URI + ":url");
            if (url_get == null || url_put == null) {
                e = new HttpFileTransferError.SLOT_REQUEST("Error getting upload/download url: %s".printf(iq.stanza.to_string()));
                Idle.add((owned) callback);
                return;
            }

            slot_result.headers = new HashMap<string, string>();

            foreach (StanzaNode node in iq.stanza.get_deep_subnodes(NS_URI + ":slot", NS_URI + ":put", NS_URI + ":header")) {
                string header_name = node.get_attribute("name");
                if (header_name == "Authorization" || header_name == "Cookie" || header_name == "Expires") {
                    string? header_val = node.get_string_content();
                    if (header_val != null && header_val.length < 8192) {
                        header_val = header_val.replace("\n", "").replace("\r", "");
                        slot_result.headers[header_name] = header_val;
                    }
                }
            }

            slot_result.url_get = url_get;
            slot_result.url_put = url_put;

            Idle.add((owned) callback);
        });
        yield;

        if (e != null) {
            throw e;
        }

        return slot_result;
    }

    public override void attach(XmppStream stream) {
        stream.stream_negotiated.connect(query_availability);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Bind.Module.IDENTITY).bound_to_resource.disconnect(query_availability);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private void query_availability(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).request_info(stream, stream.remote_name, (stream, info_result) => {
            bool available = check_ns_in_info(stream, stream.remote_name, info_result);
            if (!available) {
                stream.get_module(ServiceDiscovery.Module.IDENTITY).request_items(stream, stream.remote_name, (stream, items_result) => {
                    foreach (Xep.ServiceDiscovery.Item item in items_result.items) {
                        stream.get_module(ServiceDiscovery.Module.IDENTITY).request_info(stream, item.jid, (stream, info_result) => {
                            check_ns_in_info(stream, item.jid, info_result);
                        });
                    }
                });
            }
        });
    }

    private bool check_ns_in_info(XmppStream stream, Jid jid, Xep.ServiceDiscovery.InfoResult info_result) {
        bool available = false;
        foreach (string feature in info_result.features) {
            if (feature == NS_URI) {
                available = true;
                break;
            }
        }

        if (!available)
            return false;

        long max_file_size = extract_max_file_size(info_result);
        stream.add_flag(new Flag(jid));
        feature_available(stream, max_file_size);
        return true;
    }

    private long extract_max_file_size(Xep.ServiceDiscovery.InfoResult info_result) {
        string? max_file_size_str = null;
        StanzaNode x_node = info_result.iq.stanza.get_deep_subnode("http://jabber.org/protocol/disco#info:query", "jabber:x:data:x");
        Gee.List<StanzaNode> field_nodes = x_node.get_subnodes("field", "jabber:x:data");
        foreach (StanzaNode node in field_nodes) {
            string? var_attr = node.get_attribute("var");
            if (var_attr == "max-file-size") {
                StanzaNode value_node = node.get_subnode("value", "jabber:x:data");
                max_file_size_str = value_node.get_string_content();
                break;
            }
        }
        if (max_file_size_str != null) return long.parse(max_file_size_str);
        return -1;
    }
}

public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {"EXTRACT_MESSAGE_2"};

    public override string action_group { get { return "EXTRACT_MESSAGE_2"; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(XmppStream stream, MessageStanza message) {
        string? oob_url = OutOfBandData.get_url_from_message(message);
        if (oob_url != null && oob_url == message.body) {
            stream.get_module(Module.IDENTITY).received_url(stream, message);
        }
        return false;
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "http_file_upload");

    public Jid file_store_jid;
    public int? max_file_size;

    public Flag(Jid file_store_jid) {
        this.file_store_jid = file_store_jid;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
