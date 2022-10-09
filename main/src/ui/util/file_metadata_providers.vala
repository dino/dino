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
        MediaFile media = MediaFile.for_file(file);
        media.notify["prepared"].connect((object, pspec) => {
            Idle.add(fill_metadata.callback);
        });
        yield;
        metadata.length = media.duration / 1000;
    }
}

}