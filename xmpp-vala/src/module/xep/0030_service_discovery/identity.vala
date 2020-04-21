namespace Xmpp.Xep.ServiceDiscovery {

public class Identity {
    public const string CATEGORY_CLIENT = "client";
    public const string CATEGORY_CONFERENCE = "conference";

    public const string TYPE_PC = "pc";
    public const string TYPE_PHONE = "phone";
    public const string TYPE_TABLET = "tablet";

    public string category { get; set; }
    public string type_ { get; set; }
    public string? name { get; set; }

    public Identity(string category, string type, string? name = null) {
        this.category = category;
        this.type_ = type;
        this.name = name;
    }

    public static uint hash_func(Identity a) {
        uint hash = a.category.hash() ^ a.type_.hash();
        if (a.name != null) {
            hash ^= a.name.hash();
        }
        return hash;
    }

    public static bool equals_func(Identity a, Identity b) {
        return a.category == b.category && a.type_ == b.type_ && a.name == b.name;
    }
}

}
