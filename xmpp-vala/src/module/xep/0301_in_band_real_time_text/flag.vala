using Gee;

namespace Xmpp.Xep.RealTimeText {

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "rtt");

        //  private HashMap<Jid, GLib.Queue<StanzaNode>> action_elements = new HashMap<Jid, GLib.Queue<StanzaNode>>(Jid.hash_bare_func, Jid.equals_bare_func);
        private GLib.Queue<StanzaNode> action_elements = new GLib.Queue<StanzaNode>();
        public string? previous_message { get; set; }

        public void set_action_element(StanzaNode ae) {
            action_elements.push_tail(ae);
        }

        public StanzaNode? get_action_element() {
            if (!action_elements.is_empty()) return action_elements.pop_head();
            else return null;
        }

        public override string get_ns() {
            return NS_URI;
        }
    
        public override string get_id() {
            return IDENTITY.id;
        }
    }
}