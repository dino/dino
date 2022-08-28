using Dino.Entities;
using Xmpp;
using Xmpp.Xep;
using Gtk;

namespace Dino.Ui.Util {

public class AudioVideoFileMetadataProvider: Dino.FileMetadataProvider, Object {
    public bool supports_file(File file) {
        string? mime_type = file.query_info("*", FileQueryInfoFlags.NONE).get_content_type();
        if (mime_type == null) {
            return false;
        }
        return mime_type.has_prefix("audio") || mime_type.has_prefix("video");
    }

    public async void fill_metadata(File file, Xep.FileMetadataElement.FileMetadata metadata) {
        MediaFile media = MediaFile.for_input_stream(yield file.read_async());
        metadata.length = media.duration;
    }
}

}