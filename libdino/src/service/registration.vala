using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class Register {

    public static async Xep.InBandRegistration.Form get_registration_form(Jid jid) {
        XmppStream stream = new XmppStream();
        stream.add_module(new Tls.Module());
        stream.add_module(new Iq.Module());
        stream.add_module(new Xep.InBandRegistration.Module());
        stream.connect.begin(jid.bare_jid.to_string());

        Xep.InBandRegistration.Form? form = null;
        SourceFunc callback = get_registration_form.callback;
        stream.stream_negotiated.connect(() => {
            if (callback != null) {
                Idle.add((owned)callback);
            }
        });
        Timeout.add_seconds(5, () => {
            if (callback != null) {
                Idle.add((owned)callback);
            }
            return false;
        });
        yield;
        if (stream.negotiation_complete) {
            form = yield stream.get_module(Xep.InBandRegistration.Module.IDENTITY).get_from_server(stream, jid);
        }
        return form;
    }

    public static async string submit_form(Jid jid, Xep.InBandRegistration.Form form) {
        return yield form.stream.get_module(Xep.InBandRegistration.Module.IDENTITY).submit_to_server(form.stream, jid, form);
    }
}

}
