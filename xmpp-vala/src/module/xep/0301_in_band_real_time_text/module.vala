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

        private HashMap<Jid, string> rtt_builder = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);


        public string event { get; set; default=EVENT_NEW; }
        public int sequence;
        bool ignore = false;
        public int previous_sequence { get; set; }
        public int seq { 
            get {
                if (event == EVENT_NEW) {
                    sequence = random_seq();
                    return sequence;
                }
                return ++sequence;
            }
        }

        public signal void rtt_received(XmppStream stream, Jid jid);

        public override void attach(XmppStream stream) {
            stream.add_flag(new Flag());
            stream.get_module(MessageModule.IDENTITY).received_message.connect(on_received_message);
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            
            rtt_received.connect((stream, jid) => {
                Timeout.add(1, () => {
                    schedule_receiving(stream, jid);
                    return true;
                });
            });

        }
    
        public override void detach(XmppStream stream) {
            stream.get_module(MessageModule.IDENTITY).received_message.disconnect(on_received_message);
            stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        }
    
        public override string get_ns() { return NS_URI; }
    
        public override string get_id() { return IDENTITY.id; }

        public void generate_t_element(XmppStream stream, string text, string? position) {
           StanzaNode insert_text = new StanzaNode.build(INSERT_TEXT, NS_URI);
           if (position != null) {
               insert_text.put_attribute(POSITION, position, NS_URI);
           }
           insert_text.put_node(new StanzaNode.text(text));

           Flag flag = stream.get_flag(Flag.IDENTITY);
           if (flag != null) flag.set_action_element(insert_text);
        }

        public void generate_e_element(XmppStream stream, string? position, string? length) {
            StanzaNode erase_text = new StanzaNode.build(ERASE_TEXT, NS_URI);
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

        public StanzaNode? get_received_action_element(XmppStream stream, Jid jid) {
            Flag flag = stream.get_flag(Flag.IDENTITY);
            if (flag != null) {
                StanzaNode? ae = flag.get_received_action_element(jid);
                if (ae!=null) return ae;
            } 
            return null;
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

        private void on_received_message(XmppStream stream, MessageStanza message) {
            Jid? from_jid = message.from;

            StanzaNode? rtt_stanza_node = message.stanza.get_subnode("rtt", NS_URI);
            
            if (rtt_stanza_node != null) {
                // event resolution
                string? event = rtt_stanza_node.get_attribute("event", NS_URI);
                Event parsed_event;
                switch (event) {
                    case "new": parsed_event = Event.NEW; break;
                    case "reset": parsed_event = Event.RESET; break;
                    case "edit": parsed_event = Event.EDIT; break;
                    case "init": parsed_event = Event.INIT; break;
                    case "cancel": parsed_event = Event.CANCEL; break;
                    default: parsed_event = Event.EDIT; break;
                }
                
                if (parsed_event == Event.NEW) {
                    ignore = false;
                    if (rtt_builder.has_key(from_jid)) rtt_builder.unset(from_jid);
                    //TODO(Wolfie) set up rtt viewer on UI
                }

                if (!ignore){
                    // sequence resolution
                    int received_sequence = int.parse(rtt_stanza_node.get_attribute("seq", NS_URI));
                    bool is_sequence = true;
                    if (parsed_event==Event.EDIT &&  received_sequence != previous_sequence+1) is_sequence = false;
                    previous_sequence = received_sequence;
                
                    //get action element subnodes
                    Flag flag = stream.get_flag(Flag.IDENTITY);
                    if (is_sequence){
                        foreach (StanzaNode action_element in rtt_stanza_node.get_all_subnodes()){
                            if (flag != null) flag.set_action_element_received(from_jid, action_element);
                        };
                    } else {
                        ignore = true;
                        //TODO(Wolfie) handle loss of sync  https://xmpp.org/extensions/xep-0301.html#recovery_from_loss_of_sync
                    }
                    rtt_received(stream, from_jid);
                }
            }
        }


        public bool schedule_receiving(XmppStream stream, Jid jid) {
            StanzaNode action_element = stream.get_module(Xep.RealTimeText.Module.IDENTITY).get_received_action_element(stream, jid);
            StringBuilder rtt_message;

            if (action_element != null) {
                if (rtt_builder.has_key(jid)) {
                    rtt_message = new StringBuilder(rtt_builder[jid]);
                } else {
                    rtt_message = new StringBuilder();
                }
                
                if (action_element.name == "t") {
                    int? position = int.parse(action_element.get_attribute("p", "urn:xmpp:rtt:0"));
                    if (position == null || position > (int)rtt_message.len) position = (int)rtt_message.len;

                    string? new_text = action_element.get_string_content();
                    if (new_text == null) new_text = " ";
                   
                    rtt_message.insert(position, new_text);
                }

                else if (action_element.name == "e") {
                    int? position = int.parse(action_element.get_attribute("p", "urn:xmpp:rtt:0"));
                    if (position == null || position > (int)rtt_message.len) position = (int)rtt_message.len;

                    int? length = int.parse(action_element.get_attribute("n","urn:xmpp:rtt:0"));
                    if (length == null || length>(int)rtt_message.len) length = 1;
                    
                    rtt_message.erase(position-length+1, length);
                    rtt_builder[jid] = rtt_message.str;
                    debug("%s", rtt_message.str);
                }

                rtt_builder[jid] = rtt_message.str;
                debug("%s", rtt_message.str);
                //TODO(Wolfie) display on UI

                return true;
            }
            return false;
        }

    } 
}