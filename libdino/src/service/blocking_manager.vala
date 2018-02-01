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

    public bool is_blocked(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        return stream != null && stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).is_blocked(stream, jid.to_string());
    }

    public void block(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).block(stream, new ArrayList<string>.wrap(new string[] {jid.to_string()}));
    }

    public void unblock(Account account, Jid jid) {
        XmppStream stream = stream_interactor.get_stream(account);
        stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).unblock(stream, new ArrayList<string>.wrap(new string[] {jid.to_string()}));
    }

    public bool is_supported(Account account) {
        XmppStream stream = stream_interactor.get_stream(account);
        return stream != null && stream.get_module(Xmpp.Xep.BlockingCommand.Module.IDENTITY).is_supported(stream);
    }
}

}
