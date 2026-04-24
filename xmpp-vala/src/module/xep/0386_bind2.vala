using Gee;

namespace Xmpp.Xep.Bind2 {
    public const string NS_URI = "urn:xmpp:bind:0";

    public class Sasl2Activation : ExtensibleSaslProfile.Sasl2InlineActivation {
        public HashMap<string, Bind2InlineActivation> inline_activation_providers = new HashMap<string, Bind2InlineActivation>();

        public override StanzaNode? get_activation_node(XmppStream stream, StanzaNode inline_node) {
            var res = new StanzaNode.build("bind", Bind2.NS_URI).add_self_xmlns().put_node(
                    new StanzaNode.build("tag", Bind2.NS_URI).put_node(new StanzaNode.text("dino")));

            StanzaNode bind_inline_node = inline_node.get_subnode("bind", NS_URI).get_subnode("inline", NS_URI);

            if (bind_inline_node != null) {
                foreach (StanzaNode inline_feature in bind_inline_node.get_subnodes("feature", NS_URI)) {
                    var inline_feature_ns = inline_feature.get_attribute("var");
                    if (inline_activation_providers.has_key(inline_feature_ns)) {
                        var activation_node = inline_activation_providers[inline_feature_ns].get_activation_node(stream);
                        if (activation_node != null) {
                            res.put_node(activation_node);
                        }
                    }
                }
            }
            return res;
        }

        public override void on_bound(XmppStream stream, Jid authorization_identifier, StanzaNode success_node) {
            Bind.Flag bind_flag = new Bind.Flag();
            bind_flag.my_jid = authorization_identifier;
            bind_flag.finished = true;
            stream.add_flag(bind_flag);
            stream.get_module(Bind.Module.IDENTITY).bound_to_resource(stream, bind_flag.my_jid);

            StanzaNode? bound_node = success_node.get_subnode("bound", Bind2.NS_URI);
            if (bound_node != null) {
                foreach (var inline_activation in inline_activation_providers.values) {
                    inline_activation.on_bound(stream, bound_node);
                }
            }
        }
    }

    public abstract class Bind2InlineActivation : Object {
        public abstract StanzaNode? get_activation_node(XmppStream stream);
        public abstract void on_bound(XmppStream stream, StanzaNode bound_node);
    }
}