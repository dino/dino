using Gee;

using Xmpp;
using Xmpp.Core;

namespace Dino.Plugins.OpenPgp {

public class Flag : XmppStreamFlag {
    public const string ID = "pgp";
    public HashMap<string, string> key_ids = new HashMap<string, string>();

    public string? get_key_id(string jid) { return key_ids[get_bare_jid(jid)]; }

    public void set_key_id(string jid, string key) { key_ids[get_bare_jid(jid)] = key; }

    public static Flag? get_flag(XmppStream stream) { return (Flag?) stream.get_flag(NS_URI, ID); }

    public static bool has_flag(XmppStream stream) { return get_flag(stream) != null; }

    public override string get_ns() { return NS_URI; }

    public override string get_id() { return ID; }
}

}