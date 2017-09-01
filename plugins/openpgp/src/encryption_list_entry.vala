using Dino.Entities;

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
        string? key_id = stream_interactor.get_module(Manager.IDENTITY).get_key_id(conversation.account, conversation.counterpart);
        return key_id != null && GPGHelper.get_keylist(key_id).size > 0;
    }
}

}
