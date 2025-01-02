using Gee;
using Gtk;
using Pango;

using Dino.Entities;

namespace Dino.Ui {

public class GlobalSearch {
    public signal void selected_item(MessageItem item);
    private StreamInteractor stream_interactor;
    private string search = "";
    private int loaded_results = -1;
    private Mutex reloading_mutex = Mutex();

    public Overlay overlay;
    public SearchEntry search_entry;
    public Label entry_number_label;
    public ScrolledWindow results_scrolled;
    public Box results_box;
    public Stack results_empty_stack;
    public Frame auto_complete_overlay;
    public ListBox auto_complete_list;

    private ArrayList<Widget> auto_complete_children = new ArrayList<Widget>();
    private ArrayList<Widget> results_box_children = new ArrayList<Widget>();

    public GlobalSearch(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        Builder builder = new Builder.from_resource("/im/dino/Dino/global_search.ui");
        overlay = (Overlay) builder.get_object("overlay");
        search_entry = (SearchEntry) builder.get_object("search_entry");
        entry_number_label = (Label) builder.get_object("entry_number_label");
        results_scrolled = (ScrolledWindow) builder.get_object("results_scrolled");
        results_box = (Box) builder.get_object("results_box");
        results_empty_stack = (Stack) builder.get_object("results_empty_stack");
        auto_complete_overlay = (Frame) builder.get_object("auto_complete_overlay");
        auto_complete_list = (ListBox) builder.get_object("auto_complete_list");

        search_entry.search_changed.connect(() => {
            set_search(search_entry.text);
        });
        search_entry.notify["text"].connect_after(update_auto_complete);
        search_entry.notify["cursor-position"].connect_after(update_auto_complete);

        results_scrolled.vadjustment.notify["value"].connect(on_scrolled_window_vadjustment_value);
        results_scrolled.vadjustment.notify["upper"].connect_after(on_scrolled_window_vadjustment_upper);

        var overlay_key_events = new EventControllerKey() { name = "dino-search-overlay-key-events" };
        overlay_key_events.key_pressed.connect(on_key_pressed);
        overlay_key_events.key_released.connect(on_key_released);
        overlay.add_controller(overlay_key_events);
    }

    private void on_scrolled_window_vadjustment_value() {
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
    }

    private void on_scrolled_window_vadjustment_upper() {
        reloading_mutex.trylock();
        reloading_mutex.unlock();
    }

    private bool on_key_pressed(uint keyval, uint keycode, Gdk.ModifierType state) {
        if (!auto_complete_overlay.visible) return false;

        if (keyval == Gdk.Key.Up) {
            var row = auto_complete_list.get_selected_row();
            var index = row == null ? -1 : row.get_index() - 1;
            if (index == -1) index = (int)auto_complete_children.size - 1;
            auto_complete_list.select_row(auto_complete_list.get_row_at_index(index));
            return true;
        }
        if (keyval == Gdk.Key.Down) {
            var row = auto_complete_list.get_selected_row();
            var index = row == null ? 0 : row.get_index() + 1;
            if (index == auto_complete_children.size) index = 0;
            auto_complete_list.select_row(auto_complete_list.get_row_at_index(index));
            return true;
        }
        if (keyval == Gdk.Key.Tab) {
            auto_complete_list.get_selected_row().activate();
            return true;
        }
        // TODO: Handle cursor movement in results
        // TODO: Direct all keystrokes to text input
        return false;
    }

    private void on_key_released(uint keyval, uint keycode, Gdk.ModifierType state) {
        if (keyval == Gdk.Key.Return) {
            auto_complete_list.get_selected_row().activate();
        }
    }

    private void update_auto_complete() {
        Gee.List<SearchSuggestion> suggestions = stream_interactor.get_module(SearchProcessor.IDENTITY).suggest_auto_complete(search_entry.text, search_entry.cursor_position);
        auto_complete_overlay.visible = suggestions.size > 0;
        if (suggestions.size > 0) {
            // Remove current suggestions
            foreach (Widget widget in auto_complete_children) {
                auto_complete_list.remove(widget);
            }
            auto_complete_children.clear();

            // Populate new suggestions
            foreach(SearchSuggestion suggestion in suggestions) {
                Builder builder = new Builder.from_resource("/im/dino/Dino/search_autocomplete.ui");
                AvatarPicture avatar = (AvatarPicture)builder.get_object("picture");
                Label label = (Label)builder.get_object("label");
                string display_name;
                if (suggestion.conversation.type_ == Conversation.Type.GROUPCHAT && !suggestion.conversation.counterpart.equals(suggestion.jid) || suggestion.conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
                    display_name = Util.get_participant_display_name(stream_interactor, suggestion.conversation, suggestion.jid);
                    avatar.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(suggestion.conversation, suggestion.jid);
                } else {
                    display_name = Util.get_conversation_display_name(stream_interactor, suggestion.conversation);
                    avatar.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(suggestion.conversation);
                }
                if (display_name != suggestion.jid.to_string()) {
                    label.set_markup("%s <span font_weight='light' fgalpha='80%%'>%s</span>".printf(Markup.escape_text(display_name), Markup.escape_text(suggestion.jid.to_string())));
                } else {
                    label.label = display_name;
                }
                ListBoxRow row = new ListBoxRow() { visible = true, can_focus = false };
                row.set_child((Widget)builder.get_object("root"));
                row.activate.connect(() => {
                    handle_suggestion(suggestion);
                });
                auto_complete_list.append(row);
                auto_complete_children.add(row);
            }
            auto_complete_list.select_row(auto_complete_list.get_row_at_index(0));
        }
    }

