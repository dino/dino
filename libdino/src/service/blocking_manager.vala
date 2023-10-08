using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class BlockingManager : StreamInteractionModule, Object {
    public static ModuleIdentity<BlockingManager> IDENTITY = new ModuleIdentity<BlockingManager>("blocking_manager");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;

    public static void start(StreamInteractor stream_interactor) {
        BlockingManager m = new BlockingManager(stream_interactor);
        stream_interactor.add_module(m);
    }

    private BlockingManager(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public bool is_blocked(Account account, Jid jid, bool domainblock) {
        XmppStream stream = stream_interactor.get_stream(account);
        string jid_str = domainblock ? jid.domainpart.to_string () : jid.to_string();
        return stream != null && stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).is_blocked(stream, jid_str);
    }

    public void block(Account account, Jid jid, bool domainblock) {
        XmppStream stream = stream_interactor.get_stream(account);
        string jid_str = domainblock ? jid.domainpart.to_string () : jid.to_string();
        stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).block(stream, { jid_str });
    }
    
    public void unblock(Account account, Jid jid, bool domainblock) {
        XmppStream stream = stream_interactor.get_stream(account);
        string jid_str = domainblock ? jid.domainpart.to_string () : jid.to_string();
        stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).unblock(stream, { jid_str });
    }

    public bool is_supported(Account account) {
        XmppStream stream = stream_interactor.get_stream(account);
        return stream != null && stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).is_supported(stream);
    }
}

}
