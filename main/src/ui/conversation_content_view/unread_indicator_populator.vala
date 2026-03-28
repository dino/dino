using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

    class UnreadIndicatorPopulator : Plugins.ConversationItemPopulator, Plugins.ConversationAdditionPopulator, Object {

        public string id { get { return "unread_indicator"; } }

        private StreamInteractor stream_interactor;
        private Conversation? current_conversation;
        private UnreadIndicatorItem? unread_indicator = null;
        Plugins.ConversationItemCollection item_collection = null;

        public UnreadIndicatorPopulator(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            stream_interactor.get_module(ChatInteraction.IDENTITY).focused_out.connect(() => {
                update_unread_indicator();
            });

            stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(() => {
                if (!stream_interactor.get_module(ChatInteraction.IDENTITY).is_active_focus(current_conversation)) {
                    update_unread_indicator();
                }
            });
        }

        private void update_unread_indicator() {
            if (current_conversation == null) return;

            ContentItem? read_up_to_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(current_conversation, current_conversation.read_up_to_item);
            int current_num_unread = stream_interactor.get_module(ChatInteraction.IDENTITY).get_num_unread(current_conversation);
            if (current_num_unread == 0 && unread_indicator != null) {
                item_collection.remove_item(unread_indicator);
                unread_indicator = null;
            }

            if (read_up_to_item != null && current_num_unread > 0) {
                if (unread_indicator != null) {
                    item_collection.remove_item(unread_indicator);
                }

                unread_indicator = new UnreadIndicatorItem(read_up_to_item);
                item_collection.insert_item(unread_indicator);
            }
        }

        public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
            current_conversation = conversation;
            this.item_collection = item_collection;
            update_unread_indicator();
        }

        public void close(Conversation conversation) { }

        public void populate_timespan(Conversation conversation, DateTime after, DateTime before) { }
    }

    private class UnreadIndicatorItem : Plugins.MetaConversationItem {
        public UnreadIndicatorItem(ContentItem after_item) {
            this.time = after_item.time;
            this.secondary_sort_indicator = int.MAX;
        }

        public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {
            Box box = new Box(Orientation.HORIZONTAL, 10) { hexpand=true };
            box.get_style_context().add_class("dino-unread-line");

            Separator sep = new Separator(Orientation.HORIZONTAL) { valign=Align.CENTER, hexpand=true };
            box.append(sep);

            Label label = new Label(_("New")) { halign=Align.END, hexpand=false };
            label.attributes = new Pango.AttrList();
            label.attributes.insert(Pango.attr_weight_new(Pango.Weight.BOLD));
            box.append(label);

            return box;
        }

        public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) {
            return null;
        }
    }
}
