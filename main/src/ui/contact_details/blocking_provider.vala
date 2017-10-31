using Gtk;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

public class BlockingProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "blocking"; } }

    private StreamInteractor stream_interactor;

    public BlockingProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK) return;
        if (conversation.type_ != Conversation.Type.CHAT) return;

        if (stream_interactor.get_module(BlockingManager.IDENTITY).is_supported(conversation.account)) {
            bool is_blocked = stream_interactor.get_module(BlockingManager.IDENTITY).is_blocked(conversation.account, conversation.counterpart);
            Switch sw = new Switch() { active=is_blocked, valign=Align.CENTER, visible=true };
            sw.state_set.connect((state) => {
                if (state) {
                    stream_interactor.get_module(BlockingManager.IDENTITY).block(conversation.account, conversation.counterpart);
                } else {
                    stream_interactor.get_module(BlockingManager.IDENTITY).unblock(conversation.account, conversation.counterpart);
                }
                return false;
            });
            contact_details.add(_("Settings"), _("Block"), _("Communication and status updates in either direction are blocked"), sw);
        }
    }
}

}
