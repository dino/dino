using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

    class RealTimeTextPopulator : Plugins.ConversationItemPopulator, Plugins.ConversationAdditionPopulator, Object {

        public string id { get { return "real_time_text"; } }

        private StreamInteractor? stream_interactor;
        private Conversation? current_conversation;
        private Plugins.ConversationItemCollection? item_collection;

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

           
        }

        public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
            current_conversation = conversation;
            this.item_collection = item_collection;
            this.meta_items = new HashMap<Jid, MetaRttItem>(Jid.hash_func, Jid.equals_func);
            init_rtt();
        }

        public void close(Conversation conversation) { }

        public void populate_timespan(Conversation conversation, DateTime from, DateTime to) { }

        private void init_rtt() {
           HashMap<Jid, string>? active_rtt = stream_interactor.get_module(RttManager.IDENTITY).get_active_rtt(current_conversation);
           if (active_rtt == null) return;

           foreach(Jid jid in active_rtt.keys) {
                meta_items[jid] = new MetaRttItem(stream_interactor, current_conversation, jid, active_rtt[jid]);
                item_collection.insert_item(meta_items[jid]);
            }
        }

        private void update_rtt(Jid jid, string rtt_message) {
            if (!meta_items.has_key(jid)) {
                meta_items[jid] = new MetaRttItem(stream_interactor, current_conversation, jid, rtt_message);
                item_collection.insert_item(meta_items[jid]);
            } else if (meta_items.has_key(jid) && rtt_message != "") {
                meta_items[jid].set_new(rtt_message);
            } 
            
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
        public Jid jid;
        public string rtt_message;
        private Label label;
        private Label name_label;
        private AvatarImage image;

        public MetaRttItem(StreamInteractor stream_interactor, Conversation conversation, Jid jid, string rtt_message) {
            this.stream_interactor = stream_interactor;
            this.conversation = conversation;
            this.jid = jid;
            this.rtt_message = rtt_message;
        }

        public override Object? get_widget(Plugins.WidgetType widget_type) {
            label = new Label("") { xalign=0, vexpand=true, visible=true, wrap=true };
            label.get_style_context().add_class("dim-label");

            name_label = new Label("") { xalign=0, vexpand=true, visible=true, use_markup=true };
            
            image = new AvatarImage() { margin_top=2, valign=Align.START, visible=true };

            Box image_content_box = new Box(Orientation.HORIZONTAL, 8) { visible=true };
            Box content_box = new Box(Orientation.VERTICAL, 0) { visible=true };

            content_box.add(name_label);
            content_box.add(label);
            image_content_box.add(image);
            image_content_box.add(content_box);

            update();
            return image_content_box;
        }

        public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }

        public void set_new(string rtt_message) {
            this.rtt_message = rtt_message;
            update();
        }

        private void update() {
            if (image == null || label == null) return;

            image.set_conversation_participant(stream_interactor, conversation, jid);

            string display_name = Markup.escape_text(Util.get_participant_display_name(stream_interactor, conversation, jid));
            string color = Util.get_name_hex_color(stream_interactor, conversation.account, jid, Util.is_dark_theme(name_label));
            name_label.label = @"<span foreground=\"#$color\">$display_name</span>";

            string new_text = "";

            new_text = rtt_message;

            label.label = new_text;
        }
    }
} 