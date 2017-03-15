using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

private class StatusItem : Grid {

    private Image image = new Image();
    private Label label = new Label("");

    private StreamInteractor stream_interactor;
    private Conversation conversation;

    public StatusItem(StreamInteractor stream_interactor, Conversation conversation, string? text) {
        Object(column_spacing : 7);
        set_hexpand(true);
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        image.set_from_pixbuf((new AvatarGenerator(30, 30)).set_greyscale(true).draw_conversation(stream_interactor, conversation));
        attach(image, 0, 0, 1, 1);
        attach(label, 1, 0, 1, 1);
        string display_name = Util.get_display_name(stream_interactor, conversation.counterpart, conversation.account);
        label.set_markup(@"<span foreground=\"#B1B1B1\">$(escape_text(display_name)) $text</span>");
        show_all();
    }
}

}