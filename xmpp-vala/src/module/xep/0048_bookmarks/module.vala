using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Bookmarks {
private const string NS_URI = "storage:bookmarks";

public class Module : XmppStreamModule {
    public const string ID = "0048_bookmarks_module";
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, ID);

    public signal void conferences_updated(XmppStream stream, ArrayList<Conference> conferences);

    [CCode (has_target = false)] public delegate void OnResult(XmppStream stream, ArrayList<Conference> conferences, Object? reference);
    public void get_conferences(XmppStream stream, OnResult listener, Object? store) {
        StanzaNode get_node = new StanzaNode.build("storage", NS_URI).add_self_xmlns();
        stream.get_module(PrivateXmlStorage.Module.IDENTITY).retrieve(stream, get_node, on_conferences_received, Tuple.create(listener, store));
    }

    private static void on_conferences_received(XmppStream stream, StanzaNode node, Object? o) {
        Tuple<OnResult, Object?> tuple = o as Tuple<OnResult, Object?>;
        OnResult on_result = tuple.a;
        on_result(stream, get_conferences_from_stanza(node), tuple.b);
    }

    public void set_conferences(XmppStream stream, ArrayList<Conference> conferences) {
        StanzaNode storage_node = (new StanzaNode.build("storage", NS_URI)).add_self_xmlns();
        foreach (Conference conference in conferences) {
            storage_node.put_node(conference.stanza_node);
        }
        stream.get_module(PrivateXmlStorage.Module.IDENTITY).store(stream, storage_node, on_set_conferences_response, conferences);
    }

    private static void on_set_conferences_response(XmppStream stream, Object? o) {
        ArrayList<Conference> conferences = o as ArrayList<Conference>;
        stream.get_module(Module.IDENTITY).conferences_updated(stream, conferences);
    }

    public void add_conference(XmppStream stream, Conference add) {
        get_conferences(stream, on_add_conference_response, add);
    }

    private static void on_add_conference_response(XmppStream stream, ArrayList<Conference> conferences, Object? o) {
        Conference add = o as Conference;
        conferences.add(add);
        stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
    }

    public void replace_conference(XmppStream stream, Conference was, Conference modified) {
        get_conferences(stream, on_replace_conference_response, Tuple.create(was, modified));
    }

    private static void on_replace_conference_response(XmppStream stream, ArrayList<Conference> conferences, Object? o) {
        Tuple<Conference, Conference> tuple = o as Tuple<Conference, Conference>;
        Conference was = tuple.a;
        Conference modified = tuple.b;
        foreach (Conference conference in conferences) {
            if (conference.name == was.name && conference.jid == was.jid && conference.autojoin == was.autojoin) {
                conference.autojoin = modified.autojoin;
                conference.name = modified.name;
                conference.jid = modified.jid;
            break;
            }
        }
        stream.get_module(Module.IDENTITY).set_conferences(stream, conferences);
    }

    public void remove_conference(XmppStream stream, Conference conference) {
        get_conferences(stream, on_remove_conference_response, conference);
    }

    private static void on_remove_conference_response(XmppStream stream, ArrayList<Conference> conferences, Object? o) {
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
    }

    public override void attach(XmppStream stream) { }

    public override void detach(XmppStream stream) { }

    public static void require(XmppStream stream) {
        if (stream.get_module(IDENTITY) == null) stderr.printf("");
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return ID; }

    private static ArrayList<Conference> get_conferences_from_stanza(StanzaNode node) {
        ArrayList<Conference> conferences = new ArrayList<Conference>();
        ArrayList<StanzaNode> conferenceNodes = node.get_subnode("storage", NS_URI).get_subnodes("conference", NS_URI);
        foreach (StanzaNode conferenceNode in conferenceNodes) {
            conferences.add(new Conference.from_stanza_node(conferenceNode));
        }
        return conferences;
    }
}

}
