using Gee;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/global_search.ui")]
public class GlobalSearch : Overlay {
    public signal void selected_item(MessageItem item);
    private StreamInteractor stream_interactor;
    private string search = "";
    private int loaded_results = -1;
    private Mutex reloading_mutex = Mutex();

    [GtkChild] public SearchEntry search_entry;
    [GtkChild] public Label entry_number_label;
    [GtkChild] public ScrolledWindow results_scrolled;
    [GtkChild] public Box results_box;
    [GtkChild] public Stack results_empty_stack;
    [GtkChild] public Frame auto_complete_overlay;
    [GtkChild] public ListBox auto_complete_list;

    public GlobalSearch init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        search_entry.search_changed.connect(() => {
            set_search(search_entry.text);
        });
        search_entry.notify["text"].connect_after(() => { update_auto_complete(); });
        search_entry.notify["cursor-position"].connect_after(() => { update_auto_complete(); });

        results_scrolled.vadjustment.notify["value"].connect(() => {
            if (results_scrolled.vadjustment.upper - (results_scrolled.vadjustment.value + results_scrolled.vadjustment.page_size) < 100) {
                if (!reloading_mutex.trylock()) return;
                Gee.List<MessageItem> new_messages = stream_interactor.get_module(SearchProcessor.IDENTITY).match_messages(search, loaded_results);
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

        event.connect((event) => {
            if (auto_complete_overlay.visible) {
                if (event.type == Gdk.EventType.KEY_PRESS && event.key.keyval == Gdk.Key.Up) {
                    var row = auto_complete_list.get_selected_row();
                    var index = row == null ? -1 : row.get_index() - 1;
                    if (index == -1) index = (int)auto_complete_list.get_children().length() - 1;
                    auto_complete_list.select_row(auto_complete_list.get_row_at_index(index));
                    return true;
                }
                if (event.type == Gdk.EventType.KEY_PRESS && event.key.keyval == Gdk.Key.Down) {
                    var row = auto_complete_list.get_selected_row();
                    var index = row == null ? 0 : row.get_index() + 1;
                    if (index == auto_complete_list.get_children().length()) index = 0;
                    auto_complete_list.select_row(auto_complete_list.get_row_at_index(index));
                    return true;
                }
                if (event.type == Gdk.EventType.KEY_PRESS && event.key.keyval == Gdk.Key.Tab ||
                    event.type == Gdk.EventType.KEY_RELEASE && event.key.keyval == Gdk.Key.Return) {
                    auto_complete_list.get_selected_row().activate();
                    return true;
                }
            }
            // TODO: Handle cursor movement in results
            // TODO: Direct all keystrokes to text input
            return false;
        });

        return this;
    }

    private void update_auto_complete() {
        Gee.List<SearchSuggestion> suggestions = stream_interactor.get_module(SearchProcessor.IDENTITY).suggest_auto_complete(search_entry.text, search_entry.cursor_position);
        auto_complete_overlay.visible = suggestions.size > 0;
        if (suggestions.size > 0) {
            auto_complete_list.@foreach((widget) => auto_complete_list.remove(widget));
            foreach(SearchSuggestion suggestion in suggestions) {
                Builder builder = new Builder.from_resource("/im/dino/Dino/search_autocomplete.ui");
                AvatarImage avatar = (AvatarImage)builder.get_object("image");
                Label label = (Label)builder.get_object("label");
                string display_name;
                if (suggestion.conversation.type_ == Conversation.Type.GROUPCHAT && !suggestion.conversation.counterpart.equals(suggestion.jid) || suggestion.conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
                    display_name = Util.get_participant_display_name(stream_interactor, suggestion.conversation, suggestion.jid);
                    avatar.set_conversation_participant(stream_interactor, suggestion.conversation, suggestion.jid);
                } else {
                    display_name = Util.get_conversation_display_name(stream_interactor, suggestion.conversation);
                    avatar.set_conversation(stream_interactor, suggestion.conversation);
                }
                if (display_name != suggestion.jid.to_string()) {
                    label.set_markup(@"$display_name <span font_weight='light' fgalpha='80%'>$(suggestion.jid)</span>");
                } else {
                    label.label = display_name;
                }
                ListBoxRow row = new ListBoxRow() { visible = true, can_focus = false };
                row.add((Widget)builder.get_object("root"));
                row.activate.connect(() => {
                    handle_suggestion(suggestion);
                });
                auto_complete_list.add(row);
            }
            auto_complete_list.select_row(auto_complete_list.get_row_at_index(0));
        }
    }

    private void handle_suggestion(SearchSuggestion suggestion) {
        search_entry.move_cursor(MovementStep.LOGICAL_POSITIONS, suggestion.start_index - search_entry.cursor_position, false);
        search_entry.delete_from_cursor(DeleteType.CHARS, suggestion.end_index - suggestion.start_index);
        search_entry.insert_at_cursor(suggestion.completion + " ");
    }

    private void clear_search() {
        results_box.@foreach((widget) => { widget.destroy(); });
    }

    private void set_search(string search) {
        clear_search();
        this.search = search;

        if (get_keywords(search).is_empty) {
            results_empty_stack.set_visible_child_name("empty");
            return;
        }

        Gee.List<MessageItem> messages = stream_interactor.get_module(SearchProcessor.IDENTITY).match_messages(search);
        if (messages.size == 0) {
            results_empty_stack.set_visible_child_name("no-result");
        } else {
            results_empty_stack.set_visible_child_name("results");

            int match_count = messages.size < 10 ? messages.size : stream_interactor.get_module(SearchProcessor.IDENTITY).count_match_messages(search);
            entry_number_label.label = "<i>" + n("%i search result", "%i search results", match_count).printf(match_count) + "</i>";
            loaded_results += messages.size;
            append_messages(messages);
        }
    }

    private void append_messages(Gee.List<MessageItem> messages) {
        foreach (MessageItem item in messages) {
            Gee.List<MessageItem> before_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_before_message(item.conversation, item.message.local_time, item.message.id, 1);
            Gee.List<MessageItem> after_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_after_message(item.conversation, item.message.local_time, item.message.id, 1);

            Box context_box = new Box(Orientation.VERTICAL, 5) { visible=true };
            if (before_message != null && before_message.size > 0) {
                context_box.add(get_context_message_widget(before_message.first()));
            }

            Widget match_widget = get_match_message_widget(item);
            context_box.add(match_widget);

            if (after_message != null && after_message.size > 0) {
                context_box.add(get_context_message_widget(after_message.first()));
            }

            Label date_label = new Label(ConversationSummary.ItemMetaDataHeader.get_relative_time(item.display_time.to_local())) { xalign=0, visible=true };
            date_label.get_style_context().add_class("dim-label");

            string display_name = Util.get_conversation_display_name(stream_interactor, item.conversation);
            string title = item.message.type_ == Message.Type.GROUPCHAT ? _("In %s").printf(display_name) : _("With %s").printf(display_name);
            Box header_box = new Box(Orientation.HORIZONTAL, 10) { margin_start=7, visible=true };
            header_box.add(new Label(@"<b>$(Markup.escape_text(title))</b>") { ellipsize=EllipsizeMode.END, xalign=0, use_markup=true, visible=true });
            header_box.add(date_label);

            Box result_box = new Box(Orientation.VERTICAL, 7) { visible=true };
            result_box.add(header_box);
            result_box.add(context_box);

            results_box.add(result_box);
        }
    }

    private Widget get_match_message_widget(MessageItem item) {
        Grid grid = get_skeleton(item);
        grid.margin_top = 3;
        grid.margin_bottom = 3;

        string text = item.message.body.replace("\n", "").replace("\r", "");
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
        Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, vexpand=true, visible=true };

        // Build regex containing all keywords
        string regex_str = "(";
        Gee.List<string> keywords = get_keywords(Regex.escape_string(search.down()));
        bool first = true;
        foreach (string keyword in keywords) {
            if (first) {
                first = false;
            } else {
                regex_str += "|";
            }
            regex_str += "\\b" + keyword;
        }
        regex_str += ")";

        // Color the keywords
        string markup_text = "";
        try {
            Regex highlight_regex = new Regex(regex_str, RegexCompileFlags.CASELESS);
            MatchInfo match_info;
            highlight_regex.match(text, 0, out match_info);
            int last_end = 0;
            for (; match_info.matches(); match_info.next()) {
                int start, end;
                match_info.fetch_pos(0, out start, out end);
                markup_text += Markup.escape_text(text[last_end:start]) + "<span bgcolor=\"yellow\">" + Markup.escape_text(text[start:end]) + "</span>";
                last_end = end;
            }
            markup_text += Markup.escape_text(text[last_end:text.length]);
        } catch (RegexError e) {
            assert_not_reached();
        }

        label.label = markup_text;
        grid.attach(label, 1, 1, 1, 1);

        Button button = new Button() { relief=ReliefStyle.NONE, visible=true };
        button.clicked.connect(() => {
            selected_item(item);
        });
        button.add(grid);
        return button;
    }

    private Grid get_context_message_widget(MessageItem item) {
        Grid grid = get_skeleton(item);
        grid.margin_start = 7;
        Label label = new Label(item.message.body.replace("\n", "").replace("\r", "")) { ellipsize=EllipsizeMode.MIDDLE, xalign=0, visible=true };
        grid.attach(label, 1, 1, 1, 1);
        grid.opacity = 0.55;
        return grid;
    }

    private Grid get_skeleton(MessageItem item) {
        AvatarImage image = new AvatarImage() { height=32, width=32, margin_end=7, valign=Align.START, visible=true, allow_gray = false };
        image.set_conversation_participant(stream_interactor, item.conversation, item.jid);
        Grid grid = new Grid() { row_homogeneous=false, visible=true };
        grid.attach(image, 0, 0, 1, 2);

        string display_name = Util.get_participant_display_name(stream_interactor, item.conversation, item.jid);
        string color = Util.get_name_hex_color(stream_interactor, item.message.account, item.jid, false); // TODO Util.is_dark_theme(name_label)
        Label name_label = new Label("") { ellipsize=EllipsizeMode.END, use_markup=true, xalign=0, visible=true };
        name_label.label = @"<span size='small' foreground=\"#$color\">$display_name</span>";
        grid.attach(name_label, 1, 0, 1, 1);
        return grid;
    }

    private static Gee.List<string> get_keywords(string search_string) {
        Gee.List<string> ret = new ArrayList<string>();
        foreach (string search in search_string.split(" ")) {
            bool is_filter = search.has_prefix("from:") || search.has_prefix("in:") || search.has_prefix("with:");
            if (!is_filter && search != "") {
                ret.add(search);
            }
        }
        return ret;
    }
}

}
