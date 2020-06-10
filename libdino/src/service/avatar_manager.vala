using Gdk;
using Gee;
using Qlite;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class AvatarManager : StreamInteractionModule, Object {
    public static ModuleIdentity<AvatarManager> IDENTITY = new ModuleIdentity<AvatarManager>("avatar_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void received_avatar(Jid jid, Account account);

    private enum Source {
        USER_AVATARS,
        VCARD
    }

    private StreamInteractor stream_interactor;
    private Database db;
    private string folder = null;
    private HashMap<Jid, string> user_avatars = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, string> vcard_avatars = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private HashMap<string, Pixbuf> cached_pixbuf = new HashMap<string, Pixbuf>();
    private HashMap<string, Gee.List<SourceFuncWrapper>> pending_pixbuf = new HashMap<string, Gee.List<SourceFuncWrapper>>();
    private const int MAX_PIXEL = 192;

    public static void start(StreamInteractor stream_interactor, Database db) {
        AvatarManager m = new AvatarManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private AvatarManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.folder = Path.build_filename(Dino.get_storage_dir(), "avatars");
        DirUtils.create_with_parents(this.folder, 0700);

        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.module_manager.initialize_account_modules.connect((_, modules) => {
            modules.add(new Xep.UserAvatars.Module());
            modules.add(new Xep.VCard.Module());
        });
    }

    private async Pixbuf? get_avatar_by_hash(string hash) {
        if (cached_pixbuf.has_key(hash)) {
            return cached_pixbuf[hash];
        }
        if (pending_pixbuf.has_key(hash)) {
            pending_pixbuf[hash].add(new SourceFuncWrapper(get_avatar_by_hash.callback));
            yield;
            return cached_pixbuf[hash];
        }
        pending_pixbuf[hash] = new ArrayList<SourceFuncWrapper>();
        Pixbuf? image = yield get_image(hash);
        if (image != null) {
            cached_pixbuf[hash] = image;
        } else {
            db.avatar.delete().with(db.avatar.hash, "=", hash).perform();
        }
        foreach (SourceFuncWrapper sfw in pending_pixbuf[hash]) {
            sfw.sfun();
        }
        return image;
    }

    public async Pixbuf? get_avatar(Account account, Jid jid_) {
        Jid jid = jid_;
        if (!stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid_, account)) {
            jid = jid_.bare_jid;
        }

        int source = -1;
        string? hash = null;
        if (user_avatars.has_key(jid)) {
            hash = user_avatars[jid];
            source = 1;
        } else if (vcard_avatars.has_key(jid)) {
            hash = vcard_avatars[jid];
            source = 2;
        }

        if (hash == null) return null;

        if (cached_pixbuf.has_key(hash)) {
            return cached_pixbuf[hash];
        }

        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null || !stream.negotiation_complete) return null;

        if (pending_pixbuf.has_key(hash)) {
            pending_pixbuf[hash].add(new SourceFuncWrapper(get_avatar.callback));
            yield;
            return cached_pixbuf[hash];
        }

        pending_pixbuf[hash] = new ArrayList<SourceFuncWrapper>();
        Pixbuf? image = yield get_image(hash);
        if (image != null) {
            cached_pixbuf[hash] = image;
        } else {
            Bytes? bytes = null;
            if (source == 1) {
                bytes = yield Xmpp.Xep.UserAvatars.fetch_image(stream, jid, hash);
            } else if (source == 2) {
                bytes = yield Xmpp.Xep.VCard.fetch_image(stream, jid, hash);
                if (bytes == null && jid.is_bare()) {
                    db.avatar.delete().with(db.avatar.jid_id, "=", db.get_jid_id(jid)).perform();
                }
            }
            if (bytes != null) {
                store_image(hash, bytes);
                image = yield get_image(hash);
            }
            cached_pixbuf[hash] = image;
        }
        foreach (SourceFuncWrapper sfw in pending_pixbuf[hash]) {
            sfw.sfun();
        }
        return image;
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
                Xmpp.Xep.UserAvatars.publish_png(stream, buffer, pixbuf.width, pixbuf.height);
            }
        } catch (Error e) {
            warning(e.message);
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.UserAvatars.Module.IDENTITY).received_avatar_hash.connect((stream, jid, id) =>
            on_user_avatar_received.begin(account, jid, id)
        );
        stream_interactor.module_manager.get_module(account, Xep.VCard.Module.IDENTITY).received_avatar_hash.connect((stream, jid, id) =>
            on_vcard_avatar_received.begin(account, jid, id)
        );

        foreach (var entry in get_avatar_hashes(account, Source.USER_AVATARS).entries) {
            user_avatars[entry.key] = entry.value;
        }
        foreach (var entry in get_avatar_hashes(account, Source.VCARD).entries) {

            // FIXME: remove. temporary to remove falsely saved avatars.
            if (stream_interactor.get_module(MucManager.IDENTITY).is_groupchat(entry.key, account)) {
                db.avatar.delete().with(db.avatar.jid_id, "=", db.get_jid_id(entry.key)).perform();
                continue;
            }

            vcard_avatars[entry.key] = entry.value;
        }
    }

    private async void on_user_avatar_received(Account account, Jid jid_, string id) {
        Jid jid = jid_.bare_jid;

        if (!user_avatars.has_key(jid) || user_avatars[jid] != id) {
            user_avatars[jid] = id;
            set_avatar_hash(account, jid, id, Source.USER_AVATARS);
        }
        received_avatar(jid, account);
    }

    private async void on_vcard_avatar_received(Account account, Jid jid_, string id) {
        bool is_gc = stream_interactor.get_module(MucManager.IDENTITY).might_be_groupchat(jid_.bare_jid, account);
        Jid jid = is_gc ? jid_ : jid_.bare_jid;

        if (!vcard_avatars.has_key(jid) || vcard_avatars[jid] != id) {
            vcard_avatars[jid] = id;
            if (jid.is_bare()) { // don't save MUC occupant avatars
                set_avatar_hash(account, jid, id, Source.VCARD);
            }
        }
        received_avatar(jid, account);
    }

    public void set_avatar_hash(Account account, Jid jid, string hash, int type) {
        db.avatar.insert()
            .value(db.avatar.jid_id, db.get_jid_id(jid))
            .value(db.avatar.account_id, account.id)
            .value(db.avatar.hash, hash)
            .value(db.avatar.type_, type)
            .perform();
    }

    public HashMap<Jid, string> get_avatar_hashes(Account account, int type) {
        HashMap<Jid, string> ret = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
        foreach (Row row in db.avatar.select({db.avatar.jid_id, db.avatar.hash})
                .with(db.avatar.type_, "=", type)
                .with(db.avatar.account_id, "=", account.id)) {
            ret[db.get_jid_by_id(row[db.avatar.jid_id])] = row[db.avatar.hash];
        }
        return ret;
    }

    public void store_image(string id, Bytes data) {
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

            uint8 fbuf[1024];
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
