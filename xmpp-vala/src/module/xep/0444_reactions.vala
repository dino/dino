using Gee;

namespace Xmpp.Xep.Reactions {

public const string NS_URI = "urn:xmpp:reactions:0";

public class Module : XmppStreamModule {
    public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "reactions");

    public signal void received_reactions(XmppStream stream, Jid from_jid, string message_id, Gee.List<string> reactions, MessageStanza stanza);

    private ReceivedPipelineListener received_pipeline_listener = new ReceivedPipelineListener();

    public void send_reaction(XmppStream stream, Jid jid, string stanza_type, string message_id, Gee.List<string> reactions) {
        StanzaNode reactions_node = new StanzaNode.build("reactions", NS_URI).add_self_xmlns();
        reactions_node.put_attribute("id", message_id);
        foreach (string reaction in reactions) {
            StanzaNode reaction_node = new StanzaNode.build("reaction", NS_URI);
            reaction_node.put_node(new StanzaNode.text(reaction));
            reactions_node.put_node(reaction_node);
        }

        MessageStanza message = new MessageStanza() { to=jid, type_=stanza_type };
        message.stanza.put_node(reactions_node);

        MessageProcessingHints.set_message_hint(message, MessageProcessingHints.HINT_STORE);

        stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);
    }

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).received_pipeline.connect(received_pipeline_listener);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        stream.get_module(MessageModule.IDENTITY).received_pipeline.disconnect(received_pipeline_listener);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class ReceivedPipelineListener : StanzaListener<MessageStanza> {

    private const string[] after_actions_const = {"EXTRACT_MESSAGE_2"};

    public override string action_group { get { return ""; } }
    public override string[] after_actions { get { return after_actions_const; } }

    public override async bool run(XmppStream stream, MessageStanza message) {
        StanzaNode? reactions_node = message.stanza.get_subnode("reactions", NS_URI);
        if (reactions_node == null) return false;

        string? id_attribute = reactions_node.get_attribute("id");
        if (id_attribute == null) return false;

        Gee.List<string> reactions = new ArrayList<string>();
        foreach (StanzaNode reaction_node in reactions_node.get_subnodes("reaction", NS_URI)) {
            string? reaction = reaction_node.get_string_content();
            if (reaction == null) return false;

            if (!reactions.contains(reaction)) {
                reactions.add(reaction);
            }
        }
        stream.get_module(Module.IDENTITY).received_reactions(stream, message.from, id_attribute, reactions, message);

        return false;
    }
}

}
