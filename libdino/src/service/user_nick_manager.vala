using Xmpp;
using Dino.Entities;

namespace Dino {

public class UserNickManager : StreamInteractionModule, Object {
    public static ModuleIdentity<UserNickManager> IDENTITY = new ModuleIdentity<UserNickManager>("user_nick_manager");
    public string id { get { return IDENTITY.id; } }

    public signal void received_nick(Jid jid, string nick);

    private StreamInteractor stream_interactor;
    private Database db;

    public static void start(StreamInteractor stream_interactor, Database db) {
        UserNickManager m = new UserNickManager(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private UserNickManager(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        stream_interactor.account_added.connect(on_account_added);
        stream_interactor.module_manager.initialize_account_modules.connect((account, modules) => {
          modules.add(new Xep.UserNickname.Module());
        });
    }

    public string? get_nick(Account account, Jid jid) {
        return db.get_nick(jid);
    }

    public void publish_nick(Account account, string nick) {
        XmppStream stream = stream_interactor.get_stream(account);
        if (stream != null) {
            stream.get_module(Xep.UserNickname.Module.IDENTITY).publish_nick(stream, nick);
        }
    }

    private void on_account_added(Account account) {
        stream_interactor.module_manager.get_module(account, Xep.UserNickname.Module.IDENTITY).received_nick.connect((stream, jid, nick) => {
            on_user_nick_received(account, jid, nick);
        });
        foreach (var entry in db.get_nicks().entries) {
            on_user_nick_received(account, entry.key, entry.value);
        }
    }

    private void on_user_nick_received(Account account, Jid jid, string nick) {
        db.user_nick.insert().or("REPLACE")
            .value(db.user_nick.jid, jid.bare_jid.to_string())
            .value(db.user_nick.nick, nick)
            .perform();
        received_nick(jid, nick);
    }
}

}
