using Gdk;
using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui {

public class ConversationSelector : Widget {

    public signal void conversation_selected(Conversation conversation);

    ListBox list_box = new ListBox() { hexpand=true };

    private StreamInteractor stream_interactor;
    private uint? drag_timeout;
    private HashMap<Conversation, ConversationSelectorRow> rows = new HashMap<Conversation, ConversationSelectorRow>(Conversation.hash_func, Conversation.equals_func);

    public ConversationSelector init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        list_box.set_parent(this);
        this.layout_manager = new BinLayout();

        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(add_conversation);
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(remove_conversation);
        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(on_content_item_received);
        Timeout.add_seconds(60, () => {
            foreach (ConversationSelectorRow row in rows.values) row.update();
            return true;
        });

        foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations()) {
            add_conversation(conversation);
        }
        return this;
    }

    construct {
        add_css_class("sidebar");
        list_box.set_header_func(header);
        list_box.set_sort_func(sort);

        realize.connect(() => {
            ListBoxRow? first_row = list_box.get_row_at_index(0);
            if (first_row != null) {
                list_box.select_row(first_row);
                row_activated(first_row);
            }
        });

        list_box.row_activated.connect(row_activated);
    }

    public void row_activated(ListBoxRow r) {
        ConversationSelectorRow? row = r as ConversationSelectorRow;
        if (row != null) {
            conversation_selected(row.conversation);
        }
    }

    public void on_conversation_selected(Conversation conversation) {
        if (!rows.has_key(conversation)) {
            add_conversation(conversation);
        }
        list_box.select_row(rows[conversation]);
    }

    private void on_content_item_received(ContentItem item, Conversation conversation) {
        if (rows.has_key(conversation)) {
            list_box.invalidate_sort();
        }
    }

    private void add_conversation(Conversation conversation) {
        ConversationSelectorRow row;
        if (!rows.has_key(conversation)) {
            row = new ConversationSelectorRow(stream_interactor, conversation);
            rows[conversation] = row;
            list_box.append(row);
            row.main_revealer.set_reveal_child(true);

            // Set up drag motion behaviour (select conversation after timeout)
            DropControllerMotion drop_motion_controller = new DropControllerMotion();
            uint drag_timeout = 0;
            drop_motion_controller.motion.connect((x, y) => {
                if (drag_timeout != 0) return;
                drag_timeout = Timeout.add(200, () => {
                    conversation_selected(conversation);
                    drag_timeout = 0;
                    return false;
                });
            });
            drop_motion_controller.leave.connect(() => {
                if (drag_timeout != 0) {
                    Source.remove(drag_timeout);
                    drag_timeout = 0;
                }
            });
            row.add_controller(drop_motion_controller);
        }
        list_box.invalidate_sort();
    }

    private void select_fallback_conversation(Conversation conversation) {
        if (list_box.get_selected_row() == rows[conversation]) {
            int index = rows[conversation].get_index();
            ListBoxRow? next_select_row = list_box.get_row_at_index(index + 1);
            if (next_select_row == null) {
                next_select_row = list_box.get_row_at_index(index - 1);
            }
            if (next_select_row != null) {
                list_box.select_row(next_select_row);
                row_activated(next_select_row);
            }
        }
    }

    private async void remove_conversation(Conversation conversation) {
        select_fallback_conversation(conversation);
        if (rows.has_key(conversation)) {
            yield rows[conversation].colapse();
            list_box.remove(rows[conversation]);
            rows.unset(conversation);
        }
    }

    public void loop_conversations(bool backwards) {
        int index = list_box.get_selected_row().get_index();
        int new_index = ((index + (backwards ? -1 : 1)) + rows.size) % rows.size;
        ListBoxRow? next_select_row = list_box.get_row_at_index(new_index);
        if (next_select_row != null) {
            list_box.select_row(next_select_row);
            row_activated(next_select_row);
        }
    }

    private void header(ListBoxRow row, ListBoxRow? before_row) {
        if (row.get_header() == null && before_row != null) {
            row.set_header(new Separator(Orientation.HORIZONTAL));
        } else if (row.get_header() != null && before_row == null) {
            row.set_header(null);
        }
    }

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        ConversationSelectorRow cr1 = row1 as ConversationSelectorRow;
        ConversationSelectorRow cr2 = row2 as ConversationSelectorRow;
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
