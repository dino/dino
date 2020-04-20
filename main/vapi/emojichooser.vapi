namespace Dino {
    [CCode (cheader_filename = "emojichooser.h")]
    class EmojiChooser : Gtk.Popover {
        public signal void emoji_picked(string text);
        public EmojiChooser();
    }
}
