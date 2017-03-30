namespace Xmpp.Xep.ServiceDiscovery {

public class Identity {
    public const string CATEGORY_CLIENT = "client";
    public const string CATEGORY_CONFERENCE = "conference";

    public string category { get; set; }
    public string type_ { get; set; }
    public string? name { get; set; }

    public Identity(string category, string type, string? name = null) {
        this.category = category;
        this.type_ = type;
        this.name = name;
    }
}

}