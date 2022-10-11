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

    MessageItemEditMode? edit_mode = null;
    ChatTextViewController? controller = null;
    private bool supports_reaction = false;
    AdditionalInfo additional_info = AdditionalInfo.NONE;

    ulong realize_id = -1;
    ulong style_updated_id = -1;
    ulong marked_notify_handler_id = -1;

    public Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, hexpand=true, vexpand=true };

    public MessageMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
        base(content_item);
        message_item = content_item as MessageItem;
        this.stream_interactor = stream_interactor;

        init.begin();

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
                }
            });
        }

        update_label();
    }

    private async void init() {
        supports_reaction = yield stream_interactor.get_module(Reactions.IDENTITY).conversation_supports_reactions(message_item.conversation);
    }

    private string generate_markup_text(ContentItem item) {
        MessageItem message_item = item as MessageItem;
        Conversation conversation = message_item.conversation;
        Message message = message_item.message;

        bool theme_dependent = false;

        string markup_text = message.body;
        if (markup_text.length > 10000) {
            markup_text = markup_text.substring(0, 10000) + " [" + _("Message too long") + "]";
        }
        if (message.body.has_prefix("/me ")) {
            markup_text = markup_text.substring(4);
        }

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            markup_text = Util.parse_add_markup_theme(markup_text, conversation.nickname, true, true, true, Util.is_dark_theme(this.label), ref theme_dependent);
        } else {
            markup_text = Util.parse_add_markup_theme(markup_text, null, true, true, true, Util.is_dark_theme(this.label), ref theme_dependent);
        }

        if (message.body.has_prefix("/me ")) {
            string display_name = Util.get_participant_display_name(stream_interactor, conversation, message.from);
            markup_text = @"<i><b>$(Markup.escape_text(display_name))</b> " + markup_text + "</i>";
        }

        int only_emoji_count = Util.get_only_emoji_count(markup_text);
        if (only_emoji_count != -1) {
            string size_str = only_emoji_count < 5 ? "xx-large" : "large";
            markup_text = @"<span size=\'$size_str\'>" + markup_text + "</span>";
        }

        string dim_color = Util.is_dark_theme(this.label) ? "#BDBDBD" : "#707070";

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
                Timeout.add(10000 - time_diff, () => {
                    update_label();
                    return false;
                });
            }
        } else if (message.direction == Message.DIRECTION_SENT && message.marked == Message.Marked.ERROR) {
            // Append "delivery failed" if there was a server error
            string error_color = Util.rgba_to_hex(Util.get_label_pango_color(label, "@error_color"));
            markup_text += "  <span size='small' color='%s'>%s</span>".printf(error_color, _("delivery failed"));
            theme_dependent = true;
            additional_info = AdditionalInfo.DELIVERY_FAILED;
        }

        if (theme_dependent && realize_id == -1) {
            realize_id = label.realize.connect(update_label);
//            style_updated_id = label.style_updated.connect(update_label);
        } else if (!theme_dependent && realize_id != -1) {
            label.disconnect(realize_id);
            label.disconnect(style_updated_id);
        }
        return markup_text;
    }

    public void update_label() {
        label.label = generate_markup_text(content_item);
    }

    public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType type) {

        stream_interactor.get_module(MessageCorrection.IDENTITY).received_correction.connect(on_received_correction);

        this.notify["in-edit-mode"].connect(() => {
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
                    outer.set_widget(label, Plugins.WidgetType.GTK4);
                });
                edit_mode.send.connect(() => {
                    if (((MessageItem) content_item).message.body != edit_mode.chat_text_view.text_view.buffer.text) {
                        on_edit_send(edit_mode.chat_text_view.text_view.buffer.text);
                    } else {
//                        edit_cancelled();
                    }
                    in_edit_mode = false;
                    outer.set_widget(label, Plugins.WidgetType.GTK4);
                });

                edit_mode.chat_text_view.text_view.buffer.text = message.body;

                outer.set_widget(edit_mode, Plugins.WidgetType.GTK4);
                edit_mode.chat_text_view.text_view.grab_focus();
            } else {
                this.in_edit_mode = false;
            }
        });

        return label;
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) {
        if (content_item as FileItem != null || this.in_edit_mode) return null;
        if (in_edit_mode) return null;

        Gee.List<Plugins.MessageAction> actions = new ArrayList<Plugins.MessageAction>();

        bool correction_allowed = stream_interactor.get_module(MessageCorrection.IDENTITY).is_own_correction_allowed(message_item.conversation, message_item.message);
        if (correction_allowed) {
            Plugins.MessageAction action1 = new Plugins.MessageAction();
            action1.icon_name = "document-edit-symbolic";
            action1.callback = (button, content_meta_item_activated, widget) => {
                this.in_edit_mode = true;
            };
            actions.add(action1);
        }

        if (supports_reaction) {
            Plugins.MessageAction action2 = new Plugins.MessageAction();
            action2.icon_name = "dino-emoticon-add-symbolic";
            EmojiChooser chooser = new EmojiChooser();
            chooser.emoji_picked.connect((emoji) => {
                stream_interactor.get_module(Reactions.IDENTITY).add_reaction(message_item.conversation, message_item, emoji);
            });
            action2.popover = chooser;
            actions.add(action2);
        }
        return actions;
    }

    private void on_edit_send(string text) {
        stream_interactor.get_module(MessageCorrection.IDENTITY).send_correction(message_item.conversation, message_item.message, text);
        this.in_edit_mode = false;
    }

    private void on_received_correction(ContentItem content_item) {
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
        Util.force_css(frame, "* { border-radius: 3px; padding: 0px 7px; }");

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
    }

    private void on_text_view_changed() {
        send_button.sensitive = chat_text_view.text_view.buffer.text != "";
    }
}

}
