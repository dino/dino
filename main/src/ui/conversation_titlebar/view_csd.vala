using Gtk;
using Gee;

using Dino.Entities;

namespace Dino.Ui {

public class ConversationTitlebarCsd : Gtk.HeaderBar {

    private StreamInteractor stream_interactor;
    private Window window;
    private Conversation? conversation;

    public ConversationTitlebarCsd(StreamInteractor stream_interactor, Window window) {
        this.stream_interactor = stream_interactor;
        this.window = window;

        this.get_style_context().add_class("dino-right");
        show_close_button = true;
        hexpand = true;

        Application app = GLib.Application.get_default() as Application;
        ArrayList<Plugins.ConversationTitlebarWidget> widgets = new ArrayList<Plugins.ConversationTitlebarWidget>();
        foreach(var e in app.plugin_registry.conversation_titlebar_entries) {
            Plugins.ConversationTitlebarWidget widget = e.get_widget(Plugins.WidgetType.GTK);
            if (widget != null) {
                widgets.insert(0, widget);
            }
        }
        foreach (var w in widgets) {
            Button gtk_widget = (Gtk.Button)w;
            gtk_widget.relief = ReliefStyle.NONE;
            this.pack_end(gtk_widget);
        }
    }
}

}
