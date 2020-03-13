using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ContentItemWidgetFactory : Object {

    private StreamInteractor stream_interactor;
    private HashMap<string, WidgetGenerator> generators = new HashMap<string, WidgetGenerator>();

    public ContentItemWidgetFactory(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        generators[MessageItem.TYPE] = new MessageItemWidgetGenerator(stream_interactor);
        generators[FileItem.TYPE] = new FileItemWidgetGenerator(stream_interactor);
    }

    public Widget? get_widget(ContentItem item) {
        WidgetGenerator? generator = generators[item.type_];
        if (generator != null) {
            return (Widget?) generator.get_widget(item);
        }
        return null;
    }

    public void register_widget_generator(WidgetGenerator generator) {
        generators[generator.handles_type] = generator;
    }
}

public interface WidgetGenerator : Object {
    public abstract string handles_type { get; set; }
    public abstract Object get_widget(ContentItem item);
}

public class MessageItemWidgetGenerator : WidgetGenerator, Object {

    public string handles_type { get; set; default=MessageItem.TYPE; }

    private StreamInteractor stream_interactor;

    public MessageItemWidgetGenerator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public Object get_widget(ContentItem item) {
        MessageItem message_item = item as MessageItem;
        Conversation conversation = message_item.conversation;
        Message message = message_item.message;

        Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, vexpand=true, visible=true };
        string markup_text = message.body;
        if (markup_text.length > 10000) {
            markup_text = markup_text.substring(0, 10000) + " [" + _("Message too long") + "]";
        }
        if (message_item.message.body.has_prefix("/me")) {
            markup_text = markup_text.substring(3);
        }

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            markup_text = Util.parse_add_markup(markup_text, conversation.nickname, true, true);
        } else {
            markup_text = Util.parse_add_markup(markup_text, null, true, true);
        }

        if (message_item.message.body.has_prefix("/me")) {
            string display_name = Util.get_participant_display_name(stream_interactor, conversation, message.from);
            update_me_style(stream_interactor, message.real_jid ?? message.from, display_name, conversation.account, label, markup_text);
            label.realize.connect(() => update_me_style(stream_interactor, message.real_jid ?? message.from, display_name, conversation.account, label, markup_text));
            label.style_updated.connect(() => update_me_style(stream_interactor, message.real_jid ?? message.from, display_name, conversation.account, label, markup_text));
        }

        int only_emoji_count = Util.get_only_emoji_count(markup_text);
        if (only_emoji_count != -1) {
            string size_str = only_emoji_count < 5 ? "xx-large" : "large";
            markup_text = @"<span size=\'$size_str\'>" + markup_text + "</span>";
        }

        label.label = markup_text;
        return label;
    }

    public static void update_me_style(StreamInteractor stream_interactor, Jid jid, string display_name, Account account, Label label, string action_text) {
        string color = Util.get_name_hex_color(stream_interactor, account, jid, Util.is_dark_theme(label));
        label.label = @"<span color=\"#$(color)\">$(Markup.escape_text(display_name))</span>" + action_text;
    }
}

public class FileItemWidgetGenerator : WidgetGenerator, Object {

    public StreamInteractor stream_interactor;
    public string handles_type { get; set; default=FileItem.TYPE; }

    private const int MAX_HEIGHT = 300;
    private const int MAX_WIDTH = 600;

    public FileItemWidgetGenerator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public Object get_widget(ContentItem item) {
        FileItem file_item = item as FileItem;
        FileTransfer transfer = file_item.file_transfer;

        return new FileWidget(stream_interactor, transfer) { visible=true };
    }
}

}
