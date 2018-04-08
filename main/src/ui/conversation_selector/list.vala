using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui.ConversationSelector {

public class List : ListBox {

    public signal void conversation_selected(Conversation conversation);

    private StreamInteractor stream_interactor;
    private string[]? filter_values;
    private uint? drag_timeout;
    private HashMap<Conversation, ConversationRow> rows = new HashMap<Conversation, ConversationRow>(Conversation.hash_func, Conversation.equals_func);

    public List(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        get_style_context().add_class("sidebar");
        set_filter_func(filter);
        set_header_func(header);
        set_sort_func(sort);

        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(add_conversation);
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(remove_conversation);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_received.connect(on_message_received);
        stream_interactor.get_module(MessageProcessor.IDENTITY).message_sent.connect(on_message_received);
        Timeout.add_seconds(60, () => {
            foreach (ConversationRow row in rows.values) row.update();
            return true;
        });

        foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations()) {
            add_conversation(conversation);
        }
        realize.connect(() => {
            ListBoxRow? first_row = get_row_at_index(0);
            if (first_row != null) {
                select_row(first_row);
                row_activated(first_row);
            }
        });
    }

    public override void row_activated(ListBoxRow r) {
        if (r.get_type().is_a(typeof(ConversationRow))) {
            ConversationRow row = r as ConversationRow;
            conversation_selected(row.conversation);
        }
    }

    public void set_filter_values(string[]? values) {
        if (filter_values == values) {
            return;
        }
        filter_values = values;
        invalidate_filter();
    }

    public void on_conversation_selected(Conversation conversation) {
        if (!rows.has_key(conversation)) {
            add_conversation(conversation);
        }
        this.select_row(rows[conversation]);
    }

    private void on_message_received(Entities.Message message, Conversation conversation) {
        if (rows.has_key(conversation)) {
            invalidate_sort();
        }
    }

    private void add_conversation(Conversation conversation) {
        ConversationRow row;
        if (!rows.has_key(conversation)) {
            row = new ConversationRow(stream_interactor, conversation);
            rows[conversation] = row;
            add(row);
            row.closed.connect(() => { select_next_conversation(conversation); });
            row.main_revealer.set_reveal_child(true);
            drag_dest_set(row, DestDefaults.MOTION, null, Gdk.DragAction.COPY);
            drag_dest_set_track_motion(row, true);
            row.drag_motion.connect(this.on_drag_motion);
            row.drag_leave.connect(this.on_drag_leave);
        }
        invalidate_sort();
    }

    public bool on_drag_motion(Widget widget, Gdk.DragContext context,
                               int x, int y, uint time) {
        if (this.drag_timeout != null)
            return false;
        this.drag_timeout = Timeout.add(200, () => {
            if (widget.get_type().is_a(typeof(ConversationRow))) {
                ConversationRow row = widget as ConversationRow;
                conversation_selected(row.conversation);
            }
            this.drag_timeout = null;
            return false;
        });
        return false;
    }

    public void on_drag_leave(Widget widget, Gdk.DragContext context, uint time) {
        if (this.drag_timeout != null) {
            Source.remove(this.drag_timeout);
            this.drag_timeout = null;
        }
    }

    private void select_next_conversation(Conversation conversation) {
        if (get_selected_row() == rows[conversation]) {
            int index = rows[conversation].get_index();
            ListBoxRow? index_p1 = get_row_at_index(index + 1);
            if (index_p1 != null) {
                select_row(index_p1);
                row_activated(index_p1);
            } else if (index > 0) {
                ListBoxRow? index_m1 = get_row_at_index(index - 1);
                if (index_m1 != null) {
                    select_row(index_m1);
                    row_activated(index_m1);
                }
            }
        }
    }

    private void remove_conversation(Conversation conversation) {
        select_next_conversation(conversation);
        if (rows.has_key(conversation) && !conversation.active) {
            remove(rows[conversation]);
            rows.unset(conversation);
        }
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        } else if (row.get_header() != null && before_row == null) {
            row.set_header(null);
        }
    }

    private bool filter(ListBoxRow r) {
        if (r.get_type().is_a(typeof(ConversationRow))) {
            ConversationRow row = r as ConversationRow;
            if (filter_values != null && filter_values.length != 0) {
                foreach (string filter in filter_values) {
                    if (!(Util.get_conversation_display_name(stream_interactor, row.conversation).down().contains(filter.down()) ||
                            row.conversation.counterpart.to_string().down().contains(filter.down()))) {
                        return false;
                    }
                }
            }
        }
        return true;
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        ConversationRow cr1 = row1 as ConversationRow;
        ConversationRow cr2 = row2 as ConversationRow;
        if (cr1 != null && cr2 != null) {
            Conversation c1 = cr1.conversation;
            Conversation c2 = cr2.conversation;
            if (c1.last_active == null) return -1;
            if (c2.last_active == null) return 1;
            int comp = c2.last_active.compare(c1.last_active);
            if (comp == 0) {
                return Util.get_conversation_display_name(stream_interactor, c1)
                    .collate(Util.get_conversation_display_name(stream_interactor, c2));
            } else {
                return comp;
            }
        }
        return 0;
    }
}

}
