using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ConversationSummary {

public class DefaultMessageDisplay : Plugins.MessageDisplayProvider, Object {
    public string id { get; set; default="default"; }
    public double priority { get; set; default=0; }

    public StreamInteractor stream_interactor;

    public DefaultMessageDisplay(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool can_display(Entities.Message? message) { return true; }

    public Plugins.MetaConversationItem? get_item(Entities.Message message, Conversation conversation) {
        return new MetaMessageItem(stream_interactor, message, conversation);
    }
}

public class MetaMessageItem : Plugins.MetaConversationItem {
    public override Jid? jid { get; set; }
    public override DateTime? sort_time { get; set; }
    public override DateTime? display_time { get; set; }
    public override Encryption? encryption { get; set; }

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private Message message;

    public MetaMessageItem(StreamInteractor stream_interactor, Message message, Conversation conversation) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;
        this.message = message;
        this.jid = message.from;
        this.sort_time = message.local_time;
        this.seccondary_sort_indicator = message.id + 0.2085;
        this.display_time = message.time;
        this.encryption = message.encryption;
    }

    public override bool can_merge { get; set; default=true; }
    public override bool requires_avatar { get; set; default=true; }
    public override bool requires_header { get; set; default=true; }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        MessageTextView text_view = new MessageTextView() { visible = true };
        text_view.add_text(message.body);
        return text_view;
    }
}

}
