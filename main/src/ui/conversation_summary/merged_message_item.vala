using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class MergedMessageItem : MessageItem {

    private Label name_label = new Label("") { xalign=0, visible=true, hexpand=true };
    private MessageTextView textview = new MessageTextView() { visible=true };

    public MergedMessageItem(StreamInteractor stream_interactor, Conversation conversation, Message message) {
        base(stream_interactor, conversation, message);
        set_main_widget(textview);
        set_title_widget(name_label);

        add_message(message);
        string display_name = Util.get_message_display_name(stream_interactor, message, conversation.account);
        name_label.set_markup(@"<span foreground=\"#$(Util.get_name_hex_color(display_name, false))\">$display_name</span>");

        textview.style_updated.connect(update_display_style);
        update_display_style();
    }

    public override void add_message(Message message) {
        base.add_message(message);
        if (messages.size > 1) textview.add_text("\n");
        textview.add_text(message.body);
    }

    public override bool merge(Message message) {
        if (get_message_kind(message) == MessageKind.TEXT &&
                this.from.equals(message.from) &&
                this.messages[0].encryption == message.encryption &&
                message.time.difference(initial_time) < TimeSpan.MINUTE &&
                this.messages[0].marked != Entities.Message.Marked.WONTSEND) {
            add_message(message);
            return true;
        }
        return false;

    }

    private void update_display_style() {
        string display_name = Util.get_message_display_name(stream_interactor, messages[0], conversation.account);
        name_label.set_markup(@"<span foreground=\"#$(Util.get_name_hex_color(display_name, Util.is_dark_theme(textview)))\">$display_name</span>");
    }
}

}
