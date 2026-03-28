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
    public signal void fetched_avatar(Jid jid, Account account);

    private enum Source {
        USER_AVATARS,
        VCARD
    }

    private StreamInteractor stream_interactor;
    private Database db;
    private string folder = null;
    private HashMap<Jid, string> user_avatars = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private HashMap<Jid, string> vcard_avatars = new HashMap<Jid, string>(Jid.hash_func, Jid.equals_func);
    private HashSet<string> pending_fetch = new HashSet<string>();
    private const int MAX_PIXEL = 192;

    public static void start(StreamInteractor stream_interactor, Database db) {
        AvatarManager m = new AvatarManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private AvatarManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;

        File old_avatars = File.new_build_filename(Dino.get_storage_dir(), "avatars");
        File new_avatars = File.new_build_filename(Dino.get_cache_dir(), "avatars");
        this.folder = new_avatars.get_path();

        // Move old avatar location to new one
        if (old_avatars.query_exists()) {
            if (!new_avatars.query_exists()) {
                // Move old avatars folder (~/.local/share/dino) to new location (~/.cache/dino)
                try {
                    new_avatars.get_parent().make_directory_with_parents();
                } catch (Error e) { }
                try {
                    old_avatars.move(new_avatars, FileCopyFlags.NONE);
                    debug("Avatars directory %s moved to %s", old_avatars.get_path(), new_avatars.get_path());
                } catch (Error e) { }
            } else {
                // If both old and new folders exist, remove the old one
                try {
                    FileEnumerator enumerator = old_avatars.enumerate_children("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                    FileInfo info = null;
                    while ((info = enumerator.next_file()) != null) {
                        FileUtils.remove(old_avatars.get_path() + "/" + info.get_name());
                    }
                    DirUtils.remove(old_avatars.get_path());
                } catch (Error e) { }
            }
        }

        // Create avatar folder
        try {
            new_avatars.make_directory_with_parents();
        } catch (Error e) { }

        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.module_manager.initialize_account_modules.connect((_, modules) => {
            modules.add(new Xep.UserAvatars.Module());
            modules.add(new Xep.VCard.Module());
        });
    }

    public File? get_avatar_file(Account account, Jid jid_) {
        string? hash = get_avatar_hash(account, jid_);
        if (hash == null) return null;
        File file = File.new_for_path(Path.build_filename(folder, hash));
        if (!file.query_exists()) {
            fetch_and_store_for_jid.begin(account, jid_);
            return null;
        } else {
            return file;
        }
    }

    private string? get_avatar_hash(Account account, Jid jid_) {
        Jid jid = jid_;
        if (!stream_interactor.get_module(MucManager.IDENTITY).is_groupchat_occupant(jid_, account)) {
            jid = jid_.bare_jid;
        }
        if (user_avatars.has_key(jid)) {
            return user_avatars[jid];
        } else if (vcard_avatars.has_key(jid)) {
            return vcard_avatars[jid];
        } else {
            return null;
        }
    }

    public bool has_avatar(Account account, Jid jid) {
        return get_avatar_hash(account, jid) != null;
    }

    public void publish(Account account, File file) {
        debug("Publish avatar from %s", file.get_uri());
        FileInputStream file_stream = null;
        try {
            file_stream = file.read();
            Pixbuf pixbuf = new Pixbuf.from_stream(file_stream);
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
                debug("Publishing %u png bytes via user-avatars.", buffer.length);
            } else {
                warning("No stream when trying to publish.");
            }
        } catch (Error e) {
            warning(e.message);
        } finally {
            try {
                if (file_stream != null) file_stream.close();
            } catch (Error e) {
                // Ignore
            }
        }
    }

    public void unset_avatar(Account account) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream == null) return;
        Xmpp.Xep.UserAvatars.unset_avatar(stream);
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.UserAvatars.Module.IDENTITY).received_avatar_hash.connect((stream, jid, id) =>
            on_user_avatar_received(account, jid, id)
        );
        stream_interactor.module_manager.get_module(account, Xep.UserAvatars.Module.IDENTITY).avatar_removed.connect((stream, jid) => {
            on_user_avatar_removed(account, jid);
        });
        stream_interactor.module_manager.get_module(account, Xep.VCard.Module.IDENTITY).received_avatar_hash.connect((stream, jid, id) =>
            on_vcard_avatar_received(account, jid, id)
        );

        foreach (var entry in get_avatar_hashes(account, Source.USER_AVATARS).entries) {
            on_user_avatar_received(account, entry.key, entry.value);
        }
        foreach (var entry in get_avatar_hashes(account, Source.VCARD).entries) {
            on_vcard_avatar_received(account, entry.key, entry.value);
        }
    }

    private void on_user_avatar_received(Account account, Jid jid_, string id) {
        Jid jid = jid_.bare_jid;

        if (!user_avatars.has_key(jid) || user_avatars[jid] != id) {
            user_avatars[jid] = id;
            set_avatar_hash(account, jid, id, Source.USER_AVATARS);
        }
        received_avatar(jid, account);
    }

    private void on_user_avatar_removed(Account account, Jid jid_) {
        Jid jid = jid_.bare_jid;
        user_avatars.unset(jid);
        remove_avatar_hash(account, jid, Source.USER_AVATARS);
        received_avatar(jid, account);
    }

    private void on_vcard_avatar_received(Account account, Jid jid_, string id) {
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

    public void remove_avatar_hash(Account account, Jid jid, int type) {
        db.avatar.delete()
            .with(db.avatar.jid_id, "=", db.get_jid_id(jid))
            .with(db.avatar.account_id, "=", account.id)
            .with(db.avatar.type_, "=", type)
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

    public async bool fetch_and_store_for_jid(Account account, Jid jid) {
        int source = -1;
        string? hash = null;
        if (user_avatars.has_key(jid)) {
            hash = user_avatars[jid];
            source = 1;
        } else if (vcard_avatars.has_key(jid)) {
            hash = vcard_avatars[jid];
            source = 2;
        } else {
            return false;
        }

        XmppStream? stream = stream_interactor.get_stream(account);
        if (stream == null || !stream.negotiation_complete) return false;

        return yield fetch_and_store(stream, account, jid, source, hash);
    }

    private async bool fetch_and_store(XmppStream stream, Account account, Jid jid, int source, string? hash) {
        if (hash == null || pending_fetch.contains(hash)) return false;

        pending_fetch.add(hash);
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
            yield store_image(hash, bytes);
            fetched_avatar(jid, account);
        }
        pending_fetch.remove(hash);
        return bytes != null;
    }

    private async void store_image(string id, Bytes data) {
        File file = File.new_for_path(Path.build_filename(folder, id));
        try {
            if (file.query_exists()) file.delete(); //TODO y?
            DataOutputStream fos = new DataOutputStream(file.create(FileCreateFlags.REPLACE_DESTINATION));
            yield fos.write_bytes_async(data);
        } catch (Error e) {
            warning("Error writing avatar file: %s", e.message);
            // Ignore: we failed in storing, so we refuse to display later...
        }
    }

    public bool has_image(string id) {
        File file = File.new_for_path(Path.build_filename(folder, id));
        return file.query_exists();
    }
}

}
