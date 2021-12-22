using Gee;

namespace Xmpp.Xep.Coin {
    private const string NS_RFC = "urn:ietf:params:xml:ns:conference-info";

    public class Module : XmppStreamModule, Iq.Handler {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_RFC, "0298_coin");

        public signal void coin_info_received(Jid jid, ConferenceInfo info);

        public async override void on_iq_set(XmppStream stream, Iq.Stanza iq) {
            ConferenceInfo? info = parse_node(iq.stanza.get_subnode("conference-info", NS_RFC), null);
            if (info == null) return;

            coin_info_received(iq.from, info);
        }

        public override void attach(XmppStream stream) {
            stream.get_module(Iq.Module.IDENTITY).register_for_namespace(NS_RFC, this);
        }

        public override void detach(XmppStream stream) { }

        public override string get_ns() { return NS_RFC; }

        public override string get_id() { return IDENTITY.id; }
    }

    public ConferenceInfo? parse_node(StanzaNode conference_node, ConferenceInfo? previous_conference_info) {
        string? version_str = conference_node.get_attribute("version");
        string? conference_state = conference_node.get_attribute("state");
        if (version_str == null || conference_state == null) return null;

        int version = int.parse(version_str);
        if (previous_conference_info != null && version <= previous_conference_info.version) return null;

        ConferenceInfo conference_info = previous_conference_info ?? new ConferenceInfo();
        conference_info.version = version;

        Gee.List<StanzaNode> user_nodes = conference_node.get_deep_subnodes(NS_RFC + ":users", NS_RFC + ":user");
        foreach (StanzaNode user_node in user_nodes) {
            string? jid_string = user_node.get_attribute("entity");
            if (jid_string == null) continue;
//            if (!jid_string.has_prefix("xmpp:")) continue; // silk does this wrong
            Jid? jid = null;
            try {
                jid = new Jid(jid_string.substring(4));
            } catch (Error e) {
                continue;
            }
            string user_state = user_node.get_attribute("state");
            if (conference_state == "full" && user_state != "full") return null;

            if (user_state == "deleted") {
                conference_info.users.unset(jid);
                continue;
            }

            ConferenceUser user = new ConferenceUser();
            user.jid = jid;
            user.display_text = user_node.get_deep_string_content(NS_RFC + ":display-text");

            Gee.List<StanzaNode> endpoint_nodes = user_node.get_subnodes("endpoint");
            foreach (StanzaNode entpoint_node in endpoint_nodes) {
                Gee.List<StanzaNode> media_nodes = entpoint_node.get_subnodes("media");
                foreach (StanzaNode media_node in media_nodes) {
                    string? id = media_node.get_attribute("id");
                    string? ty = media_node.get_deep_string_content(NS_RFC + ":type");
                    string? src_id_str = media_node.get_deep_string_content(NS_RFC + ":src-id");

                    if (id == null) continue;

                    ConferenceMedia media = new ConferenceMedia();
                    media.id = id;
                    media.src_id = src_id_str != null ? int.parse(src_id_str) : -1;
                    media.ty = ty;
                    user.medias[id] = media;
                }

                conference_info.users[user.jid] = user;
            }
        }
        return conference_info;
    }

    public class ConferenceInfo {
        public int version = -1;
        public HashMap<Jid, ConferenceUser> users = new HashMap<Jid, ConferenceUser>(Jid.hash_func, Jid.equals_func);

        public StanzaNode to_xml() {
            StanzaNode ret = new StanzaNode.build("conference-info", NS_RFC).add_self_xmlns()
                    .put_attribute("version", this.version.to_string())
                    .put_attribute("state", "full");
            StanzaNode users_node = new StanzaNode.build("users", NS_RFC);

            foreach (ConferenceUser user in this.users.values) {
                users_node.put_node(user.to_xml());
            }
            ret.put_node(users_node);
            return ret;
        }
    }

    public class ConferenceUser {
        public Jid jid;
        public string? display_text;
        public HashMap<string, ConferenceMedia> medias = new HashMap<string, ConferenceMedia>();

        public StanzaNode to_xml() {
            StanzaNode user_node = new StanzaNode.build("user", NS_RFC)
                    .put_attribute("entity", jid.to_string());
            foreach (ConferenceMedia media in medias.values) {
                user_node.put_node(media.to_xml());
            }
            return user_node;
        }
    }

    public class ConferenceMedia {
        public string id;
        public string? ty;
        public int src_id = -1;

        public StanzaNode to_xml() {
            StanzaNode media_node = new StanzaNode.build("media", NS_RFC)
                    .put_attribute("id", id);
            if (ty != null) {
                media_node.put_node(new StanzaNode.build("type", NS_RFC).put_node(new StanzaNode.text(ty)));
            }
            if (src_id != -1) {
                media_node.put_node(new StanzaNode.build("src-id", NS_RFC).put_node(new StanzaNode.text(src_id.to_string())));
            }
            return media_node;
        }
    }
}