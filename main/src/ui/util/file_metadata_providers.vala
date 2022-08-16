using Xmpp;
using Gdk;

class ImageFileMetadataProvider: Dino.FileMetadataProvider, Object {
    public bool supports_file(File file) {
        return file.query_info("*", FileQueryInfoFlags.NONE).get_content_type().has_prefix("image");
    }

    public async void fill_metadata(File file, Xep.FileMetadataElement.FileMetadata metadata) {
        Pixbuf pixbuf = new Pixbuf.from_stream(yield file.read_async());
        metadata.width = pixbuf.get_width();
        metadata.height = pixbuf.get_height();
    }
}