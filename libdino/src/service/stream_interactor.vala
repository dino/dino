using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class StreamInteractor {

    public signal void account_added(Account account);
    public signal void account_removed(Account account);
    public signal void stream_negotiated(Account account, XmppStream stream);
    public signal void attached_modules(Account account, XmppStream stream);

    public ModuleManager module_manager;
    public ConnectionManager connection_manager;
    private ArrayList<StreamInteractionModule> modules = new ArrayList<StreamInteractionModule>();

    public StreamInteractor(Database db) {
        module_manager = new ModuleManager(db);
        connection_manager = new ConnectionManager(module_manager);

        connection_manager.stream_opened.connect(on_stream_opened);
    }

    public void connect(Account account) {
        module_manager.initialize(account);
        account_added(account);
        connection_manager.connect(account);
    }

    public void disconnect(Account account) {
        connection_manager.disconnect(account);
        account_removed(account);
    }

    public ArrayList<Account> get_accounts() {
        ArrayList<Account> ret = new ArrayList<Account>(Account.equals_func);
        foreach (Account account in connection_manager.get_managed_accounts()) {
            ret.add(account);
        }
        return ret;
    }

    public XmppStream? get_stream(Account account) {
        return connection_manager.get_stream(account);
    }

    public void add_module(StreamInteractionModule module) {
        modules.add(module);
    }

    public T? get_module<T>(ModuleIdentity<T>? identity) {
        if (identity == null) return null;
        foreach (StreamInteractionModule module in modules) {
            if (identity.matches(module)) return identity.cast(module);
        }
        return null;
    }

    private void on_stream_opened(Account account, XmppStream stream) {
        stream.stream_negotiated.connect( (stream) => {
            stream_negotiated(account, stream);
        });
    }
}

public class ModuleIdentity<T> : Object {
    public string id { get; private set; }

    public ModuleIdentity(string id) {
        this.id = id;
    }

    public T? cast(StreamInteractionModule module) {
        return module.get_type().is_a(typeof(T)) ? (T?) module : null;
    }

    public bool matches(StreamInteractionModule module) {
        return module.id== id;
    }
}

public interface StreamInteractionModule : Object {
    public abstract string id { get; }
}

}
