using Gee;
using Xmpp.Core;

namespace Xmpp.Xep.StatelessInlineMediaSharing {

public const string NS_URI = "urn:xmpp:sims:1";
public const string NS_URI_REFERENCE = "urn:xmpp:reference:0";

public static void add_sims_to_message(Message.Stanza message, int begin, int end, Gee.List<string> uris, string? name, string? media_type, int? size) {
    // TODO: Put that in a references namespace.
    StanzaNode reference = new StanzaNode.build("reference", NS_URI_REFERENCE).add_self_xmlns();
    reference.set_attribute("begin", begin.to_string());
    reference.set_attribute("end", end.to_string());
    reference.set_attribute("type", "data");

    StanzaNode media_sharing = new StanzaNode.build("media-sharing", NS_URI).add_self_xmlns();

    StanzaNode jingle_ft = Xep.JingleFileTransfer.generate_file_element(name, media_type, size);
    media_sharing.put_node(jingle_ft);

    StanzaNode sources = new StanzaNode.build("sources", NS_URI);
    foreach (string uri in uris) {
        StanzaNode source = new StanzaNode.build("reference", NS_URI);
        source.set_attribute("type", "data");
        source.set_attribute("uri", uri);
        sources.put_node(source);
    }
    media_sharing.put_node(sources);

    reference.put_node(media_sharing);
    message.stanza.put_node(reference);
}

// TODO: add receiving.

}
