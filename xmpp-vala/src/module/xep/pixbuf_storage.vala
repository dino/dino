using Gdk;

namespace Xmpp.Xep {
public interface PixbufStorage : Object {
    public abstract void store(string id, Bytes data);
    public abstract bool has_image(string id);
    public abstract Pixbuf? get_image(string id);
}
}
