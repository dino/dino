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
        SourceFunc callback = add_check_account.callback;
        ConnectionManager.ConnectionError.Source? ret = null;

        ulong handler_id_connected = stream_interactor.stream_negotiated.connect((connected_account, stream) => {
            if (connected_account.equals(account)) {
                account.persist(db);
                account.enabled = true;
                Idle.add((owned)callback);
            }
        });
        ulong handler_id_error = stream_interactor.connection_manager.connection_error.connect((connected_account, error) => {
            if (connected_account.equals(account)) {
                ret = error.source;
            }
            stream_interactor.disconnect_account.begin(account);
            Idle.add((owned)callback);
        });

        stream_interactor.connect_account(account);
        yield;
        stream_interactor.disconnect(handler_id_connected);
        stream_interactor.connection_manager.disconnect(handler_id_error);

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
        if (stream.negotiation_complete) {
            return yield stream.get_module(Xep.InBandRegistration.Module.IDENTITY).submit_to_server(stream, jid, form);
        }
        return null;
    }
}

}
