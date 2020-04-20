namespace Xmpp.Xep.MessageProcessingHints {

private const string NS_URI = "urn:xmpp:hints";

private const string HINT_NO_PERMANENT_STORE = "no-permanent-store";
private const string HINT_NO_STORE = "no-store";
private const string HINT_NO_COPY = "no-copy";
private const string HINT_STORE = "store";

public static void set_message_hint(MessageStanza message, string message_hint) {
    StanzaNode hint_node = (new StanzaNode.build(message_hint, NS_URI)).add_self_xmlns();
    message.stanza.put_node(hint_node);
}

}
