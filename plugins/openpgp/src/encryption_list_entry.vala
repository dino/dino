using Gee;

using Dino.Entities;
using Xmpp;

namespace Dino.Plugins.OpenPgp {

private class EncryptionListEntry : Plugins.EncryptionListEntry, Object {

    private StreamInteractor stream_interactor;

    public EncryptionListEntry(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public Entities.Encryption encryption { get {
        return Encryption.PGP;
    }}

    public string name { get {
        return "OpenPGP";
    }}

    public bool can_encrypt(Entities.Conversation conversation) {
        if (conversation.type_ == Conversation.Type.CHAT) {
            string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, conversation.counterpart);
            try {
                return key_id != null && GPGHelper.get_keylist(key_id).size > 0;
            } catch (Error e) { return false; }
        } else if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            Gee.List<Jid> muc_jids = new Gee.ArrayList<Jid>();
            Gee.List<Jid>? occupants = stream_interactor.get_module(MucManager.IDENTITY).get_occupants(conversation.counterpart, conversation.account);
            if (occupants != null) muc_jids.add_all(occupants);
            Gee.List<Jid>? offline_members = stream_interactor.get_module(MucManager.IDENTITY).get_offline_members(conversation.counterpart, conversation.account);
            if (occupants != null) muc_jids.add_all(offline_members);

            foreach (Jid jid in muc_jids) {
                string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, jid);
                if (key_id == null) return false;
            }
            return true;
        }
        return false;
    }
}

}
