using Gee;
using Xmpp;

namespace Xmpp.Xep.RealTimeText {

    public class Flag : XmppStreamFlag {
        public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "rtt");

        private HashMap<Jid, Gee.Queue<StanzaNode>> received_action_elements = new HashMap<Jid, Gee.ArrayQueue<StanzaNode>>(Jid.hash_func, Jid.equals_func);
        private GLib.Queue<StanzaNode> action_elements = new GLib.Queue<StanzaNode>();
        public string? previous_message { get; set; }

        // for sending queue

        public void set_action_element(StanzaNode ae) {
            action_elements.push_tail(ae);
        }

        public StanzaNode? get_action_element() {
            if (!action_elements.is_empty()) return action_elements.pop_head();
            else return null;
        }

        // for receiving queue

        public void set_action_element_received(Jid jid, StanzaNode ae){
            if (received_action_elements.has_key(jid)){
                received_action_elements[jid].offer(ae);
            } else {
                received_action_elements[jid] = new Gee.ArrayQueue<StanzaNode>();
                received_action_elements[jid].offer(ae);
            }
        }

        public StanzaNode? get_received_action_element(Jid jid) {
            if (received_action_elements.has_key(jid)){
                if (!received_action_elements[jid].is_empty) return received_action_elements[jid].poll();
                else return null;
            }
            return null;
        }

        public override string get_ns() {
            return NS_URI;
        }
    
        public override string get_id() {
            return IDENTITY.id;
        }
    }
}