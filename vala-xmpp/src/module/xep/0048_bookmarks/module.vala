using Gee;

using Xmpp.Core;

namespace Xmpp.Xep.Bookmarks {
private const string NS_URI = "storage:bookmarks";

public class Module : XmppStreamModule {
    public const string ID = "0048_bookmarks_module";

    public signal void conferences_updated(XmppStream stream, ArrayList<Conference> conferences);

    public void get_conferences(XmppStream stream, ConferencesRetrieveResponseListener response_listener) {
        StanzaNode get_node = new StanzaNode.build("storage", NS_URI).add_self_xmlns();
        PrivateXmlStorage.Module.get_module(stream).retrieve(stream, get_node, new GetConferences(response_listener));
    }

    public void set_conferences(XmppStream stream, ArrayList<Conference> conferences) {
        StanzaNode storage_node = (new StanzaNode.build("storage", NS_URI)).add_self_xmlns();
        foreach (Conference conference in conferences) {
            storage_node.put_node(conference.stanza_node);
        }
        PrivateXmlStorage.Module.get_module(stream).store(stream, storage_node, new StoreResponseListenerImpl(conferences));
    }

    private class StoreResponseListenerImpl : PrivateXmlStorage.StoreResponseListener, Object {
        ArrayList<Conference> conferences;
        public StoreResponseListenerImpl(ArrayList<Conference> conferences) {
            this.conferences = conferences;
        }
        public void on_success(XmppStream stream) {
            Module.get_module(stream).conferences_updated(stream, conferences);
        }
    }

    public void add_conference(XmppStream stream, Conference add) {
        get_conferences(stream, new AddConference(add));
    }

    public void replace_conference(XmppStream stream, Conference was, Conference modified) {
        get_conferences(stream, new ModifyConference(was, modified));
    }

    public void remove_conference(XmppStream stream, Conference conference) {
        get_conferences(stream, new RemoveConference(conference));
    }

    private class GetConferences : PrivateXmlStorage.RetrieveResponseListener, Object {
        ConferencesRetrieveResponseListener response_listener;

        public GetConferences(ConferencesRetrieveResponseListener response_listener) {
            this.response_listener = response_listener;
        }

        public void on_result(XmppStream stream, StanzaNode node) {
            response_listener.on_result(stream, get_conferences_from_stanza(node));
        }
    }

    private class AddConference : ConferencesRetrieveResponseListener, Object {
        private Conference conference;
        public AddConference(Conference conference) {
            this.conference = conference;
        }
        public void on_result(XmppStream stream, ArrayList<Conference> conferences) {
            conferences.add(conference);
            Module.get_module(stream).set_conferences(stream, conferences);
        }
    }

    private class ModifyConference : ConferencesRetrieveResponseListener, Object {
        private Conference was;
        private Conference modified;
        public ModifyConference(Conference was, Conference modified) {
            this.was = was;
            this.modified = modified;
        }
        public void on_result(XmppStream stream, ArrayList<Conference> conferences) {
            foreach (Conference conference in conferences) {
                if (conference.name == was.name && conference.jid == was.jid && conference.autojoin == was.autojoin) {
                    conference.autojoin = modified.autojoin;
                    conference.name = modified.name;
                    conference.jid = modified.jid;
                    break;
                }
            }
            Module.get_module(stream).set_conferences(stream, conferences);
        }
    }

    private class RemoveConference : ConferencesRetrieveResponseListener, Object {
        private Conference remove;
        public RemoveConference(Conference remove) {
            this.remove = remove;
        }
        public void on_result(XmppStream stream, ArrayList<Conference> conferences) {
            Conference? rem = null;
            foreach (Conference conference in conferences) {
                if (conference.name == remove.name && conference.jid == remove.jid && conference.autojoin == remove.autojoin) {
                    rem = conference;
                }
            }
            if (rem != null) conferences.remove(rem);
            Module.get_module(stream).set_conferences(stream, conferences);
        }
    }

    public override void attach(XmppStream stream) { }

    public override void detach(XmppStream stream) { }

    public static Module? get_module(XmppStream stream) {
        return (Module?) stream.get_module(NS_URI, ID);
    }

    public static void require(XmppStream stream) {
        if (get_module(stream) == null) stderr.printf("");
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

public interface ConferencesRetrieveResponseListener : Object {
    public abstract void on_result(XmppStream stream, ArrayList<Conference> conferences);
}

}
