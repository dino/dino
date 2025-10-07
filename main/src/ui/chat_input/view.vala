using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ChatInput {

[GtkTemplate (ui = "/im/dino/Dino/chat_input.ui")]
public class View : Box {

    public string text {
        owned get { return chat_text_view.text_view.buffer.text; }
        set { chat_text_view.text_view.buffer.text = value; }
    }

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private HashMap<Conversation, string> entry_cache = new HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);

    [GtkChild] public unowned Box quote_box;
    [GtkChild] public unowned ChatTextView chat_text_view;
    [GtkChild] public unowned Button file_button;
    [GtkChild] public unowned MenuButton emoji_button;
    [GtkChild] public unowned MenuButton encryption_button;
    [GtkChild] public unowned Separator file_separator;
    [GtkChild] public unowned Label chat_input_status;

    public EncryptionButton encryption_widget;

    public View init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        encryption_widget = new EncryptionButton(stream_interactor, encryption_button);

        EmojiChooser chooser = new EmojiChooser();
        chooser.emoji_picked.connect((emoji) => {
            chat_text_view.text_view.buffer.insert_at_cursor(emoji, emoji.data.length);
        });
        chooser.closed.connect(do_focus);

        emoji_button.set_popover(chooser);

        file_button.tooltip_text = Util.string_if_tooltips_active(_("Send a file"));

        return this;
    }

    public void set_file_upload_active(bool active) {
        file_button.visible = active;
        file_separator.visible = active;
    }

    public void initialize_for_conversation(Conversation conversation) {
        if (this.conversation != null) entry_cache[this.conversation] = chat_text_view.text_view.buffer.text;
        this.conversation = conversation;

        chat_text_view.text_view.buffer.text = "";
        if (entry_cache.has_key(conversation)) {
            chat_text_view.text_view.buffer.text = entry_cache[conversation];
        }

        do_focus();
    }

    public void set_input_state(Plugins.InputFieldStatus.MessageType message_type) {
        switch (message_type) {
            case Plugins.InputFieldStatus.MessageType.NONE:
                this.remove_css_class("dino-input-warning");
                this.remove_css_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.INFO:
                this.remove_css_class("dino-input-warning");
                this.remove_css_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.WARNING:
                this.add_css_class("dino-input-warning");
                this.remove_css_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.ERROR:
                this.remove_css_class("dino-input-warning");
                this.add_css_class("dino-input-error");
                break;
        }
    }

    public void highlight_state_description() {
        chat_input_status.add_css_class("input-status-highlight-once");
        Timeout.add(500, () => {
            chat_input_status.remove_css_class("input-status-highlight-once");
            return false;
        });
    }

    public void set_quoted_message(Widget quote_widget) {
        Widget? quote_box_child = quote_box.get_first_child();
        if (quote_box_child != null) quote_box.remove(quote_box_child);
        quote_box.append(quote_widget);
        quote_box.visible = true;
    }

    public void unset_quoted_message() {
        Widget? quote_box_child = quote_box.get_first_child();
        if (quote_box_child != null) quote_box.remove(quote_box_child);
        quote_box.visible = false;
    }

    public void do_focus() {
        chat_text_view.text_view.grab_focus();
    }
}

}
