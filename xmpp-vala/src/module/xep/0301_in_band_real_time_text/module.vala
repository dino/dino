using Gee;

using Xmpp;
using Xmpp.Xep;
//  using Dino.Entities;

namespace Xmpp.Xep.RealTimeText {
   
    private const string NS_URI = "urn:xmpp:rtt:0";

    public enum Event {
        NEW,
        RESET,
        EDIT,
        INIT,
        CANCEL
    }

    public enum ActionElement {
        INSERT_TEXT,
        ERASE_TEXT,
        WAIT
    }

    public enum ActionElementAttribute {
        POSITION,
        LENGTH,
        WAIT_INTERVAL
    }

    public class Module : XmppStreamModule {
        public static ModuleIdentity<Module> IDENTITY = new ModuleIdentity<Module>(NS_URI, "0301_in_band_real_time_text");

        public const string INSERT_TEXT = "t";
        public const string ERASE_TEXT = "e";
        public const string WAIT = "w";

        public const string POSITION = "p";
        public const string LENGTH = "n";
        public const string WAIT_INTERVAL = "n";

        public const string  EVENT_NEW  = "new";
        public const string  EVENT_RESET  = "reset";
        public const string  EVENT_EDIT = "edit";
        public const string  EVENT_INIT = "init";
        public const string  EVENT_CANCEL  = "cancel";

        public string event { get; set; default=EVENT_NEW; }
        public int seq { 
            get {
                if (event == EVENT_NEW) return random_seq();
                else return seq+1;
            }
        }

        public override void attach(XmppStream stream) {
            stream.add_flag(new Flag());
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }
    
        public override void detach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }
    
        public override string get_ns() { return NS_URI; }
    
        public override string get_id() { return IDENTITY.id; }

        public void generate_t_element(XmppStream stream, string text, string? position) {
           StanzaNode insert_text = new StanzaNode.build(INSERT_TEXT);
           if (position != null) {
               insert_text.put_attribute(POSITION, position, NS_URI);
           }
           insert_text.put_node(new StanzaNode.text(text));

           Flag flag = stream.get_flag(Flag.IDENTITY);
           if (flag != null) flag.set_action_element(insert_text);
        }

        public void generate_e_element(XmppStream stream, string? position, string? length) {
            StanzaNode erase_text = new StanzaNode.build(ERASE_TEXT);
            if (position != null) {
                erase_text.put_attribute(POSITION, position, NS_URI);
            }
            if (length != null) {
                erase_text.put_attribute(LENGTH, length, NS_URI);
            }
            Flag flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) flag.set_action_element(erase_text);
        }

        public ArrayList<StanzaNode> get_all_action_elements(XmppStream stream) {
            ArrayList<StanzaNode> action_elements = new ArrayList<StanzaNode>();

            Flag flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) {
                while (true) {
                    StanzaNode? ae = flag.get_action_element();
                    if (ae!=null) action_elements.add(ae);
                    else break;
                }    
            } 
            return action_elements;
        }

        public void save_previous_message(XmppStream stream, string message) {
            Flag flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) flag.previous_message = message;
        }

        public string get_previous_message(XmppStream stream) {
            Flag flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) {
                string? previous_message = flag.previous_message;
                if (previous_message != null) return previous_message;
                return "";
            }
            return "";
        }
    }
         


    
}