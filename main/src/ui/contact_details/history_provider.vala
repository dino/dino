using Gee;
using Gtk;

using Dino.Entities;

using Xmpp;

namespace Dino.Ui.ContactDetails {

public class HistoryProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "history_settings"; } }

    private StreamInteractor stream_interactor;

    private string HISTORY = _("History");

    private HashMap<Account, HashMap<Jid, Cancellable>> sync_cancellables = new HashMap<Account, HashMap<Jid, Cancellable>>(Account.hash_func, Account.equals_func);

    public HistoryProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return;

        EntityInfo entity_info = stream_interactor.get_module(EntityInfo.IDENTITY);

        string FORCE_RESYNC_LABEL = _("Force resync");
        string FORCE_RESYNC_DESC_LABEL = _("Fetch a complete MAM history for this chat");
        entity_info.has_feature.begin(conversation.account, conversation.counterpart, Xmpp.MessageArchiveManagement.NS_URI_2, (_, res) => {
            bool can_do_mam = entity_info.has_feature.end(res);
            if (can_do_mam) {
                Button force_resync_button = new Button() { visible = true, valign = Align.CENTER, hexpand = true };
                force_resync_button.set_label(FORCE_RESYNC_LABEL);
                contact_details.add(HISTORY, FORCE_RESYNC_LABEL, FORCE_RESYNC_DESC_LABEL, force_resync_button);
                force_resync_button.clicked.connect(() => {
                    if (!sync_cancellables.has_key(conversation.account)) {
                        sync_cancellables[conversation.account] = new HashMap<Jid, Cancellable>();
                    }
                    if (!sync_cancellables[conversation.account].has_key(conversation.counterpart.bare_jid)) {
                        sync_cancellables[conversation.account][conversation.counterpart.bare_jid] = new Cancellable();
                        var history_sync = stream_interactor.get_module(MessageProcessor.IDENTITY).history_sync;
                        history_sync.fetch_everything.begin(conversation.account, null, conversation.counterpart.bare_jid, sync_cancellables[conversation.account][conversation.counterpart.bare_jid], new DateTime.from_unix_utc(0), true, (_, res) => {
                            history_sync.fetch_everything.end(res);
                            sync_cancellables[conversation.account].unset(conversation.counterpart.bare_jid);
                        });
                    }
                });
            }
        });
    }
}

}
