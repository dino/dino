using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gee;
using Gtk;

namespace Dino.Ui.ViewModel.PreferencesRow {
    public abstract class Any : Object {
        public string title { get; set; }
    }

    public class Text : Any {
        public string text { get; set; }
    }

    public class Entry : Any {
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

    public class WidgetDeprecated : Any {
        public Widget widget;
    }
}