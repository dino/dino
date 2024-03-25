using Gee;
using Gtk;

using Dino.Entities;

using Xmpp;

namespace Dino.Ui.ContactDetails {

public class HistoryProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "history_settings"; } }

    private StreamInteractor stream_interactor;

    private HashMap<Account, HashMap<Jid, Cancellable>> sync_cancellables = new HashMap<Account, HashMap<Jid, Cancellable>>(Account.hash_func, Account.equals_func);

    public HistoryProvider(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, Plugins.WidgetType type) {
        if (type != Plugins.WidgetType.GTK4) return;

        EntityInfo entity_info = stream_interactor.get_module(EntityInfo.IDENTITY);

        string RESYNC_LABEL = _("Resync");
        string RESYNC_DESC_LABEL = _("Fetch a complete MAM history for this chat");
        entity_info.has_feature.begin(conversation.account, conversation.counterpart, Xmpp.MessageArchiveManagement.NS_URI, (_, res) => {
            bool can_do_mam = entity_info.has_feature.end(res);
            if (can_do_mam) {

                Button resync_button = new Button.with_label(RESYNC_LABEL);
                Stack resync_stack = new Stack();
                Gtk.Spinner spinner = new Gtk.Spinner();

                resync_stack.visible = true;
                contact_details.add("Permissions", RESYNC_DESC_LABEL, "", resync_stack);
                resync_stack.add_child(spinner);
                resync_stack.add_child(resync_button);
                resync_stack.set_visible_child(resync_button);

                resync_button.clicked.connect(() => {
                    resync_stack.set_visible_child(spinner);
                    spinner.start();

                    if (!sync_cancellables.has_key(conversation.account)) {
                        sync_cancellables[conversation.account] = new HashMap<Jid, Cancellable>();
                    }

                    if (!sync_cancellables[conversation.account].has_key(conversation.counterpart.bare_jid)) {
                        sync_cancellables[conversation.account][conversation.counterpart.bare_jid] = new Cancellable();
                        var history_sync = stream_interactor.get_module(MessageProcessor.IDENTITY).history_sync;
                        history_sync.fetch_history.begin(conversation.account, conversation.counterpart.bare_jid, sync_cancellables[conversation.account][conversation.counterpart.bare_jid], (_, res) => {
                            history_sync.fetch_everything.end(res);
                            spinner.stop();
                            resync_stack.set_visible_child(resync_button);
                            sync_cancellables[conversation.account].unset(conversation.counterpart.bare_jid);
                        });
                    }
                });
            }
        });
    }
}

}