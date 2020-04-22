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

    [GtkChild] public Frame frame;
    [GtkChild] public ChatTextView chat_text_view;
    [GtkChild] public Box outer_box;
    [GtkChild] public Button file_button;
    [GtkChild] public Separator file_separator;
    [GtkChild] public Label chat_input_status;

    public EncryptionButton encryption_widget;

    public View init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        encryption_widget = new EncryptionButton(stream_interactor) { relief=ReliefStyle.NONE, margin_top=3, valign=Align.START, visible=true };

        file_button.get_style_context().add_class("dino-attach-button");

        encryption_widget.get_style_context().add_class("dino-chatinput-button");

        // Emoji button for emoji picker (recents don't work < 3.22.19, category icons don't work <3.23.2)
        if (Gtk.get_major_version() >= 3 && Gtk.get_minor_version() >= 24) {
            MenuButton emoji_button = new MenuButton() { relief=ReliefStyle.NONE, margin_top=3, valign=Align.START, visible=true };
            emoji_button.get_style_context().add_class("flat");
            emoji_button.get_style_context().add_class("dino-chatinput-button");
            emoji_button.image = new Image.from_icon_name("dino-emoticon-symbolic", IconSize.BUTTON) { visible=true };

            EmojiChooser chooser = new EmojiChooser();
            chooser.emoji_picked.connect((emoji) => {
                chat_text_view.text_view.buffer.insert_at_cursor(emoji, emoji.data.length);
            });
            emoji_button.set_popover(chooser);

            outer_box.add(emoji_button);
        }

        outer_box.add(encryption_widget);

        Util.force_css(frame, "* { border-radius: 3px; }");

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

        chat_text_view.text_view.grab_focus();
    }

    public void set_input_state(Plugins.InputFieldStatus.MessageType message_type) {
        switch (message_type) {
            case Plugins.InputFieldStatus.MessageType.NONE:
                this.get_style_context().remove_class("dino-input-warning");
                this.get_style_context().remove_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.INFO:
                this.get_style_context().remove_class("dino-input-warning");
                this.get_style_context().remove_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.WARNING:
                this.get_style_context().add_class("dino-input-warning");
                this.get_style_context().remove_class("dino-input-error");
                break;
            case Plugins.InputFieldStatus.MessageType.ERROR:
                this.get_style_context().remove_class("dino-input-warning");
                this.get_style_context().add_class("dino-input-error");
                break;
        }
    }

    public void highlight_state_description() {
        chat_input_status.get_style_context().add_class("input-status-highlight-once");
        Timeout.add_seconds(1, () => {
            chat_input_status.get_style_context().remove_class("input-status-highlight-once");
            return false;
        });
    }
}

}
