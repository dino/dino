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
        if (current_conversation == null) return;
        if (current_conversation.type_ == Conversation.Type.GROUPCHAT_PM) return;

        var qry = db.identity_meta.select()
            .join_with(db.identity, db.identity.id, db.identity_meta.identity_id)
            .with(db.identity.account_id, "=", current_conversation.account.id)
            .where("last_message_untrusted is not NULL OR last_message_undecryptable is not NULL");

        switch (current_conversation.type_) {
            case Conversation.Type.CHAT:
                qry.with(db.identity_meta.address_name, "=", current_conversation.counterpart.to_string());
                break;
            case Conversation.Type.GROUPCHAT:
                bool is_private = stream_interactor.get_module(MucManager.IDENTITY).is_private_room(current_conversation.account, current_conversation.counterpart);
                if (!is_private) return;

                var list = stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(current_conversation.counterpart, current_conversation.account);
                if (list == null || list.is_empty) return;

                var selection = new StringBuilder();
                string[] selection_args = {};
                foreach (Jid jid in list) {
                    if (selection.len == 0) {
                        selection.append(@" ($(db.identity_meta.address_name) = ?");
                    } else {
                        selection.append(@" OR $(db.identity_meta.address_name) = ?");
                    }
                    selection_args += jid.to_string();
                }
                selection.append(")");
                qry.where(selection.str, selection_args);
                break;
            case Conversation.Type.GROUPCHAT_PM:
                break;
        }

        foreach (Row row in qry) {
            Jid jid = new Jid(row[db.identity_meta.address_name]);
            if (!db.identity_meta.last_message_untrusted.is_null(row)) {
                DateTime time = new DateTime.from_unix_utc(row[db.identity_meta.last_message_untrusted]);
                var item = new BadMessageItem(plugin, current_conversation, jid, time, BadnessType.UNTRUSTED);
                bad_items.add(item);
                item_collection.insert_item(item);
            }
            if (!db.identity_meta.last_message_undecryptable.is_null(row)) {
                DateTime time = new DateTime.from_unix_utc(row[db.identity_meta.last_message_undecryptable]);
                var item = new BadMessageItem(plugin, current_conversation, jid, time, BadnessType.UNDECRYPTABLE);
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
    private Conversation conversation;
    private Jid problem_jid;
    private BadnessType badness_type;

    public BadMessageItem(Plugin plugin, Conversation conversation, Jid jid, DateTime date, BadnessType badness_type) {
        this.plugin = plugin;
        this.conversation = conversation;
        this.problem_jid = jid;
        this.time = date;
        this.badness_type = badness_type;
    }

    public override Object? get_widget(Plugins.ConversationItemWidgetInterface outer, Plugins.WidgetType widget_type) {
        return new BadMessagesWidget(plugin, conversation, problem_jid, badness_type);
    }

    public override Gee.List<Plugins.MessageAction>? get_item_actions(Plugins.WidgetType type) { return null; }
}

public class BadMessagesWidget : Box {
    public BadMessagesWidget(Plugin plugin, Conversation conversation, Jid jid, BadnessType badness_type) {
        Object(orientation:Orientation.HORIZONTAL, spacing:5);

        this.halign = Align.CENTER;
        this.visible = true;

        string who = "";
        if (conversation.type_ == Conversation.Type.CHAT) {
            who = Dino.get_participant_display_name(plugin.app.stream_interactor, conversation, jid);
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            who = jid.to_string();
            // `jid` is a real JID. In MUCs, try to show nicks instead (given that the JID is currently online)
            var occupants = plugin.app.stream_interactor.get_module(MucManager.IDENTITY).get_occupants(conversation.counterpart, conversation.account);
            if (occupants == null) return;
            foreach (Jid occupant in occupants) {
                if (jid.equals_bare(plugin.app.stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(occupant, conversation.account))) {
                    who = occupant.resourcepart;
                }
            }
        }

        string warning_text = "";
        if (badness_type == BadnessType.UNTRUSTED) {
            warning_text = _("%s has been using an untrusted device. You won't see messages from devices that you do not trust.").printf(who) +
                    " <a href=\"\">%s</a>".printf(_("Manage devices"));
        } else {
            warning_text += _("%s does not trust this device. That means, you might be missing messages.").printf(who);
        }
        Label label = new Label(warning_text) { margin_start=70, margin_end=70, justify=Justification.CENTER, use_markup=true, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, hexpand=true };
        label.add_css_class("dim-label");
        this.append(label);

        label.activate_link.connect(() => {
            if (badness_type == BadnessType.UNTRUSTED) {
                ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, conversation.account, jid);
                dialog.set_transient_for((Window) get_root());
                dialog.present();
            }

            return false;
        });
    }
}

}
