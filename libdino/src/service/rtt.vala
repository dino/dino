using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;

namespace Dino {

    public class RttManager: StreamInteractionModule, Object {
        public static ModuleIdentity<RttManager> IDENTITY = new ModuleIdentity<RttManager>("rtt_manager");

        private StreamInteractor stream_interactor;
        private Conversation conversation;
        public string id { get { return IDENTITY.id; } }

        public signal void rtt_sent(Message message, Conversation conversation);
        public signal void start_scheduling(Message message, Conversation conversation);

        private HashMap<Jid, string> rtt_builder = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);

        public static void start(StreamInteractor stream_interactor) {
            RttManager m = new RttManager(stream_interactor);
            stream_interactor.add_module(m);
        }

        public RttManager(StreamInteractor stream_interactor) {
            //  Timeout.add_seconds(1, schedule_rtt);                   //TODO(Wolfie) handle schedule correctly
            this.stream_interactor = stream_interactor;
            XmppStream? stream = stream_interactor.get_stream(conversation.account);
            stream_interactor.account_added.connect(on_account_added);

            //  stream.get_module(Xep.RealTimeText.Module.IDENTITY).rtt_received.connect((stream, jid) => {
            //      Timeout.add_seconds(1, () => {
            //          schedule_receiving(stream, jid);
            //          return true;
            //      });
            //  });

            stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => { 
                //TODO(Wolfie) remove user's rtt from UI if present.
            });
        }

        public void send_rtt(ArrayList<StanzaNode>? action_elements, string sequence, string? event){
            XmppStream? stream = stream_interactor.get_stream(conversation.account);

            MessageStanza message = new MessageStanza() { to=conversation.counterpart };

            if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                message.type_ = MessageStanza.TYPE_GROUPCHAT;
            } else {
                message.type_ = MessageStanza.TYPE_CHAT;
            }

            RttStanzaNode rtt_node = new RttStanzaNode() { seq=sequence, event=event };
           
            debug("%d", action_elements.size);
            foreach (var action_element in action_elements) {
                rtt_node.stanza_node.put_node(action_element);
            }
            
            message.stanza.put_node(rtt_node.stanza_node);
            stream.get_module(MessageModule.IDENTITY).send_message.begin(stream, message);

            stream.get_module(Xep.RealTimeText.Module.IDENTITY).event = "edit";

        }

        public void message_compare(Conversation conversation, string old_message, string? new_message) {
            this.conversation = conversation;
            MessageComparison message_comparison = new MessageComparison(old_message, new_message);
            ArrayList<Tag> tags = message_comparison.generate_tags();
            
            foreach (Tag tag in tags) {
                debug("%s : %d : %d : %d: %d\n\n", tag.tag, tag.a0, tag.a1, tag.b0, tag.b1);
            }

            foreach (Tag tag in tags) {
                if (tag.tag == "insert") {
                    XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    if (stream != null) stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_t_element(stream, new_message[tag.b0:tag.b1], tag.a0.to_string());               
                }
                else if (tag.tag == "erase") {
                    XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    if (stream != null) stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_e_element(stream, tag.a1.to_string(), (tag.a1 - tag.a0).to_string());
                }
                else if (tag.tag == "replace") {
                    XmppStream? stream = stream_interactor.get_stream(conversation.account);
                    if (stream != null) {
                        stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_e_element(stream, tag.a1.to_string(), (tag.a1 - tag.a0).to_string());
                        stream.get_module(Xep.RealTimeText.Module.IDENTITY).generate_t_element(stream, new_message[tag.b0:tag.b1], tag.a0.to_string());     
                    }
                }
            }
        }

        public bool schedule_rtt() {
            //TODO(Wolfie) correct error handling
            try {
                XmppStream? stream = stream_interactor.get_stream(conversation.account);
                ArrayList<StanzaNode> action_elements = stream.get_module(Xep.RealTimeText.Module.IDENTITY).get_all_action_elements(stream);
                if (!action_elements.is_empty) {
                    string event = stream.get_module(Xep.RealTimeText.Module.IDENTITY).event;
                    int seq = stream.get_module(Xep.RealTimeText.Module.IDENTITY).seq;
                    send_rtt(action_elements, seq.to_string(), event);
                    return true;
                }
                return false;
            } catch (Error e) {
                warning("invalid stream (%s)", e.message);
                return true;
            }
        }

        private void on_account_added(Account account) {
            //TODO(Wolfie)
        }

    }
}