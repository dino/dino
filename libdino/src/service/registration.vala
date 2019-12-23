using Gee;

using Xmpp;
using Dino.Entities;

namespace Dino {

public class Register : StreamInteractionModule, Object{
    public static ModuleIdentity<Register> IDENTITY = new ModuleIdentity<Register>("registration");
    public string id { get { return IDENTITY.id; } }

    private StreamInteractor stream_interactor;
    private Database db;

    public static void start(StreamInteractor stream_interactor, Database db) {
        Register m = new Register(stream_interactor, db);
        stream_interactor.add_module(m);
    }

    private Register(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
    }

    public async ConnectionManager.ConnectionError.Source? add_check_account(Account account) {
        XmppStream stream = new XmppStream();
        stream.log = new XmppLog(account.bare_jid.to_string(), Application.print_xmpp);
        stream.add_module(new Tls.Module());
        stream.add_module(new Iq.Module());
        stream.add_module(new Xep.SrvRecordsTls.Module());
        stream.add_module(new Sasl.Module(account.bare_jid.to_string(), account.password));

        ConnectionManager.ConnectionError.Source? ret = null;

        SourceFunc callback = add_check_account.callback;
        stream.stream_negotiated.connect(() => {
            if (callback == null) return;
            Idle.add((owned)callback);
        });
        stream.get_module(Tls.Module.IDENTITY).invalid_certificate.connect((peer_cert, errors) => {
            if (callback == null) return;
            ret = ConnectionManager.ConnectionError.Source.TLS;
            Idle.add((owned)callback);
        });
        stream.get_module(Sasl.Module.IDENTITY).received_auth_failure.connect((stream, node) => {
            if (callback == null) return;
            ret = ConnectionManager.ConnectionError.Source.SASL;
            Idle.add((owned)callback);
        });
        stream.connect.begin(account.bare_jid.domainpart, (_, res) => {
            try {
                stream.connect.end(res);
            } catch (Error e) {
                debug("Error connecting to stream: %s", e.message);
            }
            if (callback != null) {
                ret = ConnectionManager.ConnectionError.Source.CONNECTION;
                Idle.add((owned)callback);
            }
        });

        yield;

        try {
            yield stream.disconnect();
        } catch (Error e) {}
        return ret;
    }

    public class ServerAvailabilityReturn {
        public bool available { get; set; }
        public TlsCertificateFlags? error_flags { get; set; }
    }

    public static async ServerAvailabilityReturn check_server_availability(Jid jid) {
        XmppStream stream = new XmppStream();
        stream.log = new XmppLog(jid.to_string(), Application.print_xmpp);
        stream.add_module(new Tls.Module());
        stream.add_module(new Iq.Module());
        stream.add_module(new Xep.SrvRecordsTls.Module());

        ServerAvailabilityReturn ret = new ServerAvailabilityReturn() { available=false };
        SourceFunc callback = check_server_availability.callback;
        stream.stream_negotiated.connect(() => {
            if (callback != null) {
                ret.available = true;
                Idle.add((owned)callback);
            }
        });
        stream.get_module(Tls.Module.IDENTITY).invalid_certificate.connect((peer_cert, errors) => {
            if (callback != null) {

                ret.error_flags = errors;
                Idle.add((owned)callback);
            }
        });

        stream.connect.begin(jid.domainpart, (_, res) => {
            try {
                stream.connect.end(res);
            } catch (Error e) {
                debug("Error connecting to stream: %s", e.message);
            }
            if (callback != null) {
                Idle.add((owned)callback);
            }
        });

        yield;

        try {
            yield stream.disconnect();
        } catch (Error e) {}
        return ret;
    }

    public static async Xep.InBandRegistration.Form? get_registration_form(Jid jid) {
        XmppStream stream = new XmppStream();
        stream.log = new XmppLog(jid.to_string(), Application.print_xmpp);
        stream.add_module(new Tls.Module());
        stream.add_module(new Iq.Module());
        stream.add_module(new Xep.SrvRecordsTls.Module());
        stream.add_module(new Xep.InBandRegistration.Module());

        SourceFunc callback = get_registration_form.callback;

        stream.stream_negotiated.connect(() => {
            if (callback != null) {
                Idle.add((owned)callback);
            }
        });

        stream.connect.begin(jid.domainpart, (_, res) => {
            try {
                stream.connect.end(res);
            } catch (Error e) {
                debug("Error connecting to stream: %s", e.message);
            }
            if (callback != null) {
                Idle.add((owned)callback);
            }
        });

        yield;

        Xep.InBandRegistration.Form? form = null;
        if (stream.negotiation_complete) {
            form = yield stream.get_module(Xep.InBandRegistration.Module.IDENTITY).get_from_server(stream, jid);
        }
        try {
            yield stream.disconnect();
        } catch (Error e) {}

        return form;
    }

    public static async string? submit_form(Jid jid, Xep.InBandRegistration.Form form) {
        XmppStream stream = new XmppStream();
        stream.log = new XmppLog(jid.to_string(), Application.print_xmpp);
        stream.add_module(new Tls.Module());
        stream.add_module(new Iq.Module());
        stream.add_module(new Xep.SrvRecordsTls.Module());
        stream.add_module(new Xep.InBandRegistration.Module());

        SourceFunc callback = submit_form.callback;

        stream.stream_negotiated.connect(() => {
            if (callback != null) {
                Idle.add((owned)callback);
            }
        });

        stream.connect.begin(jid.domainpart, (_, res) => {
            try {
                stream.connect.end(res);
            } catch (Error e) {
                debug("Error connecting to stream: %s", e.message);
            }
            if (callback != null) {
                Idle.add((owned)callback);
            }
        });

        yield;

        string? ret = null;
        if (stream.negotiation_complete) {
            ret = yield stream.get_module(Xep.InBandRegistration.Module.IDENTITY).submit_to_server(stream, jid, form);
        }
        try {
            yield stream.disconnect();
        } catch (Error e) {}
        return ret;
    }
}

}
