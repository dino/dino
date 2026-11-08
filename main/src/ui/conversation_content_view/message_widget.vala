using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class MessageMetaItem : ContentMetaItem {

    enum AdditionalInfo {
        NONE,
        PENDING,
        DELIVERY_FAILED
    }

    private StreamInteractor stream_interactor;
    private MessageItem message_item;
    public Message.Marked marked { get; set; }
    public Plugins.ConversationItemWidgetInterface outer = null;

    MessageItemEditMode? edit_mode = null;
    ChatTextViewController? controller = null;
    AdditionalInfo additional_info = AdditionalInfo.NONE;

    ulong realize_id = -1;
    ulong marked_notify_handler_id = -1;
    uint pending_timeout_id = -1;

    public Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, hexpand=true, vexpand=true };

    public MessageMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
        base(content_item);
        message_item = content_item as MessageItem;
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(MessageCorrection.IDENTITY).received_correction.connect(on_updated_item);
        stream_interactor.get_module(MessageDeletion.IDENTITY).item_deleted.connect(on_updated_item);

        label.activate_link.connect(on_label_activate_link);

        Message message = ((MessageItem) content_item).message;
        if (message.direction == Message.DIRECTION_SENT && !(message.marked in Message.MARKED_RECEIVED)) {
            var binding = message.bind_property("marked", this, "marked");
            marked_notify_handler_id = this.notify["marked"].connect(() => {
                // Currently "pending", but not anymore
                if (additional_info == AdditionalInfo.PENDING &&
                        message.marked != Message.Marked.SENDING && message.marked != Message.Marked.UNSENT) {
                    update_label();
                }

                // Currently "error", but not anymore
                if (additional_info == AdditionalInfo.DELIVERY_FAILED && message.marked != Message.Marked.ERROR) {
                    update_label();
                }

                // Currently not error, but should be
                if (additional_info != AdditionalInfo.DELIVERY_FAILED && message.marked == Message.Marked.ERROR) {
                    update_label();
                }

                // Nothing bad can happen anymore
                if (message.marked in Message.MARKED_RECEIVED) {
                    binding.unbind();
                    this.disconnect(marked_notify_handler_id);
                    marked_notify_handler_id = -1;
                }
            });
        }

        update_label();
    }

    private void generate_markup_text(ContentItem item, Label label) {
        MessageItem message_item = item as MessageItem;
        Conversation conversation = message_item.conversation;
        Message message = message_item.message;

        // Get a copy of the markup spans, such that we can modify them
        var markups = new ArrayList<Xep.MessageMarkup.Markup>();
        foreach (var markup in message.get_markups()) {
            if (markup is Xep.MessageMarkup.Span) {
                Xep.MessageMarkup.Span span = (Xep.MessageMarkup.Span) markup;
                markups.add(new Xep.MessageMarkup.Span() { types=span.types, start_char=span.start_char + 1, end_char=span.end_char - 1 });
            } else if (markup is Xep.MessageMarkup.BlockQuote) {
                Xep.MessageMarkup.BlockQuote quote = (Xep.MessageMarkup.BlockQuote) markup;
                markups.add(new Xep.MessageMarkup.BlockQuote() { start_char=quote.start_char + 1, end_char=quote.end_char - 1 });
            } else if (markup is Xep.MessageMarkup.CodeBlock) {
                Xep.MessageMarkup.CodeBlock quote = (Xep.MessageMarkup.CodeBlock) markup;
                markups.add(new Xep.MessageMarkup.CodeBlock() { start_char=quote.start_char + 1, end_char=quote.end_char - 1 });
            }
        }

        string markup_text = message.body;

        if (markup_text == null) return; // TODO remove

        // Only process messages up to a certain size
        if (markup_text.length > 10000) {
            markup_text = markup_text.substring(0, 10000) + " [" + _("Message too long") + "]";
        }

        bool theme_dependent = false;

        markup_text = Util.remove_fallbacks_adjust_markups(markup_text, message.quoted_item_id > 0, message.get_fallbacks(), markups);

        // Prefix message with name instead of /me
        if (markup_text.has_prefix("/me ")) {
            string display_name = Util.get_participant_display_name(stream_interactor, conversation, message.from);
            markup_text = display_name + " " + markup_text.substring(4);

            foreach (Xep.MessageMarkup.Markup markup in markups) {
                if (markup is Xep.MessageMarkup.Span || markup is Xep.MessageMarkup.BlockQuote) {
                    int length_to_adjust = display_name.char_count() - 4 + 1;
                    markup.start_char += length_to_adjust;
                    markup.end_char += length_to_adjust;
                }
            }

            var markup_types = new ArrayList<Xep.MessageMarkup.SpanType>();
            markup_types.add(Xep.MessageMarkup.SpanType.EMPHASIS);
            markup_types.add(Xep.MessageMarkup.SpanType.STRONG_EMPHASIS);
            markups.add(new Xep.MessageMarkup.Span() { types=markup_types, start_char=0, end_char=display_name.char_count()});
        }

        // Collect markup for the own highlighted nickname in MUCs
        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            markups.add_all(get_markup_for_highlight_word(markup_text, conversation.nickname));
        }

        // Parse the markup directives from markdown
        var parsed = Xep.MessageStyling.parse(markup_text);
        markups.add_all(parsed);

        // Add markups to make the markdown characters (*, _, etc) greyed out
        foreach (var markup in parsed) {
            if (markup is Xep.MessageMarkup.Span) {
                var span = markup as Xep.MessageMarkup.Span;

                var grey = new ArrayList<CustomSpanType>();
                grey.add(CustomSpanType.GREYED_OUT);
                markups.add(new CustomSpan() { types=grey, start_char=span.start_char - 1, end_char=span.start_char});
                markups.add(new CustomSpan() { types=grey, start_char=span.end_char, end_char=span.end_char + 1});
            }
        }

        // Apply the pango attributes
        label.set_attributes(get_attr_list_for_markups(markup_text, markups));

        // Work around pango bug
        markup_text = Util.unbreak_space_around_non_spacing_mark((owned) markup_text);

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            markup_text = Util.parse_add_markup_theme(markup_text, conversation.nickname, true, false, false, Util.is_dark_theme(this.label), ref theme_dependent);
        } else {
            markup_text = Util.parse_add_markup_theme(markup_text, null, true, false, false, Util.is_dark_theme(this.label), ref theme_dependent);
        }

        int only_emoji_count = Util.get_only_emoji_count(markup_text);
        if (only_emoji_count != -1) {
            string size_str = only_emoji_count < 5 ? "xx-large" : "large";
            markup_text = @"<span size=\'$size_str\'>" + markup_text + "</span>";
        }

        string dim_color = Util.is_dark_theme(this.label) ? "#BDBDBD" : "#707070";

        if (message.body == "") {
            markup_text = @"<i><span size='small' color='$dim_color'>%s</span></i>".printf(_("Message deleted"));
            theme_dependent = true;
        }
        if (message.edit_to != null) {
            markup_text += @"  <span size='small' color='$dim_color'>(%s)</span>".printf(_("edited"));
            theme_dependent = true;
        }

        // Append message status info
        additional_info = AdditionalInfo.NONE;
        if (message.direction == Message.DIRECTION_SENT && (message.marked == Message.Marked.SENDING || message.marked == Message.Marked.UNSENT)) {
            // Append "pending..." iff message has not been sent yet
            if (message.time.compare(new DateTime.now_utc().add_seconds(-10)) < 0) {
                markup_text += @"  <span size='small' color='$dim_color'>%s</span>".printf(_("pending…"));
                theme_dependent = true;
                additional_info = AdditionalInfo.PENDING;
            } else {
                int time_diff = (- (int) message.time.difference(new DateTime.now_utc()) / 1000);
                if (pending_timeout_id != -1) Source.remove(pending_timeout_id);
                pending_timeout_id = Timeout.add(10000 - time_diff, () => {
                    update_label();
                    pending_timeout_id = -1;
                    return false;
                });
            }
        } else if (message.direction == Message.DIRECTION_SENT && message.marked == Message.Marked.ERROR) {
            // Append "delivery failed" if there was a server error
            // TODO: Use a dedicated label, not appended text
            string error_color = Util.rgba_to_hex(Util.get_label_pango_color(label, "error_color"));
            markup_text += "  <span size='small' color='%s'>%s</span>".printf(error_color, _("delivery failed"));
            theme_dependent = true;
            additional_info = AdditionalInfo.DELIVERY_FAILED;
        }

        if (theme_dependent && realize_id == -1) {
            realize_id = label.realize.connect(update_label);
        } else if (!theme_dependent && realize_id != -1) {
            label.disconnect(realize_id);
        }
        label.label = markup_text;
    }

    private Gee.List<Xep.MessageMarkup.Markup> get_markup_for_highlight_word(string text, string highlight_word) {
        var markups = new ArrayList<Xep.MessageMarkup.Markup>();

        try {
            Regex highlight_regex = new Regex("\\b" + Regex.escape_string(highlight_word.down()) + "\\b", RegexCompileFlags.CASELESS);
            MatchInfo match_info;
            highlight_regex.match(text, 0, out match_info);
            if (match_info.matches()) {
                int start, end;
                match_info.fetch_pos(0, out start, out end);

                var markup_types = new ArrayList<Xep.MessageMarkup.SpanType>();
                markup_types.add(Xep.MessageMarkup.SpanType.STRONG_EMPHASIS);
                markups.add(new Xep.MessageMarkup.Span() { types=markup_types, start_char=start, end_char=end});
            }
        } catch (RegexError e) {
            assert_not_reached();
        }

        return markups;
    }

    private Pango.AttrList get_attr_list_for_markups(string text, Gee.List<Xep.MessageMarkup.Markup> markups) {
        var attrs = new AttrList();

        foreach (var markup in markups) {

            if (markup is Xep.MessageMarkup.Span) {
                var span = markup as Xep.MessageMarkup.Span;

                foreach (var ty in span.types) {
                    Attribute attr = null;
                    switch (ty) {
                        case Xep.MessageMarkup.SpanType.EMPHASIS:
                            attr = Pango.attr_style_new(Pango.Style.ITALIC);
                            break;
                        case Xep.MessageMarkup.SpanType.STRONG_EMPHASIS:
                            attr = Pango.attr_weight_new(Pango.Weight.BOLD);
                            break;
                        case Xep.MessageMarkup.SpanType.DELETED:
                            attr = Pango.attr_strikethrough_new(true);
                            break;
                        case Xep.MessageMarkup.SpanType.CODE:
                            attr = Pango.attr_family_new("monospace");
                            break;
                    }
                    if (attr == null) continue;
                    attr.start_index = text.index_of_nth_char(span.start_char);
                    attr.end_index = text.index_of_nth_char(span.end_char);
                    attrs.insert(attr.copy());
                }
            } else if (markup is CustomSpan) {
                var custom_span = markup as CustomSpan;

                foreach (var ty in custom_span.types) {
                    Attribute attr = null;
                    switch (ty) {
                        case CustomSpanType.GREYED_OUT:
                            attr = Pango.attr_foreground_alpha_new(40000);
                            break;
                    }
                    if (attr == null) continue;
                    attr.start_index = text.index_of_nth_char(custom_span.start_char);
                    attr.end_index = text.index_of_nth_char(custom_span.end_char);
                    attrs.insert(attr.copy());
                }
            } else if (markup is Xep.MessageMarkup.BlockQuote) {
                Attribute attr = Pango.attr_foreground_alpha_new(40000);
                attr.start_index = text.index_of_nth_char(markup.start_char);
                attr.end_index = text.index_of_nth_char(markup.end_char);
                attrs.insert(attr.copy());
            } else if (markup is Xep.MessageMarkup.CodeBlock) {
                Attribute attr = Pango.attr_family_new("monospace");
                attr.start_index = text.index_of_nth_char(markup.start_char);
                attr.end_index = text.index_of_nth_char(markup.end_char);
                attrs.insert(attr.copy());
            }
        }
        return attrs;
    }

    public void update_label() {
        generate_markup_text(content_item, label);
    }

    public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {
        this.outer = outer;

        this.notify["in-edit-mode"].connect(on_in_edit_mode_changed);

        outer.set_widget(label, Plugins.WidgetType.GTK4, 2);

        if (message_item.message.quoted_item_id > 0) {
            var quoted_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item_by_id(message_item.conversation, message_item.message.quoted_item_id);
            if (quoted_content_item != null) {
                var quote_model = new Quote.Model.from_content_item(quoted_content_item, message_item.conversation, stream_interactor);
                quote_model.jump_to.connect(() => {
                    GLib.Application.get_default().activate_action("jump-to-conversation-message", new GLib.Variant.tuple(new GLib.Variant[] { new GLib.Variant.int32(message_item.conversation.id), new GLib.Variant.int32(quoted_content_item.id) }));
                });
                var quote_widget = Quote.get_widget(quote_model);
                outer.set_widget(quote_widget, Plugins.WidgetType.GTK4, 1);
            }
        }
        return label;
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) {
        if (in_edit_mode) return null;

        Gee.List<Plugins.MessageAction> actions = new ArrayList<Plugins.MessageAction>();

        bool correction_allowed = stream_interactor.get_module(MessageCorrection.IDENTITY).is_own_correction_allowed(message_item.conversation, message_item.message);
        if (correction_allowed) {
            Plugins.MessageAction action1 = new Plugins.MessageAction();
            action1.name = "correction";
            action1.icon_name = "dino-document-edit-symbolic";
            action1.tooltip = _("Edit message");
            action1.shortcut_action = false;
            action1.callback = () => {
                this.in_edit_mode = true;
            };
            actions.add(action1);
        }

        actions.add(get_reply_action(content_item, message_item.conversation, stream_interactor));
        actions.add(get_reaction_action(content_item, message_item.conversation, stream_interactor));

        var delete_action = get_delete_action(content_item, message_item.conversation, stream_interactor);
        if (delete_action != null) actions.add(delete_action);

        return actions;
    }

    private void on_in_edit_mode_changed() {
        if (in_edit_mode == false) return;
        bool allowed = stream_interactor.get_module(MessageCorrection.IDENTITY).is_own_correction_allowed(message_item.conversation, message_item.message);
        if (allowed) {
            MessageItem message_item = content_item as MessageItem;
            Message message = message_item.message;

            edit_mode = new MessageItemEditMode();
            controller = new ChatTextViewController(edit_mode.chat_text_view, stream_interactor);
            Conversation conversation = message_item.conversation;
            controller.initialize_for_conversation(conversation);

            edit_mode.cancelled.connect(() => {
                in_edit_mode = false;
                outer.set_widget(label, Plugins.WidgetType.GTK4, 2);
            });
            edit_mode.send.connect(() => {
                string text = edit_mode.chat_text_view.text_view.buffer.text;
                var markups = edit_mode.chat_text_view.get_markups();
                Dino.send_message(message_item.conversation, text, message_item.message.quoted_item_id, message_item.message, markups);

                in_edit_mode = false;
                outer.set_widget(label, Plugins.WidgetType.GTK4, 2);
            });

            edit_mode.chat_text_view.set_text(message);

            outer.set_widget(edit_mode, Plugins.WidgetType.GTK4, 2);
            edit_mode.chat_text_view.text_view.grab_focus();
        } else {
            this.in_edit_mode = false;
        }
    }

    private void on_updated_item(ContentItem content_item) {
        if (this.content_item.id == content_item.id) {
            this.content_item = content_item;
            message_item = content_item as MessageItem;
            update_label();
        }
    }

    public static bool on_label_activate_link(string uri) {
        // Always handle xmpp URIs with Dino
        if (!uri.has_prefix("xmpp:")) return false;
        File file = File.new_for_uri(uri);
        Dino.Application.get_default().open(new File[]{file}, "");
        return true;
    }

    public override void dispose() {
        stream_interactor.get_module(MessageCorrection.IDENTITY).received_correction.disconnect(on_updated_item);
        stream_interactor.get_module(MessageDeletion.IDENTITY).item_deleted.disconnect(on_updated_item);
        this.notify["in-edit-mode"].disconnect(on_in_edit_mode_changed);
        if (marked_notify_handler_id != -1) {
            this.disconnect(marked_notify_handler_id);
        }
        if (realize_id != -1) {
            label.disconnect(realize_id);
        }
        if (pending_timeout_id != -1) {
            Source.remove(pending_timeout_id);
        }
        if (label != null) {
            label.unparent();
            label.dispose();
            label = null;
        }
        base.dispose();
    }
}

