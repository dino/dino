namespace Xmpp.Xep.OutOfBandData {

public const string NS_URI = "jabber:x:oob";

public static void add_url_to_message(MessageStanza message, string url, string? desc = null) {
    message.stanza.put_node(new StanzaNode.build("x", NS_URI).add_self_xmlns().put_node(new StanzaNode.build("url", NS_URI).put_node(new StanzaNode.text(url))));
}

public static string? get_url_from_message(MessageStanza message) {
    return message.stanza.get_deep_string_content(NS_URI + ":x", NS_URI + ":url");
}

}
