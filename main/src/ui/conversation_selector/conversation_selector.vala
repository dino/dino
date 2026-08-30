using Gdk;
using Gee;
using Gtk;

using Xmpp;
using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_selector.ui")]
public class ConversationSelector : Widget {

    public signal void conversation_selected(Conversation conversation);

    [GtkChild] private unowned ScrolledWindow scrolled;
    [GtkChild] private unowned ListBox list_box;

    private StreamInteractor stream_interactor;
    private HashMap<Conversation, ConversationSelectorRow> rows = new HashMap<Conversation, ConversationSelectorRow>(Conversation.hash_func, Conversation.equals_func);

    public ConversationSelector init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
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
        this.layout_manager = new BinLayout();
        list_box.set_sort_func(sort);

        realize.connect(() => {
            ListBoxRow? first_row = list_box.get_row_at_index(0);
            if (first_row != null) {
                list_box.select_row(first_row);
                row_activated(first_row);
            }
        });

        list_box.row_activated.connect(row_activated);

        check_widget_leak(this);
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
        ConversationSelectorRow row = rows[conversation];
        Idle.add(() => { scroll_to_row(row); return false; });
    }

    private void scroll_to_row(ConversationSelectorRow row) {
        double row_x, row_y;
        if (!row.translate_coordinates(list_box, 0, 0, out row_x, out row_y)) return;

        double row_bottom = row_y + row.get_allocated_height();
        double vadj_bottom = scrolled.vadjustment.value + scrolled.vadjustment.page_size;

        // don't scroll if any part of the row is visible
        if (row_bottom > scrolled.vadjustment.value && row_y < vadj_bottom) return;

        // scroll to vertically center the row, if possible
        double target = row_y + row.get_allocated_height() / 2.0 - scrolled.vadjustment.page_size / 2.0;
        target = target.clamp(0, scrolled.vadjustment.upper - scrolled.vadjustment.page_size);

        new Adw.TimedAnimation(scrolled, scrolled.vadjustment.value, target, 900,
            new Adw.PropertyAnimationTarget(scrolled.vadjustment, "value")
        ).play();
    }


    private void on_content_item_received(ContentItem item, Conversation conversation) {
        if (rows.has_key(conversation)) {
            list_box.invalidate_sort();
        }
    }

    private void add_conversation(Conversation conversation) {
        ConversationSelectorRow row;
        if (!rows.has_key(conversation)) {
            conversation.notify["pinned"].connect(list_box.invalidate_sort);

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
            conversation.notify["pinned"].disconnect(list_box.invalidate_sort);

            ConversationSelectorRow conversation_row;
            rows.unset(conversation, out conversation_row);

            yield conversation_row.colapse();
            list_box.remove(conversation_row);
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

    private int sort(ListBoxRow row1, ListBoxRow row2) {
        ConversationSelectorRow cr1 = row1 as ConversationSelectorRow;
        ConversationSelectorRow cr2 = row2 as ConversationSelectorRow;
        if (cr1 != null && cr2 != null) {
            Conversation c1 = cr1.conversation;
            Conversation c2 = cr2.conversation;

            int pin_comp = c2.pinned - c1.pinned;
            if (pin_comp != 0) return pin_comp;

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
