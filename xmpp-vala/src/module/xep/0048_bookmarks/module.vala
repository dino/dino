using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Bookmarks {
private const string NS_URI = "storage:bookmarks";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0048_bookmarks_module");

    public signal void received_conferences(XmppStream stream, Gee.List<Conference> conferences);

    public delegate void OnResult(XmppStream stream, Gee.List<Conference> conferences);
    public void get_conferences(XmppStream stream, owned OnResult listener) {
        StanzaNode get_node = new StanzaNode.build("storage", NS_URI).add_self_xmlns();
        stream.get_module(PrivateXmlStorage.Module.IDENTITY).retrieve(stream, get_node, (stream, node) => {
            Gee.List<Conference> conferences = get_conferences_from_stanza(node);
            listener(stream, conferences);
        });
    }

    public void set_conferences(XmppStream stream, Gee.List<Conference> conferences) {
        StanzaNode storage_node = (new StanzaNode.build("storage", NS_URI)).add_self_xmlns();
        foreach (Conference conference in conferences) {
            storage_node.put_node(conference.stanza_node);
        }
        stream.get_module(PrivateXmlStorage.Module.IDENTITY).store(stream, storage_node, (stream) => {
            stream.get_module(Module.IDENTITY).received_conferences(stream, conferences);
        });
    }

    public void add_conference(XmppStream stream, Conference conference) {
        get_conferences(stream, (stream, conferences) => {
            conferences.add(conference);
            stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
        });
    }

    public void replace_conference(XmppStream stream, Conference orig_conference, Conference modified_conference) {
        get_conferences(stream, (stream, conferences) => {
            foreach (Conference conference in conferences) {
                if (conference.autojoin == orig_conference.autojoin && conference.jid == orig_conference.jid &&
                        conference.name == orig_conference.name && conference.nick == orig_conference.nick) {
                    conference.autojoin = modified_conference.autojoin;
                    conference.jid = modified_conference.jid;
                    conference.name = modified_conference.name;
                    conference.nick = modified_conference.nick;
                break;
                }
            }
            stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
        });
    }

    public void remove_conference(XmppStream stream, Conference conference_remove) {
        get_conferences(stream, (stream, conferences) => {
            Conference? rem = null;
            foreach (Conference conference in conferences) {
                if (conference.name == conference_remove.name && conference.jid == conference_remove.jid && conference.autojoin == conference_remove.autojoin) {
                    rem = conference;
                    break;
                }
            }
            if (rem != null) conferences.remove(rem);
            stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
        });
    }

    public override void attach(XmppStream stream) { }

    public override void detach(XmppStream stream) { }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private static Gee.List<Conference> get_conferences_from_stanza(StanzaNode node) {
        Gee.List<Conference> conferences = new ArrayList<Conference>();
        Gee.List<StanzaNode> conferenceNodes = node.get_subnode("storage", NS_URI).get_subnodes("conference", NS_URI);
        foreach (StanzaNode conferenceNode in conferenceNodes) {
            Conference? conference = Conference.create_from_stanza_node(conferenceNode);
            conferences.add(conference);
        }
        return conferences;
    }
}

}
