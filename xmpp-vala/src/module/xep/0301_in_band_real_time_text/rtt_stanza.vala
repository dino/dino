namespace Xmpp {

    public class RttStanza : Object {
    
        public const string ATTRIBUTE_SEQUENCE = "seq";
        public const string ATTRIBUTE_ID = "id";
        public const string ATTRIBUTE_EVENT = "event";
    
        public string seq {
            get {
                return stanza.get_attribute(ATTRIBUTE_SEQUENCE);
            }
            set { stanza.set_attribute(ATTRIBUTE_SEQUENCE, value); }
        }

        //TODO(Wolfie) look into id attribute (to work in conjection with message correction)
    
        //  public virtual string? id {
        //      get { return stanza.get_attribute(ATTRIBUTE_ID); }
        //      set { stanza.set_attribute(ATTRIBUTE_ID, value); }
        //  }
    
        public virtual string event {
            get {
                return stanza.get_attribute(ATTRIBUTE_EVENT);
            }
            set { stanza.set_attribute(ATTRIBUTE_EVENT, value); }
        }
    
        public StanzaNode stanza;
    
        public RttStanza() {
            this.stanza = new StanzaNode.build("rtt", Xep.RealTimeText.NS_URI).add_self_xmlns();
        }
        
    }
    
    }