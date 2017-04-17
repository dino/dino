using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Bookmarks {
private const string NS_URI = "storage:bookmarks";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0048_bookmarks_module");

    public signal void conferences_updated(XmppStream stream, ArrayList<Conference> conferences);

    [CCode (has_target = false)] public delegate void OnResult(XmppStream stream, ArrayList<Conference> conferences, Object? reference);
    public void get_conferences(XmppStream stream, OnResult listener, Object? store) {
        StanzaNode get_node = new StanzaNode.build("storage", NS_URI).add_self_xmlns();
        stream.get_module(PrivateXmlStorage.Module.IDENTITY).retrieve(stream, get_node, (stream, node, o) => {
            Tuple<OnResult, Object?> tuple = o as Tuple<OnResult, Object?>;
            OnResult on_result = tuple.a;
            on_result(stream, get_conferences_from_stanza(node), tuple.b);
        }, Tuple.create(listener, store));
    }

    public void set_conferences(XmppStream stream, ArrayList<Conference> conferences) {
        StanzaNode storage_node = (new StanzaNode.build("storage", NS_URI)).add_self_xmlns();
        foreach (Conference conference in conferences) {
            storage_node.put_node(conference.stanza_node);
        }
        stream.get_module(PrivateXmlStorage.Module.IDENTITY).store(stream, storage_node, (stream, o) => {
            stream.get_module(Module.IDENTITY).conferences_updated(stream, o as ArrayList<Conference>);
        }, conferences);
    }

    public void add_conference(XmppStream stream, Conference add_) {
        get_conferences(stream, (stream, conferences, o) => {
            Conference add = o as Conference;
            conferences.add(add);
            stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
        }, add_);
    }

    public void replace_conference(XmppStream stream, Conference was_, Conference modified_) {
        get_conferences(stream, (stream, conferences, o) => {
            Tuple<Conference, Conference> tuple = o as Tuple<Conference, Conference>;
            Conference was = tuple.a;
            Conference modified = tuple.b;
            foreach (Conference conference in conferences) {
                if (conference.autojoin == was.autojoin && conference.jid == was.jid &&
                        conference.name == was.name && conference.nick == was.nick) {
                    conference.autojoin = modified.autojoin;
                    conference.jid = modified.jid;
                    conference.name = modified.name;
                    conference.nick = modified.nick;
                break;
                }
            }
            stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
        }, Tuple.create(was_, modified_));
    }

    public void remove_conference(XmppStream stream, Conference conference_) {
        get_conferences(stream, (stream, conferences, o) => {
            Conference remove = o as Conference;
            Conference? rem = null;
            foreach (Conference conference in conferences) {
                if (conference.name == remove.name && conference.jid == remove.jid && conference.autojoin == remove.autojoin) {
                    rem = conference;
                    break;
                }
            }
            if (rem != null) conferences.remove(rem);
            stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
        }, conference_);
    }

    public override void attach(XmppStream stream) { }

    public override void detach(XmppStream stream) { }

    public static void require(XmppStream stream) {
        if (stream.get_module(IDENTITY) == null) stderr.printf("");
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }

    private static ArrayList<Conference> get_conferences_from_stanza(StanzaNode node) {
        ArrayList<Conference> conferences = new ArrayList<Conference>();
        ArrayList<StanzaNode> conferenceNodes = node.get_subnode("storage", NS_URI).get_subnodes("conference", NS_URI);
        foreach (StanzaNode conferenceNode in conferenceNodes) {
            Conference? conference = Conference.create_from_stanza_node(conferenceNode);
            conferences.add(conference);
        }
        return conferences;
    }
}

}
