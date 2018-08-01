using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSelector {

public class ChatRow : ConversationRow {

    public ChatRow(StreamInteractor stream_interactor, Conversation conversation) {
        base(stream_interactor, conversation);
        has_tooltip = true;
        query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
            tooltip.set_custom(generate_tooltip());
            return true;
        });
        stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
            if (conversation.account.equals(account) && conversation.counterpart.equals(jid)) {
                update_name_label();
            }
        });
    }

    protected override void update_message_label() {
        base.update_message_label();
        if (last_message != null && last_message.direction == Message.DIRECTION_SENT) {
            nick_label.visible = true;
            nick_label.label = _("Me") + ": ";
        } else {
            nick_label.label = "";
        }
    }

    private Widget generate_tooltip() {
        Builder builder = new Builder.from_resource("/im/dino/Dino/conversation_selector/chat_row_tooltip.ui");
        Box main_box = builder.get_object("main_box") as Box;
        Box inner_box = builder.get_object("inner_box") as Box;
        Label jid_label = builder.get_object("jid_label") as Label;

        jid_label.label = conversation.counterpart.to_string();

        Gee.List<Jid>? full_jids = stream_interactor.get_module(PresenceManager.IDENTITY).get_full_jids(conversation.counterpart, conversation.account);
        if (full_jids != null) {
            for (int i = 0; i < full_jids.size; i++) {
                inner_box.add(get_fulljid_box(full_jids[i]));
            }
        }
        return main_box;
    }
}

}
