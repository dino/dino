using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

class ChatStatePopulator : Plugins.ConversationItemPopulator, Object {

    public string id { get { return "chat_state"; } }

    private StreamInteractor? stream_interactor;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;

    private MetaChatStateItem? meta_item;

    public ChatStatePopulator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(CounterpartInteractionManager.IDENTITY).received_state.connect((account, jid, state) => {
            if (current_conversation != null && current_conversation.account.equals(account) && current_conversation.counterpart.equals_bare(jid)) {
                Idle.add(() => { update_chat_state(account, jid, state); return false; });
            }
        });
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect((message, conversation) => {
            if (conversation.equals(current_conversation)) {
                Idle.add(() => { update_chat_state(conversation.account, conversation.counterpart); return false; });
            }
        });
    }

    public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.item_collection = item_collection;
        this.meta_item = null;

        update_chat_state(conversation.account, conversation.counterpart);
    }

    public void close(Conversation conversation) { }

    public void populate_timespan(Conversation conversation, DateTime from, DateTime to) { }

    public void populate_between_widgets(Conversation conversation, DateTime from, DateTime to) { }

    private void update_chat_state(Account account, Jid jid, string? state = null) {
        string? state_ = state;
        if (state_ == null) {
            state_ = stream_interactor.get_module(CounterpartInteractionManager.IDENTITY).get_chat_state(current_conversation.account, current_conversation.counterpart);
        }
        string? new_text = null;
        if (state_ != null) {
            if (state_ == Xep.ChatStateNotifications.STATE_COMPOSING || state_ == Xep.ChatStateNotifications.STATE_PAUSED) {
                if (state_ == Xep.ChatStateNotifications.STATE_COMPOSING) {
                    new_text = _("is typing...");
                } else if (state_ == Xep.ChatStateNotifications.STATE_PAUSED) {
                    new_text = _("has stopped typing");
                }
            }
        }
        if (meta_item != null && new_text == null) {
            item_collection.remove_item(meta_item);
            meta_item = null;
        } else if (meta_item != null && new_text != null) {
            meta_item.set_text(new_text);
        } else if (new_text != null) {
            meta_item = new MetaChatStateItem(stream_interactor, current_conversation, jid, new_text);
            item_collection.insert_item(meta_item);
        }

    }
}

public class MetaChatStateItem : Plugins.MetaConversationItem {
    public override Jid? jid { get; set; }
    public override bool dim { get; set; default=true; }
    public override DateTime? sort_time { get; set; default=new DateTime.now_utc().add_years(10); }

    public override bool can_merge { get; set; default=false; }
    public override bool requires_avatar { get; set; default=true; }
    public override bool requires_header { get; set; default=false; }

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private string text;
    private Label label;

    public MetaChatStateItem(StreamInteractor stream_interactor, Conversation conversation, Jid jid, string text) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.jid = jid;
        this.text = text;
    }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        label = new Label("") { xalign=0, vexpand=true, visible=true };
        label.get_style_context().add_class("dim-label");
        update_text();
        return label;
    }

    public void set_text(string text) {
        this.text = text;
        update_text();
    }

    private void update_text() {
        string display_name = Util.get_display_name(stream_interactor, jid, conversation.account);
        label.label = display_name + " " + text;
    }
}

}
