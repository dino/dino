using Gee;

using Xmpp;
using Xmpp.Core;

namespace Dino.Plugins.OpenPgp {

public class Flag : XmppStreamFlag {
    public static FlagIdentity<Flag> IDENTITY = new FlagIdentity<Flag>(NS_URI, "pgp");

    public HashMap<string, string> key_ids = new HashMap<string, string>();

    public string? get_key_id(string jid) { return key_ids[get_bare_jid(jid)]; }

    public void set_key_id(string jid, string key) { key_ids[get_bare_jid(jid)] = key; }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return IDENTITY.id; }
}

}