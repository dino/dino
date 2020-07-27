using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

    class RealTimeTextPopulator : Plugins.ConversationItemPopulator, Plugins.ConversationAdditionPopulator, Object {

        public string id { get { return "real_time_text"; } }

        private StreamInteractor? stream_interactor;
        public Conversation? current_conversation;
        private ChatInputController chat_input_controller;
        private Plugins.ConversationItemCollection? item_collection;
        private Timer stale_timer;
        private ulong microseconds;
	    private double seconds;

        private HashMap<Jid, MetaRttItem> meta_items;

        public RealTimeTextPopulator(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            stream_interactor.get_module(RttManager.IDENTITY).rtt_processed.connect((conversation, jid, rtt_message) => {
                if (current_conversation != null && current_conversation.equals(conversation)) {
                    update_rtt(jid, rtt_message);
                }
            });

            stream_interactor.get_module(RttManager.IDENTITY).event_received.connect((conversation, jid, event) => {
                if (current_conversation != null && current_conversation.equals(conversation) && event == Xep.RealTimeText.Module.EVENT_NEW) {
                    delete_rtt(jid);
                }
            });

            stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect((message, conversation) => {
                if (current_conversation != null && conversation.equals(current_conversation)) {
                    delete_rtt(message.from);
                }
            });

            stream_interactor.get_module(PresenceManager.IDENTITY).received_offline_presence.connect((jid, account) => { 
                delete_rtt(jid);
            });

            stream_interactor.get_module(RttManager.IDENTITY).rtt_setting_changed.connect((conversation) => {
                if (conversation.rtt_setting == Conversation.RttSetting.OFF) {
                    foreach(Jid jid in meta_items.keys) {
                        item_collection.remove_item(meta_items[jid]);
                    }
                    meta_items = new HashMap<Jid, MetaRttItem>(Jid.hash_func, Jid.equals_func); 
                }
            });
        }

        public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
            current_conversation = conversation;
            this.item_collection = item_collection;
            this.meta_items = new HashMap<Jid, MetaRttItem>(Jid.hash_func, Jid.equals_func);
            init_rtt();
        }

        public void close(Conversation conversation) { }

        public void populate_timespan(Conversation conversation, DateTime from, DateTime to) { }

        public void generate_new(Conversation conversation, Jid jid, string rtt_message) {
            meta_items[jid] = new MetaRttItem(stream_interactor, current_conversation, jid, rtt_message);
            item_collection.insert_item(meta_items[jid]);
            stale_timer = new Timer();
            
            Timeout.add_seconds(5, () => {
                if (current_conversation == null || current_conversation != conversation || !meta_items.has_key(jid)) return false;
                debug(current_conversation.counterpart.to_string());

                seconds = stale_timer.elapsed (out microseconds);
                bool is_stale = seconds > 5.0 ? true : false;
                if (is_stale) {
                    delete_rtt(jid);
                    return false;
                }
                return true;
            });
        }

        private void init_rtt() {
           HashMap<Jid, string>? active_rtt = stream_interactor.get_module(RttManager.IDENTITY).get_active_rtt(current_conversation);
           if (active_rtt == null) return;

           foreach(Jid jid in active_rtt.keys) {
                if (active_rtt[jid] != "") { 
                    generate_new(current_conversation, jid, active_rtt[jid]);
                }
            }
        }

        private void update_rtt(Jid jid, string rtt_message) {
            if (!meta_items.has_key(jid)) {
                generate_new(current_conversation, jid, rtt_message);  
            } else if (meta_items.has_key(jid) && rtt_message != "") {
                meta_items[jid].set_new(rtt_message);
            }
            
            stale_timer.reset();
            
            if (meta_items.has_key(jid) && rtt_message.char_count() == 0) {
                delete_rtt(jid);
            } 
        }

        private void delete_rtt(Jid jid){
            if (meta_items.has_key(jid)) {
                item_collection.remove_item(meta_items[jid]);
                meta_items.unset(jid);
            }
        }
    }

    private class MetaRttItem : Plugins.MetaConversationItem {
        public override DateTime sort_time { get; set; default=new DateTime.now_utc().add_years(10); }

        private StreamInteractor stream_interactor;
        private Conversation conversation;
        public string rtt_message;
        private Label label;

        public MetaRttItem(StreamInteractor stream_interactor, Conversation conversation, Jid jid, string rtt_message) {
            this.stream_interactor = stream_interactor;
            this.conversation = conversation;
            this.jid = jid;
            this.rtt_message = rtt_message;
            
            this.can_merge = true;
            this.requires_avatar = true;
            this.requires_header = true;
        }

        public override Object? get_widget(Plugins.WidgetType widget_type) {
            label = new Label("") { xalign=0, vexpand=true, visible=true, wrap=true };
            update();
            return label;
        }

        public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }

        public void set_new(string rtt_message) {
            this.rtt_message = rtt_message;
            update();
        }

        private void update() {
            string new_text = "";
            new_text = rtt_message;
            label.label = new_text;
        }
    }
} 