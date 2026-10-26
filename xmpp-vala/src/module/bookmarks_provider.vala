using Gee;

namespace Xmpp {

public interface BookmarksProvider : Object {
    public signal void conference_added(XmppStream stream, Conference conferences);
    public signal void conference_removed(XmppStream stream, Jid jid);
    public signal void conference_changed(XmppStream stream, Conference conferences);
    public signal void received_conferences(XmppStream stream, Set<Conference> conferences);

    public async abstract async Set<Conference>? get_conferences(XmppStream stream) throws IOError;
    public async abstract void add_conference(XmppStream stream, Conference conference) throws IOError;
    public async abstract void remove_conference(XmppStream stream, Conference conference) throws IOError;
    public async abstract void replace_conference(XmppStream stream, Jid muc_jid, Conference modified_conference) throws IOError;
}

}
