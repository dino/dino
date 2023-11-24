using GnuTLS;

namespace Dino.Plugins.Ice.DtlsSrtp {

public class CredentialsCapsuleGnuTLS : CredentialsCapsule {
    public X509.Certificate[] own_cert;
    public X509.PrivateKey private_key;
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

internal CredentialsCapsule generate_credentials () throws GLib.Error {
    int err = 0;

    X509.PrivateKey private_key = X509.PrivateKey.create ();
    err = private_key.generate (PKAlgorithm.ECDSA, 256);
    throw_if_error (err);

    var start_time = new DateTime.now_local().add_days(-1);
    var end_time = start_time.add_days (2);

    X509.Certificate cert = X509.Certificate.create ();
    cert.set_key (private_key);
    cert.set_version (1);
    cert.set_activation_time ((time_t) start_time.to_unix ());
    cert.set_expiration_time ((time_t) end_time.to_unix ());

    uint32 serial = 1;
    cert.set_serial (&serial, sizeof(uint32));

    cert.sign (cert, private_key);

    uint8[] own_fingerprint = get_fingerprint (cert, DigestAlgorithm.SHA256);
    X509.Certificate[] own_cert = new X509.Certificate[] { (owned)cert };

    var creds = new CredentialsCapsuleGnuTLS();
    creds.own_fingerprint = own_fingerprint;
    creds.own_cert = (owned) own_cert;
    creds.private_key = (owned) private_key;

    return creds;
}

public class Handler : AbstractHandler {

    public Handler.with_cert(CredentialsCapsule creds) {
        base.with_cert(creds);
    }

    protected override Xmpp.Xep.Jingle.ContentEncryption? setup_dtls_connection_thread() {
        InitFlags server_or_client = mode == Mode.SERVER ? InitFlags.SERVER : InitFlags.CLIENT;
        debug("Setting up DTLS connection using GnuTLS. We're %s", mode.to_string());

        CertificateCredentials cert_cred = CertificateCredentials.create();
        int err = cert_cred.set_x509_key(((CredentialsCapsuleGnuTLS)credentials).own_cert, ((CredentialsCapsuleGnuTLS)credentials).private_key);
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

}