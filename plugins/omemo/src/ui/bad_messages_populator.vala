using Gee;
using Gtk;
using Qlite;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.Omemo {

public enum BadnessType {
    UNTRUSTED,
    UNDECRYPTABLE
}

public class BadMessagesPopulator : Plugins.ConversationItemPopulator, Plugins.ConversationAdditionPopulator, Object {

    public string id { get { return "bad_omemo_messages"; } }

    private StreamInteractor stream_interactor;
    private Plugin plugin;
    private Database db;

    private Conversation? current_conversation;
    private Plugins.ConversationItemCollection? item_collection;

    private Gee.List<BadMessageItem> bad_items = new ArrayList<BadMessageItem>();

    public BadMessagesPopulator(StreamInteractor stream_interactor, Plugin plugin) {
        this.stream_interactor = stream_interactor;
        this.plugin = plugin;
        this.db = plugin.db;

        plugin.trust_manager.bad_message_state_updated.connect((account, jid, device_id) => {
            clear_state();
            init_state();
        });
    }

    private void init_state() {
        var qry = db.identity_meta.select()
                .join_with(db.identity, db.identity.id, db.identity_meta.identity_id)
                .with(db.identity.account_id, "=", current_conversation.account.id)
                .with(db.identity_meta.address_name, "=", current_conversation.counterpart.to_string())
                .where("last_message_untrusted is not NULL OR last_message_undecryptable is not NULL");

        foreach (Row row in qry) {
            Jid jid = new Jid(row[db.identity_meta.address_name]);
            if (!db.identity_meta.last_message_untrusted.is_null(row)) {
                DateTime time = new DateTime.from_unix_utc(row[db.identity_meta.last_message_untrusted]);
                var item = new BadMessageItem(plugin, current_conversation.account, jid, time, BadnessType.UNTRUSTED);
                bad_items.add(item);
                item_collection.insert_item(item);
            }
            if (!db.identity_meta.last_message_undecryptable.is_null(row)) {
                DateTime time = new DateTime.from_unix_utc(row[db.identity_meta.last_message_undecryptable]);
                var item = new BadMessageItem(plugin, current_conversation.account, jid, time, BadnessType.UNDECRYPTABLE);
                bad_items.add(item);
                item_collection.insert_item(item);
            }
        }
    }

    private void clear_state() {
        foreach (BadMessageItem bad_item in bad_items) {
            item_collection.remove_item(bad_item);
        }
    }

    public void init(Conversation conversation, Plugins.ConversationItemCollection item_collection, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.item_collection = item_collection;

        init_state();
    }

    public void close(Conversation conversation) { }

    public void populate_timespan(Conversation conversation, DateTime after, DateTime before) { }
}

public class BadMessageItem : Plugins.MetaConversationItem {

    private Plugin plugin;
    private Account account;
    private DateTime date;
    private Jid problem_jid;
    private BadnessType badness_type;

    public BadMessageItem(Plugin plugin, Account account, Jid jid, DateTime date, BadnessType badness_type) {
        this.plugin = plugin;
        this.account = account;
        this.problem_jid = jid;
        this.date = date;
        this.sort_time = date;
        this.badness_type = badness_type;
    }

    public override Object? get_widget(Plugins.WidgetType widget_type) {
        return new BadMessagesWidget(plugin, account, problem_jid, badness_type);
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }
}

public class BadMessagesWidget : Box {
    public BadMessagesWidget(Plugin plugin, Account account, Jid jid, BadnessType badness_type) {
        Object(orientation:Orientation.HORIZONTAL, spacing:5);

        this.halign = Align.CENTER;
        this.visible = true;

        var sb = new StringBuilder();
        if (badness_type == BadnessType.UNTRUSTED) {
            sb.append("Your contact has been using an untrusted device. You won't see messages from devices that you do not trust.");
            sb.append(" <a href=\"\">%s</a>".printf("Manage devices"));
        } else {
            sb.append("Your contact does not trust this device. That means, you might be missing messages.");
        }
        Label label = new Label(sb.str) { margin_start=70, margin_end=70, justify=Justification.CENTER, use_markup=true, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, hexpand=true, visible=true };
        label.get_style_context().add_class("dim-label");
        this.add(label);

        label.activate_link.connect(() => {
            if (badness_type == BadnessType.UNTRUSTED) {
                ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, account, jid);
                dialog.set_transient_for((Window) get_toplevel());
                dialog.present();
            }

            return false;
        });
    }
}

}
