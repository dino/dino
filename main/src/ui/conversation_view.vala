using Gee;
using Gdk;
using Gtk;

using Dino.Entities;

namespace Dino.Ui {

[GtkTemplate (ui = "/im/dino/Dino/conversation_view.ui")]
public class ConversationView : Widget {

    [GtkChild] public unowned Revealer goto_end_revealer;
    [GtkChild] public unowned Button goto_end_button;
    [GtkChild] public unowned ChatInput.View chat_input;
    [GtkChild] public unowned ConversationSummary.ConversationView conversation_frame;

    construct {
        this.layout_manager = new BinLayout();
    }

    public void open_save_file_dialog(FileTransfer file_transfer) {
        var save_dialog = new FileChooserNative(_("Save as…"), (Gtk.Window) this.get_root(), FileChooserAction.SAVE, null, null);
        save_dialog.set_modal(true);
        save_dialog.set_current_name(file_transfer.file_name);

        save_dialog.response.connect(() => {
            File? target_file = save_dialog.get_file();
            if (target_file == null) {
                warning("No file returned from save dialog.");
                return;
            }
            try {
                file_transfer.get_file().copy(save_dialog.get_file(), GLib.FileCopyFlags.OVERWRITE, null);
            } catch (Error err) {
                warning("Failed copy file %s - %s", file_transfer.get_file().get_uri(), err.message);
            }
        });

        save_dialog.show();
    }
}

}
