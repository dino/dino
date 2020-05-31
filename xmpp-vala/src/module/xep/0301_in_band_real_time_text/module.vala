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

        //  public HashMap<Conversation, Gee.List<StanzaNode>> sub_nodes = new HashMap<Conversation, Gee.List<StanzaNode>>(Conversation.hash_func, Conversation.equals_func);

        public const string INSERT_TEXT = "t";
        public const string ERASE_TEXT = "e";
        public const string WAIT = "w";

        public const string POSITION = "p";
        public const string LENGTH = "n";
        public const string WAIT_INTERVAL = "n";

        public const string  NEW  = "new";
        public const string  RESET  = "reset";
        public const string  EDIT = "edit";
        public const string  INIT = "init";
        public const string  CANCEL  = "cancel";

        public string event{ get; set; default=NEW; }
        public string seq = random_seq();


        public override void attach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        }
    
        public override void detach(XmppStream stream) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }
    
        public override string get_ns() { return NS_URI; }
    
        public override string get_id() { return IDENTITY.id; }

        public void generate_t_element(string text, string? position) {
           StanzaNode insert_text = new StanzaNode.build(INSERT_TEXT);
           if (position != null) {
               insert_text.put_attribute(POSITION, position, NS_URI);
           }
           insert_text.put_node(new StanzaNode.text(text));
        }

        public void generate_e_element(string? position, string? length) {
            StanzaNode erase_text = new StanzaNode.build(ERASE_TEXT);
            if (position != null) {
                erase_text.put_attribute(POSITION, position, NS_URI);
            }
            if (length != null) {
                erase_text.put_attribute(LENGTH, length, NS_URI);
            }
        
        }
    }
         


    
}