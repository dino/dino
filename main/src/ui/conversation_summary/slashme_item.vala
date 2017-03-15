using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class SlashMeItem : MessageItem {

    private Box box = new Box(Orientation.VERTICAL, 0) { visible=true, vexpand=true };
    private MessageTextView textview = new MessageTextView() { visible=true };
    private string text;
    private TextTag nick_tag;

    public SlashMeItem(StreamInteractor stream_interactor, Conversation conversation, Message message) {
        base(stream_interactor, conversation, message);
        box.set_center_widget(textview);
        set_title_widget(box);
        text = message.body.substring(3);

        string display_name = Util.get_message_display_name(stream_interactor, message, conversation.account);
        nick_tag = textview.buffer.create_tag("nick", foreground: @"#$(Util.get_name_hex_color(display_name, false))");
        TextIter iter;
        textview.buffer.get_start_iter(out iter);
        textview.buffer.insert_with_tags(ref iter, display_name, display_name.length, nick_tag);
        textview.add_text(text);
        add_message(message);

        textview.style_updated.connect(update_display_style);
        update_display_style();
    }

    public override bool merge(Message message) {
        return false;
    }

    private void update_display_style() {
        string display_name = Util.get_message_display_name(stream_interactor, messages[0], conversation.account);
        nick_tag.foreground = @"#$(Util.get_name_hex_color(display_name, Util.is_dark_theme(textview)))";
    }
}

}
