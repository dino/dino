using Xmpp;

namespace Dino.Plugins.Omemo {

public class EncryptionListEntry : Plugins.EncryptionListEntry, Object {
    private Plugin plugin;

    public EncryptionListEntry(Plugin plugin) {
        this.plugin = plugin;
    }

    public Entities.Encryption encryption { get {
        return Entities.Encryption.OMEMO;
    }}

    public string name { get {
        return "OMEMO";
    }}

    public void encryption_activated(Entities.Conversation conversation, Plugins.SetInputFieldStatus input_status_callback) {
        encryption_activated_async.begin(conversation, input_status_callback);
    }

    public async void encryption_activated_async(Entities.Conversation conversation, Plugins.SetInputFieldStatus input_status_callback) {
        MucManager muc_manager = plugin.app.stream_interactor.get_module(MucManager.IDENTITY);
        Manager omemo_manager = plugin.app.stream_interactor.get_module(Manager.IDENTITY);

        if (muc_manager.is_private_room(conversation.account, conversation.counterpart)) {
            foreach (Jid offline_member in muc_manager.get_offline_members(conversation.counterpart, conversation.account)) {
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
