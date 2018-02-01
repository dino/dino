using Gee;

using Xmpp;
using Xmpp;

namespace Dino.Plugins.OpenPgp {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "pgp");

    public HashMap<Jid, string> key_ids = new HashMap<Jid, string>(Jid.hash_bare_func, Jid.equals_bare_func);

    public string? get_key_id(Jid jid) { return key_ids[jid]; }

    public void set_key_id(Jid jid, string key) { key_ids[jid] = key; }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}