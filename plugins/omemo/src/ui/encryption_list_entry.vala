using Dino.Entities;
using Gtk;
using Qlite;
using Xmpp;

namespace Dino.Plugins.Omemo {

public class EncryptionListEntry : Plugins.EncryptionListEntry, Object {
    private Plugin plugin;
    private Database db;

    public EncryptionListEntry(Plugin plugin) {
        this.plugin = plugin;
        this.db = plugin.db;
    }

    public Entities.Encryption encryption { get {
        return Entities.Encryption.OMEMO;
    }}

    public string name { get {
        return "OMEMO";
    }}

    public Object? get_encryption_icon(Entities.Conversation conversation, ContentItem content_item) {
        return null;
    }

    public string? get_encryption_icon_name(Entities.Conversation conversation, ContentItem content_item) {
        if (content_item.encryption != encryption) return null;

        RowOption row = db.content_item_meta.select( { db.identity_meta.trust_level } ).with(db.content_item_meta.content_item_id, "=", content_item.id)
            .join_on(db.identity_meta, @"$(db.identity_meta.address_name)=$(db.content_item_meta.address_name) AND $(db.identity_meta.device_id)=$(db.content_item_meta.device_id)")
            .single().row();


        if (row.is_present() && (TrustLevel) row[db.identity_meta.trust_level] == TrustLevel.VERIFIED) {
            return "dino-security-high-symbolic";
        }
        return null;
    }

    public void encryption_activated(Entities.Conversation conversation, Plugins.SetInputFieldStatus input_status_callback) {
        encryption_activated_async.begin(conversation, input_status_callback);
    }

    public async void encryption_activated_async(Entities.Conversation conversation, Plugins.SetInputFieldStatus input_status_callback) {
        if (conversation.type_ == Conversation.Type.GROUPCHAT_PM) {
            input_status_callback(new Plugins.InputFieldStatus("Can't use encryption in a groupchat private message.", Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
            return;
        }
        MucManager muc_manager = plugin.app.stream_interactor.get_module(MucManager.IDENTITY);
        Manager omemo_manager = plugin.app.stream_interactor.get_module(Manager.IDENTITY);

        if (muc_manager.is_private_room(conversation.account, conversation.counterpart)) {
            var offline_members = muc_manager.get_offline_members(conversation.counterpart, conversation.account);
            if (offline_members == null) {
                // We don't store offline members yet, and it'll be null if we're offline
                return;
            }
            foreach (Jid offline_member in offline_members) {
                bool ok = yield omemo_manager.ensure_get_keys_for_jid(conversation.account, offline_member);
                if (!ok) {
                    input_status_callback(new Plugins.InputFieldStatus("A member does not support OMEMO: %s".printf(offline_member.to_string()), Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
                    return;
                }
            }
            return;
        }

        if (!(yield omemo_manager.ensure_get_keys_for_jid(conversation.account, conversation.counterpart.bare_jid))) {
            input_status_callback(new Plugins.InputFieldStatus("This contact does not support %s encryption".printf("OMEMO"), Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
        }
    }

}
}