    private void handle_suggestion(SearchSuggestion suggestion) {
        search_entry.delete_text(suggestion.start_index, suggestion.end_index);
        int position = search_entry.cursor_position;
        search_entry.insert_text(suggestion.completion + " ", suggestion.completion.length + 1, ref position);
        search_entry.set_position(-1);
    }

    private void clear_search() {
        // Scroll to top
        results_scrolled.vadjustment.value = 0;
        foreach (Widget widget in results_box_children) {
            results_box.remove(widget);
        }
        results_box_children.clear();
        loaded_results = 0;
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
            Gee.List<MessageItem> before_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_before_message(item.conversation, item.message.time, item.message.id, 1);
            Gee.List<MessageItem> after_message = stream_interactor.get_module(MessageStorage.IDENTITY).get_messages_after_message(item.conversation, item.message.time, item.message.id, 1);

            Box context_box = new Box(Orientation.VERTICAL, 5);
            if (before_message != null && before_message.size > 0) {
                context_box.append(get_context_message_widget(before_message.first()));
            }

            Widget match_widget = get_match_message_widget(item);
            context_box.append(match_widget);

            if (after_message != null && after_message.size > 0) {
                context_box.append(get_context_message_widget(after_message.first()));
            }

            Label date_label = new Label(ConversationSummary.ConversationItemSkeleton.get_relative_time(item.time.to_local())) { xalign=0 };
            date_label.add_css_class("dim-label");

            string display_name = Util.get_conversation_display_name(stream_interactor, item.conversation);
            string title = item.message.type_ == Message.Type.GROUPCHAT ? _("In %s").printf(display_name) : _("With %s").printf(display_name);
            Box header_box = new Box(Orientation.HORIZONTAL, 10) { margin_start=7 };
            header_box.append(new Label(@"<b>$(Markup.escape_text(title))</b>") { ellipsize=EllipsizeMode.END, xalign=0, use_markup=true });
            header_box.append(date_label);

            Box result_box = new Box(Orientation.VERTICAL, 7);
            result_box.append(header_box);
            result_box.append(context_box);

            results_box.append(result_box);
            results_box_children.add(result_box);

        }
    }

    private Widget get_match_message_widget(MessageItem item) {
        Grid grid = get_skeleton(item);
        grid.margin_top = 3;
        grid.margin_bottom = 3;

        string text = Util.unbreak_space_around_non_spacing_mark(item.message.body.replace("\n", "").replace("\r", ""));
        if (text.char_count() > 200) {
            int index = text.index_of(search);
            int char_index = index < 0 ? 0 : text.char_count(index);
            if (char_index + search.char_count() <= 100) {
                text = text.substring(0, text.index_of_nth_char(150)) + " … " + text.substring(text.index_of_nth_char(text.char_count() - 50));
            } else if (char_index >= text.char_count() - 100) {
                text = text.substring(0, text.index_of_nth_char(50)) + " … " + text.substring(text.index_of_nth_char(text.char_count() - 150));
            } else {
                text = text.substring(0, text.index_of_nth_char(25)) + " … " + text.substring(text.index_of_nth_char(char_index - 50), text.index_of_nth_char(char_index + 100)) + " … " + text.substring(text.index_of_nth_char(text.char_count() - 25));
            }
        }
        Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, vexpand=true };

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
                string themed_span = Util.is_dark_theme(label) ? "<span color=\"black\" bgcolor=\"yellow\">" : "<span bgcolor=\"yellow\">";
                markup_text += Markup.escape_text(text[last_end:start]) + themed_span + Markup.escape_text(text[start:end]) + "</span>";
                last_end = end;
            }
            markup_text += Markup.escape_text(text[last_end:text.length]);
        } catch (RegexError e) {
            assert_not_reached();
        }

        label.label = markup_text;
        grid.attach(label, 1, 1, 1, 1);

        Button button = new Button() { has_frame=false };
        button.clicked.connect(() => {
            selected_item(item);
        });
        button.child = grid;
        return button;
    }

    private Grid get_context_message_widget(MessageItem item) {
        Grid grid = get_skeleton(item);
        grid.margin_start = 7;
        Label label = new Label(item.message.body.replace("\n", "").replace("\r", "")) { ellipsize=EllipsizeMode.MIDDLE, xalign=0 };
        grid.attach(label, 1, 1, 1, 1);
        grid.opacity = 0.55;
        return grid;
    }

    private Grid get_skeleton(MessageItem item) {
        AvatarPicture picture = new AvatarPicture() { height_request=32, width_request=32, margin_end=7, valign=Align.START };
        picture.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).add_participant(item.conversation, item.jid);
        Grid grid = new Grid() { row_homogeneous=false };
        grid.attach(picture, 0, 0, 1, 2);

        string display_name = Util.get_participant_display_name(stream_interactor, item.conversation, item.jid);
        Label name_label = new Label(display_name) { ellipsize=EllipsizeMode.END, xalign=0 };
        name_label.attributes = new AttrList();
        name_label.attributes.insert(attr_weight_new(Weight.BOLD));
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

    public Widget get_widget() {
        return overlay;
    }
}

}
