using Secret;

using Dino.Entities;

namespace Dino {

public class SecretManager {

    private string user;
    private string server;
    private static Secret.Schema schema = new Secret.Schema("org.gnome.keyring.NetworkPassword", Secret.SchemaFlags.NONE,
                                                            "user", Secret.SchemaAttributeType.STRING,
                                                            "server", Secret.SchemaAttributeType.STRING,
                                                            "protocol", Secret.SchemaAttributeType.STRING);

    public SecretManager(Jid jid) {
        user = jid.localpart;
        server = jid.domainpart;
    }

    public string? get_password() {
        try {
            return Secret.password_lookup_sync(schema, null,
                                               "user", user,
                                               "server", server,
                                               "protocol", "xmpp");
        } catch (GLib.Error e) {
            return null;
        }
    }

    public void set_password(string password) {
        try {
            Secret.password_store_sync(schema, Secret.COLLECTION_DEFAULT,
                                       "XMPP account " + user + "@" + server, password, null,
                                       "user", user,
                                       "server", server,
                                       "protocol", "xmpp");
        } catch (GLib.Error e) { }
    }
}

}
