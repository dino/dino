using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Dino.Ui;

namespace Dino {

    public class Rtt: StreamInteractionModule, Object {
        public static ModuleIdentity<Rtt> IDENTITY = new ModuleIdentity<Rtt>("rtt");

        private StreamInteractor stream_interactor;
        private ChatTextViewController chat_text_view_controller;

        public string id { get { return IDENTITY.id; } }

        public signal void rtt_sent(Message message, Conversation conversation);


        //private HashMap<Conversation, HashMap<Jid, Gee.List<StanzaNode>> action_elements = new HashMap<Conversation, HashMap<Jid, Gee.List<StanzaNode>>(Conversation.hash_func, Conversation.equals_func);
        private HashMap<Conversation, Gee.List<StanzaNode>> action_elements = new HashMap<Conversation, Gee.List<StanzaNode>>(Conversation.hash_func, Conversation.equals_func);

        public static void start(StreamInteractor stream_interactor) {
            Rtt m = new Rtt(stream_interactor);
            stream_interactor.add_module(m);
        }

        public Rtt(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            stream_interactor.account_added.connect(on_account_added);
            chat_text_view_controller.send_rtt.connect(message_compare);

            stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => { 
                //TODO(Wolfie) remove user's rtt from UI if present.
            });
        }

        public void send_rtt(Conversation conversation, string sequence, string event ){
    
            RttStanza rtt_stanza = new RttStanza() { seq=sequence, event=event };
            if (action_elements.has_key(conversation)){
                foreach (var action_element in action_elements[conversation]) {
                    rtt_stanza.stanza.put_node(action_element);
                }                                                       
            }
            
            Message out_message = stream_interactor.get_module(MessageProcessor.IDENTITY).create_out_message(null, conversation, rtt_stanza.stanza, true);
            stream_interactor.get_module(MessageProcessor.IDENTITY).send_xmpp_message(out_message, conversation);
            rtt_sent(out_message, conversation);

        }

        public void message_compare(string old_message, string new_message){
                
            //TODO(Wolfie)


        }


        private void on_account_added(Account account) {
            //TODO(Wolfie)
        }


    }
}