using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class StreamInteractor {

    public signal void account_added(Account account);
    public signal void account_removed(Account account);
    public signal void stream_negotiated(Account account);

    public ModuleManager module_manager;
    public ConnectionManager connection_manager;
    private ArrayList<StreamInteractionModule> interaction_modules = new ArrayList<StreamInteractionModule>();

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

    public Core.XmppStream? get_stream(Account account) {
        return connection_manager.get_stream(account);
    }

    public void add_module(StreamInteractionModule module) {
        interaction_modules.add(module);
    }

    public StreamInteractionModule? get_module(string id) {
        foreach (StreamInteractionModule module in interaction_modules) {
            if (module.get_id() == id) {
                return module;
            }
        }
        return null;
    }

    private void on_stream_opened(Account account, Core.XmppStream stream) {
        stream.stream_negotiated.connect( (stream) => {
            stream_negotiated(account);
        });
    }
}

public interface StreamInteractionModule : Object {
    public abstract string get_id();
}

}