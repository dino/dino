using Gee;

namespace Dino.Entities {
public class Account : Object {

    public int id { get; set; }
    public string localpart { get { return bare_jid.localpart; } }
    public string domainpart { get { return bare_jid.domainpart; } }
    public string resourcepart { get; set; }
    public Jid bare_jid { get; private set; }
    public string? password { get; set; }
    public string display_name {
        owned get {
            if (alias != null) {
                return alias;
            } else {
                return bare_jid.to_string();
            }
        }
    }
    public string? alias { get; set; }
    public bool enabled { get; set; }

    public Account.from_bare_jid(string bare_jid) {
        this.bare_jid = new Jid(bare_jid);
    }

    public bool equals(Account acc) {
        return equals_func(this, acc);
    }

    public static bool equals_func(Account acc1, Account acc2) {
        return acc1.bare_jid.to_string() == acc2.bare_jid.to_string();
    }

    public static uint hash_func(Account acc) {
        return acc.bare_jid.to_string().hash();
    }
}
}