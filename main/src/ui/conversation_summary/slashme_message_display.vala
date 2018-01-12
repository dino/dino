using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

public class SlashmeMessageDisplay : Plugins.MessageDisplayProvider, Object {
    public string id { get; set; default="slashme"; }
    public double priority { get; set; default=1; }

    public StreamInteractor stream_interactor;

    public SlashmeMessageDisplay(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool can_display(Entities.Message? message) {
        return message.body.has_prefix("/me");
    }

    public Plugins.MetaConversationItem? get_item(Entities.Message message, Conversation conversation) {
        return new MetaSlashmeItem(stream_interactor, message, conversation);
    }
}

public class MetaSlashmeItem : Plugins.MetaConversationItem {
    public override Jid? jid { get; set; }
    public override DateTime? sort_time { get; set; }
    public override DateTime? display_time { get; set; }
    public override Encryption? encryption { get; set; }

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private Message message;
    private TextTag nick_tag;
    private MessageTextView text_view;

    public MetaSlashmeItem(StreamInteractor stream_interactor, Message message, Conversation conversation) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.message = message;
        this.jid = message.from;
        this.sort_time = message.local_time;
        this.seccondary_sort_indicator = message.id + 0.0845;
        this.display_time = message.time;
        this.encryption = message.encryption;
    }

    public override bool can_merge { get; set; default=false; }
    public override bool requires_avatar { get; set; default=true; }
    public override bool requires_header { get; set; default=false; }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        text_view = new MessageTextView() { valign=Align.CENTER, vexpand=true, visible = true };

        string display_name = Util.get_message_display_name(stream_interactor, message, conversation.account);
        string color = Util.get_name_hex_color(stream_interactor, conversation.account, conversation.counterpart, Util.is_dark_theme(text_view));
        nick_tag = text_view.buffer.create_tag("nick", foreground: "#" + color);
        TextIter iter;
        text_view.buffer.get_start_iter(out iter);
        text_view.buffer.insert_with_tags(ref iter, display_name, display_name.length, nick_tag);
        text_view.add_text(message.body.substring(3));

        text_view.style_updated.connect(update_style);
        text_view.realize.connect(update_style);
        return text_view;
    }

    private void update_style() {
        string color = Util.get_name_hex_color(stream_interactor, conversation.account, message.real_jid ?? message.from, Util.is_dark_theme(text_view));
        nick_tag.foreground = "#" + color;
    }
}

}
