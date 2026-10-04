using Gee;
namespace Xmpp.Xep.MessageDisplayedSynchronization {
    public const string NS_URI = "urn:xmpp:mds:displayed:0";
    public const string NS_URI_SERVER_ASSIST = "urn:xmpp:mds:server-assist:0";

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0490_message_displayed_synchronization");

        public signal void on_message_displayed(Jid conversation_jid, Jid stanza_id_by_jid, string stanza_id);

        private void handle_displayed_node_item(XmppStream stream, string? id, StanzaNode? item) {
            if (id == null || item == null) return;
            try {
                Jid conversation_jid = Jid.from_string(id);
                StanzaNode? stanza_id_node = item.get_subnode("stanza-id", UniqueStableStanzaIDs.NS_URI);
                if (stanza_id_node == null || stanza_id_node.get_attribute("by") == null || stanza_id_node.get_attribute("id") == null) return;
                Jid stanza_id_by_jid = Jid.from_string(stanza_id_node.get_attribute("by"));
                string stanza_id = stanza_id_node.get_attribute("id");
                if (stream.has_flag(Flag.IDENTITY)) {
                    stream.get_flag(Flag.IDENTITY).learn_mds(conversation_jid, stanza_id_by_jid, stanza_id);
                }
                on_message_displayed(conversation_jid, stanza_id_by_jid, stanza_id);
            } catch (InvalidJidError e) {
                warning("Received mds item with invalid jid, ignoring: %s", e.message);
            }
        }

        private void on_pubsub_item(XmppStream stream, Jid jid, string id, StanzaNode? item) {
            if (!jid.equals(stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid)) {
                warning("Received alleged mds item from %s, ignoring", jid.to_string());
                return;
            }
            handle_displayed_node_item(stream, id, item);
        }

        private void on_initial_presence_sent(XmppStream stream) {
            var pubsub = stream.get_module(Pubsub.Module.IDENTITY);
            pubsub.request_all.begin(stream, null, NS_URI, (_, res) => {
                try {
                    Gee.List<StanzaNode>? items = pubsub.request_all.end(res);
                    foreach (StanzaNode node_item in items) {
                        handle_displayed_node_item(stream, node_item.get_attribute("id"), node_item.get_subnode("displayed", NS_URI));
                    }
                } catch (IOError e) {
                    warning("Failed requesting initial mds set: %s", e.message);
                }
            });
        }

        public async bool update_message_displayed(XmppStream stream, Jid conversation_jid, Jid stanza_id_by_jid, string stanza_id) {
            var pubsub = stream.get_module(Pubsub.Module.IDENTITY);
            var node = new StanzaNode.build("displayed", NS_URI).add_self_xmlns()
                    .put_node(new StanzaNode.build("stanza-id", UniqueStableStanzaIDs.NS_URI).add_self_xmlns()
                        .put_attribute("by", stanza_id_by_jid.to_string())
                        .put_attribute("id", stanza_id));
            var options = new Pubsub.PublishOptions()
                    .set_persist_items(true)
                    .set_max_items("max")
                    .set_send_last_published_item("never")
                    .set_access_model("whitelist");
            try {
                return yield pubsub.publish(stream, stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid, NS_URI, conversation_jid.to_string(), node, options);
            } catch (IOError e) {
                warning("Failed publishing mds item: %s", e.message);
                return false;
            }
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NS_URI, on_pubsub_item, null, null);
            stream.get_module(Presence.Module.IDENTITY).initial_presence_sent.connect(on_initial_presence_sent);
            if (!stream.has_flag(Flag.IDENTITY)) {
                stream.add_flag(new Flag());
            }
        }

        public override void detach(XmppStream stream) {
            stream.get_module(Presence.Module.IDENTITY).initial_presence_sent.disconnect(on_initial_presence_sent);
            stream.get_module(Pubsub.Module.IDENTITY).remove_filtered_notification(stream, NS_URI);
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }

    }

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "mds");

        private Map<Jid, Jid> stanza_id_bys = new HashMap<Jid, Jid>(Jid.hash_func, Jid.equals_func);
        private Map<Jid, string> stanza_ids = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);

        public void learn_mds(Jid jid, Jid stanza_by, string stanza_id) {
            stanza_id_bys[jid] = stanza_by;
            stanza_ids[jid] = stanza_id;
        }

        public bool is_displayed(Jid conversation_jid, Jid stanza_by, string stanza_id) {
            return stanza_id_bys[conversation_jid].equals(stanza_by) && stanza_ids[conversation_jid] == stanza_id;
        }

        public override string get_ns() { return NS_URI; }
        public override string get_id() { return IDENTITY.id; }
    }
}