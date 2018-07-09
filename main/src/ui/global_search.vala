using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/global_search.ui")]
class GlobalSearch : Box {
    private StreamInteractor stream_interactor;
    private string search = "";
    private int loaded_results = -1;
    private Mutex reloading_mutex = Mutex();

    [GtkChild] public SearchEntry search_entry;
    [GtkChild] public Label entry_number_label;
    [GtkChild] public ScrolledWindow results_scrolled;
    [GtkChild] public Box results_box;

    public GlobalSearch init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        search_entry.search_changed.connect(() => {
            set_search(search_entry.text);
        });

        results_scrolled.vadjustment.notify["value"].connect(() => {
            if (results_scrolled.vadjustment.upper - (results_scrolled.vadjustment.value + results_scrolled.vadjustment.page_size) < 100) {
                if (!reloading_mutex.trylock()) return;
                Gee.List<Message> new_messages = stream_interactor.get_module(SearchProcessor.IDENTITY).match_messages(search, loaded_results);
                if (new_messages.size == 0) {
                    reloading_mutex.unlock();
                    return;
                }
                loaded_results += new_messages.size;
                append_messages(new_messages);
            }
        });
        results_scrolled.vadjustment.notify["upper"].connect_after(() => {
            reloading_mutex.trylock();
            reloading_mutex.unlock();
        });
        return this;
    }

    private void clear_search() {
        results_box.@foreach((widget) => { widget.destroy(); });
    }

    private void set_search(string search) {
        clear_search();
        this.search = search;

        int match_count = stream_interactor.get_module(SearchProcessor.IDENTITY).count_match_messages(search);
        entry_number_label.label = "<i>" + _("%i search results").printf(match_count) + "</i>";
        Gee.List<Message> messages = stream_interactor.get_module(SearchProcessor.IDENTITY).match_messages(search);
        loaded_results += messages.size;
        append_messages(messages);
    }

    private void append_messages(Gee.List<Message> messages) {
        foreach (Message message in messages) {
            if (message.from == null) {
                print("wtf null\n");
            continue;
            }
            Conversation? conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation_for_message(message);
            Gee.List<Message> before_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_before_message(conversation, message.local_time, message.id, 1);
            Gee.List<Message> after_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_after_message(conversation, message.local_time, message.id, 1);

            Box context_box = new Box(Orientation.VERTICAL, 5) { visible=true };
            if (before_message != null && before_message.size > 0) {
                context_box.add(get_context_message_widget(before_message.first()));
            }
            context_box.add(get_match_message_widget(message));
            if (after_message != null && after_message.size > 0) {
                context_box.add(get_context_message_widget(after_message.first()));
            }

            Label date_label = new Label(ConversationSummary.DefaultSkeletonHeader.get_relative_time(message.time)) { xalign=0, visible=true };
            date_label.get_style_context().add_class("dim-label");

            string display_name = Util.get_conversation_display_name(stream_interactor, conversation);
            string title = message.type_ == Message.Type.GROUPCHAT ? _("In %s").printf(display_name) : _("With %s").printf(display_name);
            Box header_box = new Box(Orientation.HORIZONTAL, 10) { margin_left=7, visible=true };
            header_box.add(new Label(@"<b>$(Markup.escape_text(title))</b>") { ellipsize=EllipsizeMode.END, xalign=0, use_markup=true, visible=true });
            header_box.add(date_label);

            Box result_box = new Box(Orientation.VERTICAL, 7) { visible=true };
            result_box.add(header_box);
            result_box.add(context_box);

            results_box.add(result_box);
        }
    }

    // Workaround GTK TextView issues
    private void force_alloc_width(Widget widget, int width) {
        Allocation alloc = Allocation();
        widget.get_preferred_width(out alloc.width, null);
        widget.get_preferred_height(out alloc.height, null);
        alloc.width = width;
        widget.size_allocate(alloc);
    }

    private Widget get_match_message_widget(Message message) {
        Grid grid = get_skeleton(message);
        grid.margin_top = 3;
        grid.margin_bottom = 3;

        string text = message.body.replace("\n", "").replace("\r", "");
        if (text.length > 200) {
            int index = text.index_of(search);
            if (index + search.length <= 100) {
                text = text.substring(0, 150) + " … " + text.substring(text.length - 50, 50);
            } else if (index >= text.length - 100) {
                text = text.substring(0, 50) + " … " + text.substring(text.length - 150, 150);
            } else {
                text = text.substring(0, 25) + " … " + text.substring(index - 50, 50) + text.substring(index, 100) + " … " + text.substring(text.length - 25, 25);
            }
        }
        TextView tv = new TextView() { wrap_mode=Gtk.WrapMode.WORD_CHAR, hexpand=true, visible=true };
        tv.buffer.text = text;
        TextTag link_tag = tv.buffer.create_tag("hit", background: "yellow");

        Regex url_regex = new Regex(search.down());
        MatchInfo match_info;
        url_regex.match(text.down(), 0, out match_info);
        for (; match_info.matches(); match_info.next()) {
            int start;
            int end;
            match_info.fetch_pos(0, out start, out end);
            start = text[0:start].char_count();
            end = text[0:end].char_count();
            TextIter start_iter;
            TextIter end_iter;
            tv.buffer.get_iter_at_offset(out start_iter, start);
            tv.buffer.get_iter_at_offset(out end_iter, end);
            tv.buffer.apply_tag(link_tag, start_iter, end_iter);
        }
        grid.attach(tv, 1, 1, 1, 1);

        //        force_alloc_width(tv, this.width_request);

        Button button = new Button() { relief=ReliefStyle.NONE, visible=true };
        button.add(grid);
        return button;
    }

    private Grid get_context_message_widget(Message message) {
        Grid grid = get_skeleton(message);
        grid.margin_left = 7;
        Label label = new Label(message.body.replace("\n", "").replace("\r", "")) { ellipsize=EllipsizeMode.MIDDLE, xalign=0, visible=true };
        grid.attach(label, 1, 1, 1, 1);
        grid.opacity = 0.55;
        return grid;
    }

    private Grid get_skeleton(Message message) {
        AvatarImage image = new AvatarImage() { height=32, width=32, margin_right=7, valign=Align.START, visible=true, allow_gray = false };
        image.set_jid(stream_interactor, message.from, message.account);
        Grid grid = new Grid() { row_homogeneous=false, visible=true };
        grid.attach(image, 0, 0, 1, 2);

        string display_name = Util.get_display_name(stream_interactor, message.from, message.account);
        string color = Util.get_name_hex_color(stream_interactor, message.account, message.from, false); // TODO Util.is_dark_theme(name_label)
        Label name_label = new Label("") { use_markup=true, xalign=0, visible=true };
        name_label.label = @"<span size='small' foreground=\"#$color\">$display_name</span>";
        grid.attach(name_label, 1, 0, 1, 1);
        return grid;
    }
}

}
