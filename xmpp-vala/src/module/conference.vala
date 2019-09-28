namespace Xmpp {

public class Conference : Object {
    public virtual Jid jid { get; set; }
    public virtual bool autojoin { get; set; }
    public virtual string? nick { get; set; }
    public virtual string? name { get; set; }
    public virtual string? password { get; set; }

    public static bool equal_func(Conference a, Conference b) {
        return a.jid.equals(b.jid);
    }

    public static uint hash_func(Conference a) {
        return Jid.hash_func(a.jid);
    }
}

}
