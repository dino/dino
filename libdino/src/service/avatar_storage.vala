using Gdk;

using Xmpp;

namespace Dino {
public class AvatarStorage : Xep.PixbufStorage, Object {

    string folder;

    public AvatarStorage(string folder) {
        this.folder = folder;
        DirUtils.create_with_parents(folder, 0700);
    }

    public void store(string id, Bytes data) {
        File file = File.new_for_path(Path.build_filename(folder, id));
        try {
            if (file.query_exists()) file.delete(); //TODO y?
            DataOutputStream fos = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
            fos.write_bytes_async.begin(data);
        } catch (Error e) {
            // Ignore: we failed in storing, so we refuse to display later...
        }
    }

    public bool has_image(string id) {
        File file = File.new_for_path(Path.build_filename(folder, id));
        return file.query_exists();
    }

    public async Pixbuf? get_image(string id) {
        try {
            File file = File.new_for_path(Path.build_filename(folder, id));
            FileInputStream stream = yield file.read_async();

            uint8 fbuf[100];
            size_t size;

            Checksum checksum = new Checksum (ChecksumType.SHA1);
            while ((size = yield stream.read_async(fbuf)) > 0) {
                checksum.update(fbuf, size);
            }

            if (checksum.get_string() != id) {
                FileUtils.remove(file.get_path());
            }
            stream.seek(0, SeekType.SET);
            return yield new Pixbuf.from_stream_async(stream, null);
        } catch (Error e) {
            return null;
        }
    }
}
}
