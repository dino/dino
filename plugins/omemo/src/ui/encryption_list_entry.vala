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

    public bool can_encrypt(Entities.Conversation conversation) {
        return plugin.app.stream_interactor.get_module(Manager.IDENTITY).can_encrypt(conversation);
    }
}

}
