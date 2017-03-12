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
        return Manager.get_instance(plugin.app.stream_interaction).can_encrypt(conversation);
    }
}

}