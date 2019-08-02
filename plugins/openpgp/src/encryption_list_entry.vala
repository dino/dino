using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.OpenPgp {

private class EncryptionListEntry : Plugins.EncryptionListEntry, Object {

    private StreamInteractor stream_interactor;
    private Database db;

    public EncryptionListEntry(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
    }

    public Entities.Encryption encryption { get {
        return Encryption.PGP;
    }}

    public string name { get {
        return "OpenPGP";
    }}

    public void encryption_activated(Entities.Conversation conversation, Plugins.SetInputFieldStatus input_status_callback) {
        try {
            GPGHelper.get_public_key(db.get_account_key(conversation.account) ?? "");
        } catch (Error e) {
            input_status_callback(new Plugins.InputFieldStatus("You didn't configure OpenPGP for this account. You can do that in the Accounts Dialog.", Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
            return;
        }

        if (conversation.type_ == Conversation.Type.CHAT) {
            string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, conversation.counterpart);
            if (key_id == null) {
                input_status_callback(new Plugins.InputFieldStatus("This contact does not support %s encryption.".printf("OpenPGP"), Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
                return;
            }
            try {
                GPGHelper.get_keylist(key_id);
            } catch (Error e) {
                input_status_callback(new Plugins.InputFieldStatus("This contact's OpenPGP key is not in your keyring.", Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
            }
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Gee.List<Jid> muc_jids = new Gee.ArrayList<Jid>();
            Gee.List<Jid>? occupants = stream_interactor.get_module(MucManager.IDENTITY).get_occupants(conversation.counterpart, conversation.account);
            if (occupants != null) muc_jids.add_all(occupants);
            Gee.List<Jid>? offline_members = stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(conversation.counterpart, conversation.account);
            if (offline_members != null) muc_jids.add_all(offline_members);

            foreach (Jid jid in muc_jids) {
                string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, jid);
                if (key_id == null) {
                    input_status_callback(new Plugins.InputFieldStatus("A member's OpenPGP key is not in your keyring: %s / %s.".printf(jid.to_string(), key_id), Plugins.InputFieldStatus.MessageType.ERROR, Plugins.InputFieldStatus.InputState.NO_SEND));
                    return;
                }
            }
        }
    }
}

}
