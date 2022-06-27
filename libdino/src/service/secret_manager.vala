#if WITH_SECRET
using Secret;

using Xmpp;
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

    public async string? get_password() {
        try {
            return yield Secret.password_lookup(schema, null,
                                               "user", user,
                                               "server", server,
                                               "protocol", "xmpp");
        } catch (GLib.Error e) {
            return null;
        }
    }

    public async bool set_password(string password) {
        try {
            return yield Secret.password_store(schema, Secret.COLLECTION_DEFAULT,
                                       "XMPP account " + user + "@" + server, password, null,
                                       "user", user,
                                       "server", server,
                                       "protocol", "xmpp");
        } catch (GLib.Error e) {
            return false;
        }
    }
}

}
#endif
