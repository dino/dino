using Gee;

namespace Xmpp.Xep.Bookmarks2 {

public const string NS_URI = "urn:xmpp:bookmarks:1";
public const string NS_URI_COMPAT = NS_URI + "#compat";

public class Module : BookmarksProvider, XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0402_bookmarks2");

    public async Set<Conference>? get_conferences(XmppStream stream) {
        HashMap<Jid, Conference>? hm = null;

        Flag? flag = stream.get_flag(Flag.IDENTITY);
        if (flag != null) {
            hm = flag.conferences;
        } else {
            Gee.List<StanzaNode>? items = yield stream.get_module(Pubsub.Module.IDENTITY).request_all(stream, stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid, NS_URI);
            if (items == null) return null;

            hm = new HashMap<Jid, Conference>(Jid.hash_func, Jid.equals_func);
            foreach (StanzaNode item_node in items) {
                Conference? conference = parse_item_node(item_node.sub_nodes[0], item_node.get_attribute("id"));
                if (conference == null) continue;
                hm[conference.jid] = conference;
            }
            stream.add_flag(new Flag(hm));
        }


        var ret = new HashSet<Conference>();
        foreach (var conference in hm.values) {
            ret.add(conference);
        }
        return ret;
    }

    public async void add_conference(XmppStream stream, Conference conference) {
        StanzaNode conference_node = new StanzaNode.build("conference", NS_URI).add_self_xmlns()
            .put_attribute("autojoin", conference.autojoin.to_string());
        if (conference.name != null) {
            conference_node.put_attribute("name", conference.name);
        }
        if (conference.nick != null) {
            conference_node.put_node((new StanzaNode.build("nick", NS_URI)).put_node(new StanzaNode.text(conference.nick)));
        }
        if (conference.password != null) {
            conference_node.put_node((new StanzaNode.build("password", NS_URI)).put_node(new StanzaNode.text(conference.password)));
        }
        var publish_options = new Pubsub.PublishOptions()
                .set_persist_items(true)
                .set_max_items("max")
                .set_send_last_published_item("never")
                .set_access_model("whitelist");

        yield stream.get_module(Pubsub.Module.IDENTITY).publish(stream, stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid, NS_URI, conference.jid.to_string(), conference_node, publish_options);
    }

    public async void replace_conference(XmppStream stream, Jid muc_jid, Conference modified_conference) {
        yield add_conference(stream, modified_conference);
    }

    public async void remove_conference(XmppStream stream, Conference conference) {
        yield stream.get_module(Pubsub.Module.IDENTITY).retract_item(stream,
                    stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid,
                    NS_URI,
                    conference.jid.to_string());
    }

    private void on_pupsub_item(XmppStream stream, Jid jid, string id, StanzaNode? node) {
        if (!jid.equals(stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid)) {
            warning("Received alleged bookmarks:1 item from %s, ignoring", jid.to_string());
            return;
        }

        Conference conference = parse_item_node(node, id);
        Flag? flag = stream.get_flag(Flag.IDENTITY);
        if (flag != null) {
            flag.conferences[conference.jid] = conference;
        }
        conference_added(stream, conference);
    }

    private void on_pupsub_retract(XmppStream stream, Jid jid, string id) {
        if (!jid.equals(stream.get_flag(Bind.Flag.IDENTITY).my_jid.bare_jid)) {
            warning("Received alleged bookmarks:1 retract from %s, ignoring", jid.to_string());
            return;
        }

        try {
            Jid jid_parsed = new Jid(id);
            Flag? flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) {
                flag.conferences.unset(jid_parsed);
            }
            conference_removed(stream, jid_parsed);
        } catch (InvalidJidError e) {
            warning("Ignoring conference bookmark update with invalid Jid: %s", e.message);
        }
    }

    private Conference? parse_item_node(StanzaNode conference_node, string id) {
        Conference conference = new Conference();
        try {
            Jid jid_parsed = new Jid(id);
            if (jid_parsed.resourcepart != null) return null;
            conference.jid = jid_parsed;
        } catch (InvalidJidError e) {
            warning("Ignoring conference bookmark update with invalid Jid: %s", e.message);
            return null;
        }

        if (conference_node.name != "conference" || conference_node.ns_uri != NS_URI) return null;

        conference.name = conference_node.get_attribute("name", NS_URI);
        conference.autojoin = conference_node.get_attribute_bool("autojoin", false, NS_URI);
        conference.nick = conference_node.get_deep_string_content("nick");
        conference.password = conference_node.get_deep_string_content("password");
        return conference;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(Pubsub.Module.IDENTITY).add_filtered_notification(stream, NS_URI, on_pupsub_item, on_pupsub_retract, null);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(Pubsub.Module.IDENTITY).remove_filtered_notification(stream, NS_URI);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "bookmarks2");

    public Flag(HashMap<Jid, Conference> conferences) {
        this.conferences = conferences;
    }

    public HashMap<Jid, Conference> conferences = new HashMap<Jid, Conference>(Jid.hash_func, Jid.equals_func);

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
