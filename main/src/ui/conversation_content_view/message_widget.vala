using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class MessageMetaItem : ContentMetaItem {

    private StreamInteractor stream_interactor;
    private MessageItemWidget message_item_widget;
    private MessageItem message_item;

    public MessageMetaItem(ContentItem content_item, StreamInteractor stream_interactor) {
        base(content_item);
        message_item = content_item as MessageItem;
        this.stream_interactor = stream_interactor;
    }

    public override Object? get_widget(Plugins.WidgetType type) {
        message_item_widget = new MessageItemWidget(stream_interactor, content_item) { visible=true };

        message_item_widget.edit_cancelled.connect(() => { this.in_edit_mode = false; });
        message_item_widget.edit_sent.connect(on_edit_send);

        stream_interactor.get_module(MessageCorrection.IDENTITY).received_correction.connect(on_received_correction);

        return message_item_widget;
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) {
        if (content_item as FileItem != null) return null;

        bool allowed = stream_interactor.get_module(MessageCorrection.IDENTITY).is_own_correction_allowed(message_item.conversation, message_item.message);
        Gee.List<Plugins.MessageAction> actions = new ArrayList<Plugins.MessageAction>();
        if (allowed && !in_edit_mode) {
            Plugins.MessageAction action1 = new Plugins.MessageAction();
            action1.icon_name = "document-edit-symbolic";
            action1.callback = (button, content_meta_item_activated, widget) => {
                message_item_widget.set_edit_mode();
                this.in_edit_mode = true;
            };
            actions.add(action1);
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
            message_item_widget.content_item = content_item;
            message_item_widget.update_label();
        }
    }
}

public class MessageItemWidget : SizeRequestBin {

    public signal void edit_cancelled();
    public signal void edit_sent(string text);

    StreamInteractor stream_interactor;
    public ContentItem content_item;

    Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, vexpand=true, visible=true };
    MessageItemEditMode? edit_mode = null;
    ChatTextViewController? controller = null;

    ulong realize_id = -1;
    ulong style_updated_id = -1;

    construct {
        this.add(label);
        this.size_request_mode = SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public MessageItemWidget(StreamInteractor stream_interactor, ContentItem content_item) {
        this.stream_interactor = stream_interactor;
        this.content_item = content_item;

        update_label();
    }

    public void set_edit_mode() {

        MessageItem message_item = content_item as MessageItem;
        Message message = message_item.message;

        if (edit_mode == null) {
            edit_mode = new MessageItemEditMode();
            controller = new ChatTextViewController(edit_mode.chat_text_view, stream_interactor);
            Conversation conversation = message_item.conversation;
            controller.initialize_for_conversation(conversation);

            edit_mode.cancelled.connect(() => {
                edit_cancelled();
                unset_edit_mode();
            });
            edit_mode.send.connect(() => {
                edit_sent(edit_mode.chat_text_view.text_view.buffer.text);
                unset_edit_mode();
            });
        }

        edit_mode.chat_text_view.text_view.buffer.text = message.body;

        this.remove(label);
        this.add(edit_mode);

        edit_mode.chat_text_view.text_view.grab_focus();
    }

    public void unset_edit_mode() {
        this.remove(edit_mode);
        this.add(label);
    }

    public void update_label() {
        label.label = generate_markup_text(content_item);
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
        if (message.body.has_prefix("/me")) {
            markup_text = markup_text.substring(3);
        }

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            markup_text = Util.parse_add_markup(markup_text, conversation.nickname, true, true);
        } else {
            markup_text = Util.parse_add_markup(markup_text, null, true, true);
        }

        if (message.body.has_prefix("/me")) {
            string display_name = Util.get_participant_display_name(stream_interactor, conversation, message.from);
            string color = Util.get_name_hex_color(stream_interactor, conversation.account, message.real_jid ?? message.from, Util.is_dark_theme(label));
            markup_text = @"<span color=\"#$(color)\">$(Markup.escape_text(display_name))</span>" + markup_text;
            theme_dependent = true;
        }

        int only_emoji_count = Util.get_only_emoji_count(markup_text);
        if (only_emoji_count != -1) {
            string size_str = only_emoji_count < 5 ? "xx-large" : "large";
            markup_text = @"<span size=\'$size_str\'>" + markup_text + "</span>";
        }

        if (message.edit_to != null) {
            string color = Util.is_dark_theme(label) ? "#808080" : "#909090";
            markup_text += " <span size='small' color='%s'>(%s)</span>".printf(color, _("edited"));
            theme_dependent = true;
        }

        if (theme_dependent && realize_id == -1) {
            realize_id = label.realize.connect(update_label);
            style_updated_id = label.style_updated.connect(update_label);
        } else if (!theme_dependent && realize_id != -1) {
            label.disconnect(realize_id);
            label.disconnect(style_updated_id);
        }
        return markup_text;
    }
}

[GtkTemplate (ui = "/im/dino/Dino/message_item_widget_edit_mode.ui")]
public class MessageItemEditMode : Box {

    public signal void cancelled();
    public signal void send();

    [GtkChild] public MenuButton emoji_button;
    [GtkChild] public ChatTextView chat_text_view;
    [GtkChild] public Button cancel_button;
    [GtkChild] public Button send_button;
    [GtkChild] public Frame frame;

    construct {
        Util.force_css(frame, "* { border-radius: 3px; }");

        EmojiChooser chooser = new EmojiChooser();
        chooser.emoji_picked.connect((emoji) => {
            chat_text_view.text_view.buffer.insert_at_cursor(emoji, emoji.data.length);
        });
        emoji_button.set_popover(chooser);

        cancel_button.clicked.connect(() => cancelled());
        send_button.clicked.connect(() => send());
        chat_text_view.cancel_input.connect(() => cancelled());
        chat_text_view.send_text.connect(() => send());

    }
}

}
