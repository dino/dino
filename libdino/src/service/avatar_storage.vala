using Gdk;

using Xmpp;

namespace Dino {
public class AvatarStorage : Xep.PixbufStorage, Object {

    string folder;

    public AvatarStorage(string folder) {
        this.folder = folder;
        DirUtils.create_with_parents(folder, 0700);
    }

    public void store(string id, uint8[] data) {
        File file = File.new_for_path(Path.build_filename(folder, id));
        try {
            if (file.query_exists()) file.delete(); //TODO y?
            DataOutputStream fos = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
            fos.write_async.begin(data);
        } catch (Error e) {
            // Ignore: we failed in storing, so we refuse to display later...
        }
    }

    public bool has_image(string id) {
        File file = File.new_for_path(Path.build_filename(folder, id));
        return file.query_exists();
    }

    public Pixbuf? get_image(string id) {
        try {
            return new Pixbuf.from_file(Path.build_filename(folder, id));
        } catch (Error e) {
            return null;
        }
    }
}
}
