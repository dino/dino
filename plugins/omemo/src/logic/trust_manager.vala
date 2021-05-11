using Dino.Entities;
using Gee;
using Xmpp;
using Signal;
using Qlite;

namespace Dino.Plugins.Omemo {

public class TrustManager {

    public signal void bad_message_state_updated(Account account, Jid jid, int device_id);

    private StreamInteractor stream_interactor;
    private Database db;
    private TagMessageListener tag_message_listener;

    public HashMap<Message, int> message_device_id_map = new HashMap<Message, int>(Message.hash_func, Message.equals_func);

    public TrustManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        tag_message_listener = new TagMessageListener(stream_interactor, this, db, message_device_id_map);
        stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(tag_message_listener);
    }

    public void set_blind_trust(Account account, Jid jid, bool blind_trust) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return;
        db.trust.update()
            .with(db.trust.identity_id, "=", identity_id)
            .with(db.trust.address_name, "=", jid.bare_jid.to_string())
            .set(db.trust.blind_trust, blind_trust).perform();
    }

    public void set_device_trust(Account account, Jid jid, int device_id, TrustLevel trust_level) {
        int identity_id = db.identity.get_id(account.id);
        db.identity_meta.update()
            .with(db.identity_meta.identity_id, "=", identity_id)
            .with(db.identity_meta.address_name, "=", jid.bare_jid.to_string())
            .with(db.identity_meta.device_id, "=", device_id)
            .set(db.identity_meta.trust_level, trust_level).perform();

        // Hide messages from untrusted or unknown devices
        string selection = null;
        string[] selection_args = {};
        var app_db = Application.get_default().db;
        foreach (Row row in db.content_item_meta.with_device(identity_id, jid.bare_jid.to_string(), device_id).with(db.content_item_meta.trusted_when_received, "=", false)) {
            if (selection == null) {
                selection = @"$(app_db.content_item.id) = ?";
            } else {
                selection += @" OR $(app_db.content_item.id) = ?";
            }
            selection_args += row[db.content_item_meta.content_item_id].to_string();
        }
        if (selection != null) {
            app_db.content_item.update()
                .set(app_db.content_item.hide, trust_level == TrustLevel.UNTRUSTED || trust_level == TrustLevel.UNKNOWN)
                .where(selection, selection_args)
                .perform();
        }

        if (trust_level == TrustLevel.TRUSTED) {
            db.identity_meta.update_last_message_untrusted(identity_id, device_id, null);
            bad_message_state_updated(account, jid, device_id);
        }
    }

    public bool is_known_address(Account account, Jid jid) {
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return false;
        return db.identity_meta.with_address(identity_id, jid.to_string()).with(db.identity_meta.last_active, ">", 0).count() > 0;
    }

    public Gee.List<int32> get_trusted_devices(Account account, Jid jid) {
        Gee.List<int32> devices = new ArrayList<int32>();
        int identity_id = db.identity.get_id(account.id);
        if (identity_id < 0) return devices;
        foreach (Row device in db.identity_meta.get_trusted_devices(identity_id, jid.bare_jid.to_string())) {
            if(device[db.identity_meta.trust_level] != TrustLevel.UNKNOWN || device[db.identity_meta.identity_key_public_base64] == null)
                devices.add(device[db.identity_meta.device_id]);
        }
        return devices;
    }

    private class TagMessageListener : MessageListener {
        public string[] after_actions_const = new string[]{ "STORE" };
        public override string action_group { get { return "DECRYPT_TAG"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        private StreamInteractor stream_interactor;
        private TrustManager trust_manager;
        private Database db;
        private HashMap<Message, int> message_device_id_map;

        public TagMessageListener(StreamInteractor stream_interactor, TrustManager trust_manager, Database db, HashMap<Message, int> message_device_id_map) {
            this.stream_interactor = stream_interactor;
            this.trust_manager = trust_manager;
            this.db = db;
            this.message_device_id_map = message_device_id_map;
        }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            int device_id = 0;
            if (message_device_id_map.has_key(message)) {
                device_id = message_device_id_map[message];
                message_device_id_map.unset(message);
            }

            // TODO: Handling of files

            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_item(conversation, 1, message.id);

            if (content_item != null && device_id != 0) {
                Jid jid = content_item.jid;
                if (conversation.type_ == Conversation.Type.GROUPCHAT) {
                    jid = message.real_jid;
                }

                int identity_id = db.identity.get_id(conversation.account.id);
                TrustLevel trust_level = (TrustLevel) db.identity_meta.get_device(identity_id, jid.bare_jid.to_string(), device_id)[db.identity_meta.trust_level];
                if (trust_level == TrustLevel.UNTRUSTED || trust_level == TrustLevel.UNKNOWN) {
                    stream_interactor.get_module(ContentItemStore.IDENTITY).set_item_hide(content_item, true);
                    db.identity_meta.update_last_message_untrusted(identity_id, device_id, message.time);
                    trust_manager.bad_message_state_updated(conversation.account, jid, device_id);
                }

                db.content_item_meta.insert()
                    .value(db.content_item_meta.content_item_id, content_item.id)
                    .value(db.content_item_meta.identity_id, identity_id)
                    .value(db.content_item_meta.address_name, jid.bare_jid.to_string())
                    .value(db.content_item_meta.device_id, device_id)
                    .value(db.content_item_meta.trusted_when_received, trust_level != TrustLevel.UNTRUSTED)
                    .perform();
            }
            return false;
        }
    }
}

}