[GtkTemplate (ui = "/im/dino/Dino/message_item_widget_edit_mode.ui")]
public class MessageItemEditMode : Box {

    public signal void cancelled();
    public signal void send();

    [GtkChild] public unowned MenuButton emoji_button;
    [GtkChild] public unowned ChatTextView chat_text_view;
    [GtkChild] public unowned Button cancel_button;
    [GtkChild] public unowned Button send_button;
    [GtkChild] public unowned Frame frame;

    construct {
        EmojiChooser chooser = new EmojiChooser();
        chooser.emoji_picked.connect((emoji) => {
            chat_text_view.text_view.buffer.insert_at_cursor(emoji, emoji.data.length);
        });
        emoji_button.set_popover(chooser);

        chat_text_view.text_view.buffer.changed.connect_after(on_text_view_changed);

        cancel_button.clicked.connect(() => cancelled());
        send_button.clicked.connect(() => send());
        chat_text_view.cancel_input.connect(() => cancelled());
        chat_text_view.send_text.connect(() => send());

        check_widget_leak(this);
    }

    private void on_text_view_changed() {
        send_button.sensitive = chat_text_view.text_view.buffer.text != "";
    }
}

    public enum CustomSpanType {
        GREYED_OUT
    }

    public class CustomSpan : Xep.MessageMarkup.Markup {
        public Gee.List<CustomSpanType> types { get; set; }
    }

}
