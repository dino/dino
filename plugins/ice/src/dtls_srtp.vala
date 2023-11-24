namespace Dino.Plugins.Ice.DtlsSrtp {

public abstract class CredentialsCapsule : Object {
    public uint8[] own_fingerprint;
}

public abstract class AbstractHandler {

    public signal void send_data(uint8[] data);

    public bool ready { get {
        return srtp_session.has_encrypt && srtp_session.has_decrypt;
    }}

    public Mode mode { get; set; default = Mode.CLIENT; }
    public uint8[] own_fingerprint { get; private set; }
    public uint8[] peer_fingerprint { get; set; }
    public string peer_fp_algo { get; set; }

    protected CredentialsCapsule credentials;
    protected Cond buffer_cond = Cond();
    protected Mutex buffer_mutex = Mutex();
    protected Gee.LinkedList<Bytes> buffer_queue = new Gee.LinkedList<Bytes>();

    protected bool running = false;
    protected bool stop = false;
    protected bool restart = false;

    protected Crypto.Srtp.Session srtp_session = new Crypto.Srtp.Session();

    protected AbstractHandler.with_cert(CredentialsCapsule creds) {
        this.credentials = creds;
        this.own_fingerprint = creds.own_fingerprint;
    }

    public uint8[]? process_incoming_data(uint component_id, uint8[] data) throws Crypto.Error {
        if (data[0] >= 128) {
            if (!srtp_session.has_decrypt) {
                debug("Received data before SRTP session is ready, dropping.");
                return null;
            }
            if (component_id == 1) {
                if (data.length >= 2 && data[1] >= 192 && data[1] < 224) {
                    return srtp_session.decrypt_rtcp(data);
                }
                return srtp_session.decrypt_rtp(data);
            }
            if (component_id == 2) return srtp_session.decrypt_rtcp(data);
        }
        if (component_id == 1 && data.length >= 1 && (data[0] >= 20 && data[0] < 64)) {
            on_data_rec(data);
            return null;
        }
        debug("Dropping unknown data from component %u", component_id);
        return null;
    }

    public uint8[]? process_outgoing_data(uint component_id, uint8[] data) throws Crypto.Error {
        if (srtp_session.has_encrypt) {
            if (component_id == 1) {
                if (data.length >= 2 && data[1] >= 192 && data[1] < 224) {
                    return srtp_session.encrypt_rtcp(data);
                }
                return srtp_session.encrypt_rtp(data);
            }
            if (component_id == 2) return srtp_session.encrypt_rtcp(data);
        }
        return null;
    }

    public void on_data_rec(owned uint8[] data) {
        buffer_mutex.lock();
        buffer_queue.add(new Bytes.take(data));
        buffer_cond.signal();
        buffer_mutex.unlock();
    }

    public void stop_dtls_connection() {
        buffer_mutex.lock();
        stop = true;
        buffer_cond.signal();
        buffer_mutex.unlock();
    }

    protected Bytes get_buffer_if_present () {
        buffer_mutex.lock();
        if (buffer_queue.size == 0) {
            buffer_mutex.unlock();
            return null;
        }
        Bytes res = buffer_queue.remove_at(0);
        buffer_mutex.unlock();
        return res;
    }

    public async Xmpp.Xep.Jingle.ContentEncryption? setup_dtls_connection() {
        MainContext context = MainContext.current_source().get_context();
        var thread = new Thread<Xmpp.Xep.Jingle.ContentEncryption>("dtls-connection", () => {
            // Check we can start working on the thread
            buffer_mutex.lock();
            if (stop) {
                restart = true;
                buffer_mutex.unlock();
                return null;
            }
            if (running || ready) {
                buffer_mutex.unlock();
                return null;
            }
            running = true;
            restart = false;
            buffer_mutex.unlock();

            // Actual work
            var res = setup_dtls_connection_thread();

            // Callback
            Source source = new IdleSource();
            source.set_callback(setup_dtls_connection.callback);
            source.attach(context);
            return res;
        });
        yield;
        return thread.join();
    }

    protected abstract Xmpp.Xep.Jingle.ContentEncryption? setup_dtls_connection_thread();
}

private string format_fingerprint(uint8[] fingerprint) {
    var sb = new StringBuilder();
    for (int i = 0; i < fingerprint.length; i++) {
        sb.append("%02X".printf(fingerprint[i]));
        if (i < fingerprint.length - 1) {
            sb.append(":");
        }
    }
    return sb.str;
}


public enum Mode {
    CLIENT, SERVER
}

}
