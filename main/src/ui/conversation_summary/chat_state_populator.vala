using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

class ChatStatePopulator : Plugins.ConversationItemPopulator, Plugins.ConversationAdditionPopulator, Object {

    public string id { get { return "chat_state"; } }

    private StreamInteractor? stream_interactor;
    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;

    private MetaChatStateItem? meta_item;

    public ChatStatePopulator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(CounterpartInteractionManager.IDENTITY).received_state.connect((account, jid, state) => {
            if (current_conversation != null && current_conversation.account.equals(account) && current_conversation.counterpart.equals_bare(jid)) {
                update_chat_state(account, jid);
            }
        });
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect((message, conversation) => {
            if (conversation.equals(current_conversation)) {
                update_chat_state(conversation.account, conversation.counterpart);
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

    private void update_chat_state(Account account, Jid jid) {
        HashMap<Jid, string>? states = stream_interactor.get_module(CounterpartInteractionManager.IDENTITY).get_chat_states(current_conversation);

        StateType? state_type = null;
        Gee.List<Jid> jids = new ArrayList<Jid>();

        if (states != null) {
            Gee.List<Jid> composing = new ArrayList<Jid>();
            Gee.List<Jid> paused = new ArrayList<Jid>();
            foreach (Jid j in states.keys) {
                string state = states[j];
                if (state == Xep.ChatStateNotifications.STATE_COMPOSING) {
                    composing.add(j);
                } else if (state == Xep.ChatStateNotifications.STATE_PAUSED) {
                    paused.add(j);
                }
            }
            if (composing.size == 1 || (composing.size > 1 && current_conversation.type_ != Conversation.Type.GROUPCHAT)) {
                state_type = StateType.TYPING;
                jids.add(composing[0]);
            } else if (paused.size >= 1 && current_conversation.type_ != Conversation.Type.GROUPCHAT) {
                state_type = StateType.PAUSED;
                jids.add(paused[0]);
            } else if (composing.size > 1) {
                state_type = StateType.TYPING;
                jids = composing;
            }
        }
        if (meta_item != null && state_type == null) {
            item_collection.remove_item(meta_item);
            meta_item = null;
        } else if (meta_item != null && state_type != null) {
            meta_item.set_new(state_type, jids);
        } else if (state_type != null) {
            meta_item = new MetaChatStateItem(stream_interactor, current_conversation, jid, state_type, jids);
            item_collection.insert_item(meta_item);
        }
    }
}

private enum StateType {
    TYPING,
    PAUSED
}

private class MetaChatStateItem : Plugins.MetaConversationItem {
    public override Jid? jid { get; set; }
    public override bool dim { get; set; default=true; }
    public override DateTime sort_time { get; set; default=new DateTime.now_utc().add_years(10); }

    public override bool can_merge { get; set; default=false; }
    public override bool requires_avatar { get; set; default=false; }
    public override bool requires_header { get; set; default=false; }

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private StateType state_type;
    private Gee.List<Jid> jids = new ArrayList<Jid>();
    private Label label;
    private AvatarImage image;

    public MetaChatStateItem(StreamInteractor stream_interactor, Conversation conversation, Jid jid, StateType state_type, Gee.List<Jid> jids) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.jid = jid;
        this.state_type = state_type;
        this.jids = jids;
    }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        label = new Label("") { xalign=0, vexpand=true, visible=true };
        label.get_style_context().add_class("dim-label");
        image = new AvatarImage() { margin_top=2, valign=Align.START, visible=true };

        Box image_content_box = new Box(Orientation.HORIZONTAL, 8) { visible=true };
        image_content_box.add(image);
        image_content_box.add(label);

        update();
        return image_content_box;
    }

    public void set_new(StateType state_type, Gee.List<Jid> jids) {
        this.state_type = state_type;
        this.jids = jids;
        update();
    }

    private void update() {
        if (image == null || label == null) return;

        image.set_conversation_participants(stream_interactor, conversation, jids.to_array());

        Gee.List<string> display_names = new ArrayList<string>();
        foreach (Jid jid in jids) {
            display_names.add(Util.get_participant_display_name(stream_interactor, conversation, jid));
        }
        string new_text = "";
        if (jids.size > 3) {
            new_text = _("%s, %s and %i others").printf(display_names[0], display_names[1], jids.size - 2);
        } else if (jids.size == 3) {
            new_text = _("%s, %s and %s").printf(display_names[0], display_names[1], display_names[2]);
        } else if (jids.size == 2) {
            new_text =_("%s and %s").printf(display_names[0], display_names[1]);
        } else {
            new_text = display_names[0];
        }
        if (state_type == StateType.TYPING) {
            new_text += " " + n("is typing…", "are typing…", jids.size);
        } else {
            new_text += " " + _("has stopped typing");
        }

        label.label = new_text;
    }
}

}
