using Gee;
using Nice;
using Xmpp;

namespace Dino.Plugins.Ice {

public class Plugin : RootInterface, Object {
    public Dino.Application app;

    public void registered(Dino.Application app) {
        this.app = app;
        app.stream_interactor.stream_attached_modules.connect((account, stream) => {
            stream.get_module(Xmpp.Xep.Socks5Bytestreams.Module.IDENTITY).set_local_ip_address_handler(get_local_ip_addresses);
        });
    }

    private Gee.List<string> get_local_ip_addresses() {
        Gee.List<string> result = new ArrayList<string>();
        foreach (string ip_address in Nice.interfaces_get_local_ips(false)) {
            result.add(ip_address);
        }
        return result;
    }

    public void shutdown() {
        // Nothing to do
    }
}

}
