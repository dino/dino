using Gdk;
using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class AvatarManager : StreamInteractionModule, Object {
    public static ModuleIdentity<AvatarManager> IDENTITY = new ModuleIdentity<AvatarManager>("avatar_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void received_avatar(Pixbuf avatar, Jid jid, Account account);

    private enum Source {
        USER_AVATARS,
        VCARD
    }

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<Jid, string> user_avatars = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, string> vcard_avatars = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private AvatarStorage avatar_storage = new AvatarStorage(get_storage_dir());
    private HashMap<string, Pixbuf> cached_pixbuf = new HashMap<string, Pixbuf>();
    private const int MAX_PIXEL = 192;

    public static void start(StreamInteractor stream_interactor, Database db) {
        AvatarManager m = new AvatarManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    public static string get_storage_dir() {
        return Path.build_filename(Dino.get_storage_dir(), "avatars");
    }

    private AvatarManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.module_manager.initialize_account_modules.connect(initialize_avatar_modules);
    }

    private void initialize_avatar_modules(Account account, ArrayList<XmppStreamModule> modules) {
        modules.add(new Xep.UserAvatars.Module(avatar_storage));
        modules.add(new Xep.VCard.Module(avatar_storage));
    }

    private Pixbuf? get_avatar_by_hash(string hash) {
        if (cached_pixbuf.has_key(hash)) {
            return cached_pixbuf[hash];
        }
        Pixbuf? image = avatar_storage.get_image(hash);
        if (image != null) {
            cached_pixbuf[hash] = image;
        }
        return image;
    }

    public Pixbuf? get_avatar(Account account, Jid jid) {
        Jid jid_ = jid;
        if (!stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid, account)) {
            jid_ = jid.bare_jid;
        }
        string? user_avatars_id = user_avatars[jid_];
        if (user_avatars_id != null) {
            return get_avatar_by_hash(user_avatars_id);
        }
        string? vcard_avatars_id = vcard_avatars[jid_];
        if (vcard_avatars_id != null) {
            return get_avatar_by_hash(vcard_avatars_id);
        }
        return null;
    }

    public void publish(Account account, string file) {
        try {
            Pixbuf pixbuf = new Pixbuf.from_file(file);
            if (pixbuf.width >= pixbuf.height && pixbuf.width > MAX_PIXEL) {
                int dest_height = (int) ((float) MAX_PIXEL / pixbuf.width * pixbuf.height);
                pixbuf = pixbuf.scale_simple(MAX_PIXEL, dest_height, InterpType.BILINEAR);
            } else if (pixbuf.height > pixbuf.width && pixbuf.width > MAX_PIXEL) {
                int dest_width = (int) ((float) MAX_PIXEL / pixbuf.height * pixbuf.width);
                pixbuf = pixbuf.scale_simple(dest_width, MAX_PIXEL, InterpType.BILINEAR);
            }
            uint8[] buffer;
            pixbuf.save_to_buffer(out buffer, "png");
            XmppStream stream = stream_interactor.get_stream(account);
            if (stream != null) {
                stream.get_module(Xep.UserAvatars.Module.IDENTITY).publish_png(stream, buffer, pixbuf.width, pixbuf.height);
                on_user_avatar_received(account, account.bare_jid, Base64.encode(buffer));
            }
        } catch (Error e) {
            print("error " + e.message + "\n");
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.UserAvatars.Module.IDENTITY).received_avatar.connect((stream, jid, id) =>
            on_user_avatar_received(account, jid, id)
        );
        stream_interactor.module_manager.get_module(account, Xep.VCard.Module.IDENTITY).received_avatar.connect((stream, jid, id) =>
            on_vcard_avatar_received(account, jid, id)
        );

        user_avatars = db.get_avatar_hashes(Source.USER_AVATARS);
        foreach (Jid jid in user_avatars.keys) {
            on_user_avatar_received(account, jid, user_avatars[jid]);
        }
        vcard_avatars = db.get_avatar_hashes(Source.VCARD);
        foreach (Jid jid in vcard_avatars.keys) {
            on_vcard_avatar_received(account, jid, vcard_avatars[jid]);
        }
    }

    private void on_user_avatar_received(Account account, Jid jid, string id) {
        if (!user_avatars.has_key(jid) || user_avatars[jid] != id) {
            user_avatars[jid] = id;
            db.set_avatar_hash(jid, id, Source.USER_AVATARS);
        }
        Pixbuf? avatar = avatar_storage.get_image(id);
        if (avatar != null) {
            received_avatar(avatar, jid, account);
        }
    }

    private void on_vcard_avatar_received(Account account, Jid jid, string id) {
        if (!vcard_avatars.has_key(jid) || vcard_avatars[jid] != id) {
            vcard_avatars[jid] = id;
            if (!jid.is_full()) { // don't save muc avatars
                db.set_avatar_hash(jid, id, Source.VCARD);
            }
        }
        Pixbuf? avatar = avatar_storage.get_image(id);
        if (avatar != null) {
            received_avatar(avatar, jid, account);
        }
    }
}

}