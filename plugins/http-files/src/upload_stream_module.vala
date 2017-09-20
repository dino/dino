using Xmpp;
using Xmpp.Core;
using Xmpp.Xep;

namespace Dino.Plugins.HttpFiles {

private const string NS_URI = "urn:xmpp:http:upload";
private const string NS_URI_0 = "urn:xmpp:http:upload:0";

public class UploadStreamModule : XmppStreamModule {
    public static Core.ModuleIdentity<UploadStreamModule> IDENTITY = new Core.ModuleIdentity<UploadStreamModule>(NS_URI, "0363_http_file_upload");

    public signal void feature_available(XmppStream stream, int? max_file_size);

    public delegate void OnUploadOk(XmppStream stream, string url_down);
    public delegate void OnError(XmppStream stream, string error);
    public void upload(XmppStream stream, string file_uri, owned OnUploadOk listener, owned OnError error_listener) {
        File file = File.new_for_path(file_uri);
        FileInfo file_info = file.query_info("*", FileQueryInfoFlags.NONE);
        request_slot(stream, file.get_basename(), (int)file_info.get_size(), file_info.get_content_type(),
            (stream, url_down, url_up) => {
                uint8[] data;
                FileUtils.get_data(file_uri, out data);

                Soup.Message message = new Soup.Message("PUT", url_up);
                message.set_request(file_info.get_content_type(), Soup.MemoryUse.COPY, data);
                Soup.Session session = new Soup.Session();
                session.send_async.begin(message, null, (obj, res) => {
                    try {
                        session.send_async.end(res);
                        if (message.status_code >= 200 && message.status_code < 300) {
                            listener(stream, url_down);
                        } else {
                            error_listener(stream, "HTTP status code " + message.status_code.to_string());
                        }
                    } catch (Error e) {
                        error_listener(stream, e.message);
                    }
                });
            },
            error_listener);
    }

    private delegate void OnSlotOk(XmppStream stream, string url_get, string url_put);
    private void request_slot(XmppStream stream, string filename, int file_size, string? content_type, owned OnSlotOk listener, owned OnError error_listener) {
        Flag? flag = stream.get_flag(Flag.IDENTITY);
        if (flag == null) return;

        StanzaNode? request_node = null;
        switch (flag.ns_ver) {
            case NS_URI_0:
                request_node = new StanzaNode.build("request", NS_URI_0).add_self_xmlns();
                request_node.put_attribute("filename", filename).put_attribute("size", file_size.to_string());
                if (content_type != null) request_node.put_attribute("content-type", content_type);
                break;
            case NS_URI:
                request_node = new StanzaNode.build("request", NS_URI).add_self_xmlns()
                        .put_node(new StanzaNode.build("filename", NS_URI).put_node(new StanzaNode.text(filename)))
                        .put_node(new StanzaNode.build("size", NS_URI).put_node(new StanzaNode.text(file_size.to_string())));
                if (content_type != null) {
                    request_node.put_node(new StanzaNode.build("content-type", NS_URI).put_node(new StanzaNode.text(content_type)));
                }
                break;
        }
        Iq.Stanza iq = new Iq.Stanza.get(request_node) { to=flag.file_store_jid };
        stream.get_module(Iq.Module.IDENTITY).send_iq(stream, iq, (stream, iq) => {
            if (iq.is_error()) {
                error_listener(stream, "Error getting upload/download url");
                return;
            }
            string? url_get = null, url_put = null;
            switch (flag.ns_ver) {
                case NS_URI_0:
                    url_get = iq.stanza.get_deep_attribute(flag.ns_ver + ":slot", flag.ns_ver + ":get", flag.ns_ver + ":url");
                    url_put = iq.stanza.get_deep_attribute(flag.ns_ver + ":slot", flag.ns_ver + ":put", flag.ns_ver + ":url");
                    break;
                case NS_URI:
                    url_get = iq.stanza.get_deep_string_content(flag.ns_ver + ":slot", flag.ns_ver + ":get");
                    url_put = iq.stanza.get_deep_string_content(flag.ns_ver + ":slot", flag.ns_ver + ":put");
                    break;
            }
            if (url_get == null || url_put == null) {
                error_listener(stream, "Error getting upload/download url");
            }
            listener(stream, url_get, url_put);
        });
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

    private bool check_ns_in_info(XmppStream stream, string jid, Xep.ServiceDiscovery.InfoResult info_result) {
        bool ver_available = false;
        bool ver_0_available = false;
        foreach (string feature in info_result.features) {
            if (feature == NS_URI_0) {
                ver_0_available = true;
                break;
            } else if (feature == NS_URI) {
                ver_available = true;
            }
        }

        if (ver_available || ver_0_available) {
            int? max_file_size = extract_max_file_size(info_result);
            if (ver_0_available) {
                stream.add_flag(new Flag(jid, NS_URI_0));
            } else if (ver_available) {
                stream.add_flag(new Flag(jid, NS_URI));
            }

            feature_available(stream, max_file_size);
            return true;
        }
        return false;
    }

    private int? extract_max_file_size(Xep.ServiceDiscovery.InfoResult info_result) {
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
        if (max_file_size_str != null) return int.parse(max_file_size_str);
        return null;
    }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "service_discovery");

    public string file_store_jid;
    public string ns_ver;
    public int? max_file_size;

    public Flag(string file_store_jid, string ns_ver) {
        this.file_store_jid = file_store_jid;
        this.ns_ver = ns_ver;
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
