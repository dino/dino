using GnuTLS;

namespace Dino.Plugins.Ice.DtlsSrtp {

public class CredentialsCapsule {
    public uint8[] own_fingerprint;
    public X509.Certificate[] own_cert;
    public X509.PrivateKey private_key;
}

public class Handler {

    public signal void send_data(uint8[] data);

    public bool ready { get {
        return srtp_session.has_encrypt && srtp_session.has_decrypt;
    }}

    public Mode mode { get; set; default = Mode.CLIENT; }
    public uint8[] own_fingerprint { get; private set; }
    public uint8[] peer_fingerprint { get; set; }
    public string peer_fp_algo { get; set; }

    private CredentialsCapsule credentials;
    private Cond buffer_cond = Cond();
    private Mutex buffer_mutex = Mutex();
    private Gee.LinkedList<Bytes> buffer_queue = new Gee.LinkedList<Bytes>();

    private bool running = false;
    private bool stop = false;
    private bool restart = false;

    private Crypto.Srtp.Session srtp_session = new Crypto.Srtp.Session();

    public Handler.with_cert(CredentialsCapsule creds) {
        this.credentials = creds;
        this.own_fingerprint = creds.own_fingerprint;
    }

    public uint8[]? process_incoming_data(uint component_id, uint8[] data) throws Crypto.Error {
        if (srtp_session.has_decrypt) {
            if (component_id == 1) {
                if (data.length >= 2 && data[1] >= 192 && data[1] < 224) {
                    return srtp_session.decrypt_rtcp(data);
                }
                return srtp_session.decrypt_rtp(data);
            }
            if (component_id == 2) return srtp_session.decrypt_rtcp(data);
        } else if (component_id == 1) {
            on_data_rec(data);
        }
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

    internal static CredentialsCapsule generate_credentials() throws GLib.Error {
        int err = 0;

        X509.PrivateKey private_key = X509.PrivateKey.create();
        err = private_key.generate(PKAlgorithm.RSA, 2048);
        throw_if_error(err);

        var start_time = new DateTime.now_local().add_days(1);
        var end_time = start_time.add_days(2);

        X509.Certificate cert = X509.Certificate.create();
        cert.set_key(private_key);
        cert.set_version(1);
        cert.set_activation_time ((time_t) start_time.to_unix ());
        cert.set_expiration_time ((time_t) end_time.to_unix ());

        uint32 serial = 1;
        cert.set_serial(&serial, sizeof(uint32));

        cert.sign(cert, private_key);

        uint8[] own_fingerprint = get_fingerprint(cert, DigestAlgorithm.SHA256);
        X509.Certificate[] own_cert = new X509.Certificate[] { (owned)cert };

        var creds = new CredentialsCapsule();
        creds.own_fingerprint = own_fingerprint;
        creds.own_cert = (owned) own_cert;
        creds.private_key = (owned) private_key;

        return creds;
    }

    public void stop_dtls_connection() {
        buffer_mutex.lock();
        stop = true;
        buffer_cond.signal();
        buffer_mutex.unlock();
    }

    public async Xmpp.Xep.Jingle.ContentEncryption? setup_dtls_connection() {
        MainContext context = MainContext.current_source().get_context();
        var thread = new Thread<Xmpp.Xep.Jingle.ContentEncryption>("dtls-connection", () => {
            var res = setup_dtls_connection_thread();
            Source source = new IdleSource();
            source.set_callback(setup_dtls_connection.callback);
            source.attach(context);
            return res;
        });
        yield;
        return thread.join();
    }

    private Xmpp.Xep.Jingle.ContentEncryption? setup_dtls_connection_thread() {
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

        InitFlags server_or_client = mode == Mode.SERVER ? InitFlags.SERVER : InitFlags.CLIENT;
        debug("Setting up DTLS connection. We're %s", mode.to_string());

        CertificateCredentials cert_cred = CertificateCredentials.create();
        int err = cert_cred.set_x509_key(credentials.own_cert, credentials.private_key);
        throw_if_error(err);

        Session? session = Session.create(server_or_client | InitFlags.DATAGRAM);
        session.enable_heartbeat(1);
        session.set_srtp_profile_direct("SRTP_AES128_CM_HMAC_SHA1_80");
        session.set_credentials(GnuTLS.CredentialsType.CERTIFICATE, cert_cred);
        session.server_set_request(CertificateRequest.REQUEST);
        session.set_priority_from_string("NORMAL:!VERS-TLS-ALL:+VERS-DTLS-ALL:+CTYPE-CLI-X509");

        session.set_transport_pointer(this);
        session.set_pull_function(pull_function);
        session.set_pull_timeout_function(pull_timeout_function);
        session.set_push_function(push_function);
        session.set_verify_function(verify_function);

        DateTime maximum_time = new DateTime.now_utc().add_seconds(20);
        do {
            err = session.handshake();

            DateTime current_time = new DateTime.now_utc();
            if (maximum_time.compare(current_time) < 0) {
                warning("DTLS handshake timeouted");
                err = ErrorCode.APPLICATION_ERROR_MIN + 1;
                break;
            }
            if (stop) {
                debug("DTLS handshake stopped");
                err = ErrorCode.APPLICATION_ERROR_MIN + 2;
                break;
            }
        } while (err < 0 && !((ErrorCode)err).is_fatal());

        buffer_mutex.lock();
        if (stop) {
            stop = false;
            running = false;
            bool restart = restart;
            buffer_mutex.unlock();
            if (restart) {
                debug("Restarting DTLS handshake");
                return setup_dtls_connection_thread();
            }
            return null;
        }
        buffer_mutex.unlock();
        if (err != ErrorCode.SUCCESS) {
            warning("DTLS handshake failed: %s", ((ErrorCode)err).to_string());
            return null;
        }

        uint8[] km = new uint8[150];
        Datum? client_key, client_salt, server_key, server_salt;
        session.get_srtp_keys(km, km.length, out client_key, out client_salt, out server_key, out server_salt);
        if (client_key == null || client_salt == null || server_key == null || server_salt == null) {
            warning("SRTP client/server key/salt null");
        }

        debug("Finished DTLS connection. We're %s", mode.to_string());
        if (mode == Mode.SERVER) {
            srtp_session.set_encryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, server_key.extract(), server_salt.extract());
            srtp_session.set_decryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, client_key.extract(), client_salt.extract());
        } else {
            srtp_session.set_encryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, client_key.extract(), client_salt.extract());
            srtp_session.set_decryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, server_key.extract(), server_salt.extract());
        }
        return new Xmpp.Xep.Jingle.ContentEncryption(Xmpp.Xep.JingleIceUdp.DTLS_NS_URI, "DTLS-SRTP", credentials.own_fingerprint, peer_fingerprint);
    }

    private static ssize_t pull_function(void* transport_ptr, uint8[] buffer) {
        Handler self = transport_ptr as Handler;

        self.buffer_mutex.lock();
        while (self.buffer_queue.size == 0) {
            self.buffer_cond.wait(self.buffer_mutex);
            if (self.stop) {
                self.buffer_mutex.unlock();
                debug("DTLS handshake pull_function stopped");
                return -1;
            }
        }
        Bytes data = self.buffer_queue.remove_at(0);
        self.buffer_mutex.unlock();

        uint8[] data_uint8 = Bytes.unref_to_data((owned) data);
        Memory.copy(buffer, data_uint8, data_uint8.length);

        // The callback should return 0 on connection termination, a positive number indicating the number of bytes received, and -1 on error.
        return (ssize_t)data_uint8.length;
    }

    private static int pull_timeout_function(void* transport_ptr, uint ms) {
        Handler self = transport_ptr as Handler;

        int64 end_time = get_monotonic_time() + ms * 1000;

        self.buffer_mutex.lock();
        while (self.buffer_queue.size == 0) {
            self.buffer_cond.wait_until(self.buffer_mutex, end_time);
            if (self.stop) {
                self.buffer_mutex.unlock();
                debug("DTLS handshake pull_timeout_function stopped");
                return -1;
            }

            if (get_monotonic_time() > end_time) {
                self.buffer_mutex.unlock();
                return 0;
            }
        }
        self.buffer_mutex.unlock();

        // The callback should return 0 on timeout, a positive number if data can be received, and -1 on error.
        return 1;
    }

    private static ssize_t push_function(void* transport_ptr, uint8[] buffer) {
        Handler self = transport_ptr as Handler;
        self.send_data(buffer);

        // The callback should return a positive number indicating the bytes sent, and -1 on error.
        return (ssize_t)buffer.length;
    }

    private static int verify_function(Session session) {
        Handler self = session.get_transport_pointer() as Handler;
        try {
            bool valid = self.verify_peer_cert(session);
            if (!valid) {
                warning("DTLS certificate invalid. Aborting handshake.");
                return 1;
            }
        } catch (Error e) {
            warning("Error during DTLS certificate validation: %s. Aborting handshake.", e.message);
            return 1;
        }

        // The callback function should return 0 for the handshake to continue or non-zero to terminate.
        return 0;
    }

    private bool verify_peer_cert(Session session) throws GLib.Error {
        unowned Datum[] cert_datums = session.get_peer_certificates();
        if (cert_datums.length == 0) {
            warning("No peer certs");
            return false;
        }
        if (cert_datums.length > 1) warning("More than one peer cert");

        X509.Certificate peer_cert = X509.Certificate.create();
        peer_cert.import(ref cert_datums[0], CertificateFormat.DER);

        DigestAlgorithm algo;
        switch (peer_fp_algo) {
            case "sha-256":
                algo = DigestAlgorithm.SHA256;
                break;
            default:
                warning("Unkown peer fingerprint algorithm: %s", peer_fp_algo);
                return false;
        }

        uint8[] real_peer_fp = get_fingerprint(peer_cert, algo);

        if (real_peer_fp.length != this.peer_fingerprint.length) {
            warning("Fingerprint lengths not equal %i vs %i", real_peer_fp.length, peer_fingerprint.length);
            return false;
        }

        for (int i = 0; i < real_peer_fp.length; i++) {
            if (real_peer_fp[i] != this.peer_fingerprint[i]) {
                warning("First cert in peer cert list doesn't equal advertised one: %s vs %s", format_fingerprint(real_peer_fp), format_fingerprint(peer_fingerprint));
                return false;
            }
        }

        return true;
    }
}

private uint8[] get_fingerprint(X509.Certificate certificate, DigestAlgorithm digest_algo) {
    uint8[] buf = new uint8[512];
    size_t buf_out_size = 512;
    certificate.get_fingerprint(digest_algo, buf, ref buf_out_size);

    uint8[] ret = new uint8[buf_out_size];
    for (int i = 0; i < buf_out_size; i++) {
        ret[i] = buf[i];
    }
    return ret;
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
