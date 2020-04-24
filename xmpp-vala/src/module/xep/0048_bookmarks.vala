using Gee;

namespace Xmpp.Xep.Bookmarks {
private const string NS_URI = "storage:bookmarks";

public class Module : BookmarksProvider, XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0048_bookmarks_module");

    public async Set<Conference>? get_conferences(XmppStream stream) {

        StanzaNode get_node = new StanzaNode.build("storage", NS_URI).add_self_xmlns();
        StanzaNode? result_node = yield stream.get_module(PrivateXmlStorage.Module.IDENTITY).retrieve(stream, get_node);
        if (result_node == null) return null;

        Set<Conference> ret = new HashSet<Conference>(Conference.hash_func, Conference.equals_func);
        Gee.List<StanzaNode> conferences_node = result_node.get_subnode("storage", NS_URI).get_subnodes("conference", NS_URI);
        foreach (StanzaNode conference_node in conferences_node) {
            Conference? conference = Bookmarks1Conference.create_from_stanza_node(conference_node);
            ret.add(conference);
        }
        return ret;
    }

    private async void set_conferences(XmppStream stream, Set<Conference> conferences) {
        StanzaNode storage_node = (new StanzaNode.build("storage", NS_URI)).add_self_xmlns();
        foreach (Conference conference in conferences) {
            Bookmarks1Conference? bookmarks1conference = conference as Bookmarks1Conference;
            if (bookmarks1conference != null) {
                storage_node.put_node(bookmarks1conference.stanza_node);
            } else {
                StanzaNode conference_node = new StanzaNode.build("conference", NS_URI)
                    .put_attribute("jid", conference.jid.to_string())
                    .put_attribute("autojoin", conference.autojoin ? "true" : "false");
                if (conference.name != null) {
                    conference_node.put_attribute("name", conference.name);
                }
                if (conference.nick != null) {
                    conference_node.put_node(new StanzaNode.build("nick", NS_URI)
                        .put_node(new StanzaNode.text(conference.nick)));
                }
                // TODO (?) Bookmarks 2 currently don't define a password
                storage_node.put_node(conference_node);
            }
        }
        yield stream.get_module(PrivateXmlStorage.Module.IDENTITY).store(stream, storage_node);
        stream.get_module(Module.IDENTITY).received_conferences(stream, conferences);
    }

    public async void add_conference(XmppStream stream, Conference conference) {
        Set<Conference>? conferences = yield get_conferences(stream);
        conferences.add(conference);
        yield set_conferences(stream, conferences);
    }

    public async void replace_conference(XmppStream stream, Jid muc_jid, Conference modified_conference) {
        Set<Conference>? conferences = yield get_conferences(stream);
        foreach (Conference conference in conferences) {
            if (conference.jid.equals(muc_jid)) {
                conference.autojoin = modified_conference.autojoin;
                conference.name = modified_conference.name;
                conference.nick = modified_conference.nick;
                conference.password = modified_conference.password;
            }
        }
        yield set_conferences(stream, conferences);
    }

    public async void remove_conference(XmppStream stream, Conference conference_remove) {
        Set<Conference>? conferences = yield get_conferences(stream);
        conferences.remove(conference_remove);
        yield set_conferences(stream, conferences);
    }

    public override void attach(XmppStream stream) { }

    public override void detach(XmppStream stream) { }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

}
