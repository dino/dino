using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class InURLRewriter : IncomingURLRewriter, Object {
    private Regex url_regex;

    public InURLRewriter () {
        this.url_regex = new Regex("""^aesgcm://(.*)#(([A-Fa-f0-9]{2}){48}|([A-Fa-f0-9]{2}){44})$""");
    }

    public string? rewrite(string url) {
      print("Should I rewrite URL?\n");
      MatchInfo info;
      if (this.url_regex.match(url, 0, out info)) {
        return "https://" + info.fetch(1);
      } else {
        return null;
      }
    }
}

}
