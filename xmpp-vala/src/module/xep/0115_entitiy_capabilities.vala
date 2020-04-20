using Gee;

namespace Xmpp.Xep.EntityCapabilities {
    private const string NS_URI = "http://jabber.org/protocol/caps";

    private Regex? sha1_base64_regex = null;

    public string? get_caps_hash(Presence.Stanza presence) {
        if (sha1_base64_regex == null) {
            sha1_base64_regex = /^[A-Za-z0-9+\/]{27}=$/;
        }
        StanzaNode? c_node = presence.stanza.get_subnode("c", NS_URI);
        if (c_node == null) return null;
        string? ver_attribute = c_node.get_attribute("ver", NS_URI);
        if (ver_attribute == null || !sha1_base64_regex.match(ver_attribute)) return null;
        return ver_attribute;
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0115_entity_capabilities");

        private string own_ver_hash;
        private Storage storage;

        public Module(Storage storage) {
            this.storage = storage;
        }

        private string get_own_hash(XmppStream stream) {
            if (own_ver_hash == null) {
                own_ver_hash = compute_hash(stream.get_module(ServiceDiscovery.Module.IDENTITY).identities, stream.get_flag(ServiceDiscovery.Flag.IDENTITY).features, new ArrayList<DataForms.DataForm>());
            }
            return own_ver_hash;
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Presence.Module.IDENTITY).pre_send_presence_stanza.connect(on_pre_send_presence_stanza);
            stream.get_module(Presence.Module.IDENTITY).received_presence.connect(on_received_presence);
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Presence.Module.IDENTITY).pre_send_presence_stanza.disconnect(on_pre_send_presence_stanza);
            stream.get_module(Presence.Module.IDENTITY).received_presence.disconnect(on_received_presence);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

        private void on_pre_send_presence_stanza(XmppStream stream, Presence.Stanza presence) {
            if (presence.type_ == Presence.Stanza.TYPE_AVAILABLE) {
                presence.stanza.put_node(new StanzaNode.build("c", NS_URI).add_self_xmlns()
                    .put_attribute("hash", "sha-1")
                    .put_attribute("node", "https://dino.im")
                    .put_attribute("ver", get_own_hash(stream)));
            }
        }

        private void on_received_presence(XmppStream stream, Presence.Stanza presence) {
            string? caps_hash = get_caps_hash(presence);
            if (caps_hash == null) return;

            Gee.List<string> capabilities = storage.get_features(caps_hash);
            ServiceDiscovery.Identity identity = storage.get_identities(caps_hash);
            if (identity == null) {
                stream.get_module(ServiceDiscovery.Module.IDENTITY).request_info(stream, presence.from, (stream, query_result) => {
                    store_entity_result(stream, caps_hash, query_result);
                });
            } else {
                stream.get_flag(ServiceDiscovery.Flag.IDENTITY).set_entity_features(presence.from, capabilities);
            }
        }

        private void store_entity_result(XmppStream stream, string entity, ServiceDiscovery.InfoResult? query_result) {
            if (query_result == null) return;

            Gee.List<DataForms.DataForm> data_forms = new ArrayList<DataForms.DataForm>();
            foreach (StanzaNode node in query_result.iq.stanza.get_deep_subnodes(ServiceDiscovery.NS_URI_INFO + ":query", DataForms.NS_URI + ":x")) {
                data_forms.add(DataForms.DataForm.create_from_node(node));
            }

            if (compute_hash(query_result.identities, query_result.features, data_forms) == entity) {
                storage.store_identities(entity, query_result.identities);
                storage.store_features(entity, query_result.features);
                stream.get_flag(ServiceDiscovery.Flag.IDENTITY).set_entity_features(query_result.iq.from, query_result.features);
            }
        }

        private static string compute_hash(Gee.List<ServiceDiscovery.Identity> identities, Gee.List<string> features, Gee.List<DataForms.DataForm> data_forms) {
            identities.sort(compare_identities);
            features.sort();

            string s = "";
            foreach (ServiceDiscovery.Identity identity in identities) {
                string s_identity = identity.category + "/" + identity.type_ + "//";
                if (identity.name != null) s_identity += identity.name;
                s_identity += "<";
                s += s_identity;
            }
            foreach (string feature in features) {
                s += feature + "<";
            }

            data_forms.sort(compare_data_forms);
            foreach (DataForms.DataForm data_form in data_forms) {
                if (data_form.form_type == null) {
                    // If [..] the FORM_TYPE field is not of type "hidden" or the form does not include a FORM_TYPE field, ignore the form but continue processing. (XEP-0115)
                    continue;
                }
                s += data_form.form_type + "<";

                data_form.fields.sort(compare_data_fields);
                foreach (DataForms.DataForm.Field field in data_form.fields) {
                    s += field.var + "<";
                    Gee.List<string> values = field.get_values();
                    values.sort();
                    foreach (string value in values) {
                        s += value + "<";
                    }
                }
            }

            Checksum c = new Checksum(ChecksumType.SHA1);
            c.update(s.data, -1);
            size_t size = 20;
            uint8[] buf = new uint8[size];
            c.get_digest(buf, ref size);

            return Base64.encode(buf);
        }

        private static int compare_identities(ServiceDiscovery.Identity a, ServiceDiscovery.Identity b) {
            int category_comp = a.category.collate(b.category);
            if (category_comp != 0) return category_comp;
            int type_comp = a.type_.collate(b.type_);
            if (type_comp != 0) return type_comp;
            // TODO lang
            return 0;
        }

        private static int compare_data_forms(DataForms.DataForm a, DataForms.DataForm b) {
            if (a.form_type != null && b.form_type != null) {
                return a.form_type.collate(b.form_type);
            }
            return 0;
        }

        private static int compare_data_fields(DataForms.DataForm.Field a, DataForms.DataForm.Field b) {
            if (a.var != null && b.var != null) {
                return a.var.collate(b.var);
            }
            return 0;
        }
    }

    public interface Storage : Object {
        public abstract void store_identities(string entity, Gee.List<ServiceDiscovery.Identity> identities);
        public abstract void store_features(string entity, Gee.List<string> capabilities);
        public abstract ServiceDiscovery.Identity? get_identities(string entity);
        public abstract Gee.List<string> get_features(string entity);
    }
}
