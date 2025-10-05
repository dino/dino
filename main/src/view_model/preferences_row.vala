using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;

namespace Dino.Ui.ViewModel.PreferencesRow {
    public abstract class Any : Object {
        public string title { get; set; }

        public string? media_type { get; set; }
        public string? media_uri { get; set; }
    }

    public class Text : Any {
        public string text { get; set; }
    }

    public class Entry : Any {
        public signal void changed();
        public string text { get; set; }
    }

    public class PrivateText : Any {
        public signal void changed();
        public string text { get; set; }
    }

    public class Toggle : Any {
        public string subtitle { get; set; }
        public bool state { get; set; }
    }

    public class ComboBox : Any {
        public Gee.List<string> items = new ArrayList<string>();
        public int active_item { get; set; }
    }

    public class Button : Any {
        public signal void clicked();
        public string button_text { get; set; }
    }
}