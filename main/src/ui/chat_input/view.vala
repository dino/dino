using Gdk;
using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ChatInput {

[GtkTemplate (ui = "/im/dino/Dino/chat_input.ui")]
public class View : Box {

    public signal void send_text();

    public string text {
        owned get { return text_input.buffer.text; }
        set { text_input.buffer.text = value; }
    }

    private StreamInteractor stream_interactor;
    private Conversation? conversation;
    private HashMap<Conversation, string> entry_cache = new HashMap<Conversation, string>(Conversation.hash_func, Conversation.equals_func);
    private int vscrollbar_min_height;

    public OccupantsTabCompletor occupants_tab_completor;
    private SmileyConverter smiley_converter;
    public EditHistory edit_history;

    [GtkChild] public Frame frame;
    [GtkChild] public ScrolledWindow scrolled;
    [GtkChild] public TextView text_input;
    [GtkChild] public Box outer_box;
    [GtkChild] public Button file_button;
    [GtkChild] public Separator file_separator;
    [GtkChild] public Label chat_input_status;

    public EncryptionButton encryption_widget;

    public View init(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        occupants_tab_completor = new OccupantsTabCompletor(stream_interactor, text_input);
        smiley_converter = new SmileyConverter(text_input);
        edit_history = new EditHistory(text_input, GLib.Application.get_default());
        encryption_widget = new EncryptionButton(stream_interactor) { relief=ReliefStyle.NONE, margin_top=3, valign=Align.START, visible=true };

        file_button.clicked.connect(() => {
            PreviewFileChooserNative chooser = new PreviewFileChooserNative("Select file", get_toplevel() as Gtk.Window, FileChooserAction.OPEN, "Select", "Cancel");
            if (chooser.run() == Gtk.ResponseType.ACCEPT) {
                string uri = chooser.get_filename();
                stream_interactor.get_module(FileManager.IDENTITY).send_file.begin(uri, conversation);
            }
        });
        file_button.get_style_context().add_class("dino-attach-button");

        scrolled.get_vscrollbar().get_preferred_height(out vscrollbar_min_height, null);
        scrolled.vadjustment.notify["upper"].connect_after(on_upper_notify);

        encryption_widget.get_style_context().add_class("dino-chatinput-button");
        encryption_widget.encryption_changed.connect(update_file_transfer_availability);

        // Emoji button for emoji picker (recents don't work < 3.22.19, category icons don't work <3.23.2)
        if (Gtk.get_major_version() >= 3 && Gtk.get_minor_version() >= 24) {
            MenuButton emoji_button = new MenuButton() { relief=ReliefStyle.NONE, margin_top=3, valign=Align.START, visible=true };
            emoji_button.get_style_context().add_class("flat");
            emoji_button.get_style_context().add_class("dino-chatinput-button");
            emoji_button.image = new Image.from_icon_name("dino-emoticon-symbolic", IconSize.BUTTON) { visible=true };

            EmojiChooser chooser = new EmojiChooser();
            chooser.emoji_picked.connect((emoji) => {
                text_input.buffer.insert_at_cursor(emoji, emoji.data.length);
            });
            emoji_button.set_popover(chooser);

            outer_box.add(emoji_button);
        }

        outer_box.add(encryption_widget);

        text_input.key_press_event.connect(on_text_input_key_press);

        Util.force_css(frame, "* { border-radius: 3px; }");

        return this;
    }

    private void update_file_transfer_availability() {
        bool upload_available = stream_interactor.get_module(FileManager.IDENTITY).is_upload_available(conversation);
        file_button.visible = upload_available;
        file_separator.visible = upload_available;
    }

    public void initialize_for_conversation(Conversation conversation) {
        if (this.conversation != null) entry_cache[this.conversation] = text_input.buffer.text;
        this.conversation = conversation;

        update_file_transfer_availability();

        text_input.buffer.text = "";
        if (entry_cache.has_key(conversation)) {
            text_input.buffer.text = entry_cache[conversation];
        }

        text_input.grab_focus();
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

    private bool on_text_input_key_press(EventKey event) {
        if (event.keyval in new uint[]{Key.Return, Key.KP_Enter}) {
            if ((event.state & ModifierType.SHIFT_MASK) > 0) {
                text_input.buffer.insert_at_cursor("\n", 1);
            } else if (this.text != "") {
                send_text();
                edit_history.reset_history();
            }
            return true;
        }
        return false;
    }

    private void on_upper_notify() {
        scrolled.vadjustment.value = scrolled.vadjustment.upper - scrolled.vadjustment.page_size;

        // hack for vscrollbar not requiring space and making textview higher //TODO doesn't resize immediately
        scrolled.get_vscrollbar().visible = (scrolled.vadjustment.upper > scrolled.max_content_height - 2 * vscrollbar_min_height);
    }
}

}
