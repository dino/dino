using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

namespace Dino {

    public class RttManager: StreamInteractionModule, Object {
        public static ModuleIdentity<RttManager> IDENTITY = new ModuleIdentity<RttManager>("rtt_manager");

        private StreamInteractor stream_interactor;
        Account account;
        private Conversation conversation;
        public string id { get { return IDENTITY.id; } }

        public signal void start_scheduling(Message message, Conversation conversation);
  
        private HashMap<Conversation, Gee.Queue<StanzaNode>> action_elements_sent = new  HashMap<Conversation, Gee.ArrayQueue<StanzaNode>>(Conversation.hash_func, Conversation.equals_func);
        private HashMap<Conversation, int> seq = new  HashMap<Conversation, int>(Conversation.hash_func, Conversation.equals_func);
        private HashMap<Conversation, string> event = new  HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);
        public HashMap<Conversation, string>? previous_message =  new  HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);

        private HashMap<Conversation, HashMap<Jid, Gee.Queue<StanzaNode>>> received_action_elements = new HashMap<Conversation, HashMap<Jid, Gee.ArrayQueue<StanzaNode>>>(Conversation.hash_func, Conversation.equals_func);
        private HashMap<Conversation, HashMap<Jid, string>> rtt_builder = new HashMap<Conversation, HashMap<Jid, string>>(Conversation.hash_func, Conversation.equals_func);

        public static void start(StreamInteractor stream_interactor) {
            RttManager m = new RttManager(stream_interactor);
            stream_interactor.add_module(m);
        }

        public RttManager(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;
            stream_interactor.account_added.connect(on_account_added);
            stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => { 
                //TODO(Wolfie) remove user's rtt from UI if present.
            });
        }

        public void message_compare(Conversation conversation, string old_message, string? new_message) {
            this.conversation = conversation;
            MessageComparison message_comparison = new MessageComparison(old_message, new_message);
            ArrayList<Tag> tags = message_comparison.generate_tags();

            foreach (Tag tag in tags) {
                if (tag.tag == "insert") {
                    XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    if (stream != null) {
                        StanzaNode insert_text = stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_t_element(stream, new_message[tag.b0:tag.b1], tag.a0.to_string());
                        set_action_element(conversation, insert_text);  
                    }             
                }
                else if (tag.tag == "erase") {
                    XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    if (stream != null) {
                        StanzaNode erase_text = stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_e_element(stream, tag.a1.to_string(), (tag.a1 - tag.a0).to_string());
                        set_action_element(conversation, erase_text);
                    }
                }
                else if (tag.tag == "replace") {
                    XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    if (stream != null) {
                        StanzaNode erase_text = stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_e_element(stream, tag.a1.to_string(), (tag.a1 - tag.a0).to_string());
                        set_action_element(conversation, erase_text);  

                        StanzaNode insert_text = stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_t_element(stream, new_message[tag.b0:tag.b1], tag.a0.to_string());
                        set_action_element(conversation, insert_text);    
                    }
                }
            }
        }

        private void set_action_element(Conversation conversation, StanzaNode ae) {
            if (action_elements_sent.has_key(conversation)) {
                action_elements_sent[conversation].offer(ae);
            } else {
                action_elements_sent[conversation] = new Gee.ArrayQueue<StanzaNode>();
                action_elements_sent[conversation].offer(ae);
            }
        }

        public ArrayList<StanzaNode> get_action_elements(Conversation conversation) {
            ArrayList<StanzaNode> action_elements = new ArrayList<StanzaNode>();

            if (action_elements_sent.has_key(conversation)) {
                while (!action_elements_sent[conversation].is_empty) {
                    StanzaNode ae = action_elements_sent[conversation].poll();
                    action_elements.add(ae);
                }
            }
            return action_elements;
        }

        public void save_previous_message(Conversation conversation, string message) {
            previous_message[conversation] = message;
        }

        public string get_previous_message(Conversation conversation) {
            if (previous_message.has_key(conversation)) return previous_message[conversation];
            return "";
        }

        public void set_event(Conversation conversation, string event_) {
            event[conversation] = event_;
        }

        public async void set_received_action_element(Account account, Jid jid, MessageStanza stanza, Gee.List<StanzaNode> action_elements) {
            Message message = yield stream_interactor.get_module(MessageProcessor.IDENTITY).parse_message_stanza(account, stanza);
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
            if (conversation == null) return;

            if (received_action_elements.has_key(conversation)){
                if (received_action_elements[conversation].has_key(jid)) {
                    foreach(StanzaNode ae in action_elements) {
                        received_action_elements[conversation][jid].offer(ae);
                    }
                } else {
                    received_action_elements[conversation][jid] = new Gee.ArrayQueue<StanzaNode>();
                    foreach(StanzaNode ae in action_elements) {
                        received_action_elements[conversation][jid].offer(ae);
                    }
                }
            } else {
                received_action_elements[conversation] = new HashMap<Jid, Gee.Queue<StanzaNode>>(Jid.hash_func, Jid.equals_func);
                received_action_elements[conversation][jid] = new Gee.ArrayQueue<StanzaNode>();
                foreach(StanzaNode ae in action_elements) {
                    received_action_elements[conversation][jid].offer(ae);
                }
            }
        }

        public StanzaNode? get_received_action_element(Conversation conversation, Jid jid) {
            if (received_action_elements.has_key(conversation) && received_action_elements[conversation].has_key(jid)){
                if (!received_action_elements[conversation][jid].is_empty) return received_action_elements[conversation][jid].poll();
                else return null;
            }
            return null;
        }

        public async void unset_rtt_builder(Account account, Jid jid, MessageStanza stanza, string event_) {
            Message message = yield stream_interactor.get_module(MessageProcessor.IDENTITY).parse_message_stanza(account, stanza);
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
            if (conversation == null) return;

            if (rtt_builder.has_key(conversation) && rtt_builder[conversation].has_key(jid) && event_ == RealTimeText.Module.EVENT_NEW) {
                rtt_builder[conversation].unset(jid);
            }
        }

        public bool schedule_rtt(Conversation conversation) {
            XmppStream? stream = stream_interactor.get_stream(conversation.account);
            ArrayList<StanzaNode> action_elements = get_action_elements(conversation);

            if (!action_elements.is_empty) {

                if (!event.has_key(conversation)) event[conversation] = RealTimeText.Module.EVENT_NEW;
                if (!seq.has_key(conversation)) seq[conversation] = random_seq();

                int sequence = seq[conversation];

                if (event[conversation] == RealTimeText.Module.EVENT_NEW) {
                    sequence = random_seq();
                    seq[conversation] = sequence;
                } else {
                    sequence = seq[conversation] + 1;
                    seq[conversation] = seq[conversation] + 1;
                }

                string message_type = conversation.type_ == Conversation.Type.GROUPCHAT ? MessageStanza.TYPE_GROUPCHAT : MessageStanza.TYPE_CHAT;
                stream.get_module(RealTimeText.Module.IDENTITY).send_rtt(stream, conversation.counterpart, message_type, action_elements, sequence.to_string(), event[conversation]);
                set_event(conversation, RealTimeText.Module.EVENT_EDIT);
                return true;
            }
            return false;
        }

        public bool schedule_receiving(Account account, Jid jid) {

            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid.bare_jid, account);
            if (conversation==null) return false;

            StanzaNode action_element = get_received_action_element(conversation, jid);
            StringBuilder rtt_message;

            if (action_element != null) {
                if (rtt_builder.has_key(conversation) && rtt_builder[conversation].has_key(jid)) {
                    rtt_message = new StringBuilder(rtt_builder[conversation][jid]);
                } else {
                    rtt_message = new StringBuilder();
                }
                
                if (action_element.name == RealTimeText.Module.ACTION_ELEMENT_INSERT) {
                    int? position = int.parse(action_element.get_attribute(RealTimeText.Module.ATTRIBUTE_POSITION, RealTimeText.NS_URI));
                    if (position == null || position > (int)rtt_message.len) position = (int)rtt_message.len;

                    string? new_text = action_element.get_string_content();
                    if (new_text == null) new_text = " ";
                   
                    rtt_message.insert(position, new_text);
                }

                else if (action_element.name == RealTimeText.Module.ACTION_ELEMENT_ERASE) {
                    int? position = int.parse(action_element.get_attribute(RealTimeText.Module.ATTRIBUTE_POSITION, RealTimeText.NS_URI));
                    if (position == null || position > (int)rtt_message.len) position = (int)rtt_message.len;

                    int? length = int.parse(action_element.get_attribute(RealTimeText.Module.ATTRIBUTE_LENGTH, RealTimeText.NS_URI));
                    if (length == null || length>(int)rtt_message.len) length = 1;
                    
                    rtt_message.erase(position-length+1, length);
                }

                if (rtt_builder.has_key(conversation) && rtt_builder[conversation].has_key(jid)) {
                    rtt_builder[conversation][jid] = rtt_message.str;
                } else {
                    rtt_builder[conversation] = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
                    rtt_builder[conversation][jid] = rtt_message.str;
                }

                debug("%s", rtt_message.str);
                //TODO(Wolfie) display on UI

                return true;
            }
            return false;
        }

        private void on_account_added(Account account) {
            this.account = account;
            stream_interactor.module_manager.get_module(account, Xep.RealTimeText.Module.IDENTITY).rtt_received.connect((jid, stanza, action_elements) => {
                set_received_action_element.begin(account, jid, stanza, action_elements);

                Timeout.add(1, () => {
                    schedule_receiving(account, jid);
                    return true;
                });
            });

            stream_interactor.module_manager.get_module(account, Xep.RealTimeText.Module.IDENTITY).event_received.connect((jid, stanza, event) => {
                unset_rtt_builder.begin(account, jid, stanza, event);
            });
        }
    }
}