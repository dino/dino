using Xmpp.Core;

namespace Xmpp.Xep.OutOfBandData {

public const string NS_URI = "jabber:x:oob";

public static void add_url_to_message(Message.Stanza message, string url, string? desc = null) {
    message.stanza.put_node(new StanzaNode.build("x", NS_URI).add_self_xmlns().put_node(new StanzaNode.build("url", NS_URI).put_node(new StanzaNode.text(url))));
}

}
