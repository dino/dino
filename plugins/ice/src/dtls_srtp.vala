using GnuTLS;

public class DtlsSrtp {

    public signal void send_data(uint8[] data);

    private X509.Certificate[] own_cert;
    private X509.PrivateKey private_key;
    private Cond buffer_cond = new Cond();
    private Mutex buffer_mutex = new Mutex();
    private Gee.LinkedList<Bytes> buffer_queue = new Gee.LinkedList<Bytes>();
    private uint pull_timeout = uint.MAX;
    private string peer_fingerprint;

    private Crypto.Srtp.Session srtp_session = new Crypto.Srtp.Session();

    public static DtlsSrtp setup() throws GLib.Error {
        var obj = new DtlsSrtp();
        obj.generate_credentials();
        return obj;
    }

    internal string get_own_fingerprint(DigestAlgorithm digest_algo) {
        return format_certificate(own_cert[0], digest_algo);
    }

    public void set_peer_fingerprint(string fingerprint) {
        this.peer_fingerprint = fingerprint;
    }

    public uint8[] process_incoming_data(uint component_id, uint8[] data) {
        if (srtp_session.has_decrypt) {
            try {
                if (component_id == 1) {
                    if (data.length >= 2 && data[1] >= 192 && data[1] < 224) {
                        return srtp_session.decrypt_rtcp(data);
                    }
                    return srtp_session.decrypt_rtp(data);
                }
                if (component_id == 2) return srtp_session.decrypt_rtcp(data);
            } catch (Error e) {
                warning("%s (%d)", e.message, e.code);
                return null;
            }
        } else if (component_id == 1) {
            on_data_rec(data);
        }
        return null;
    }

    public uint8[] process_outgoing_data(uint component_id, uint8[] data) {
        if (srtp_session.has_encrypt) {
            try {
                if (component_id == 1) {
                    if (data.length >= 2 && data[1] >= 192 && data[1] < 224) {
                        return srtp_session.encrypt_rtcp(data);
                    }
                    return srtp_session.encrypt_rtp(data);
                }
                if (component_id == 2) return srtp_session.encrypt_rtcp(data);
            } catch (Error e) {
                warning("%s (%d)", e.message, e.code);
                return null;
            }
        }
        return null;
    }

    public void on_data_rec(owned uint8[] data) {
        buffer_mutex.lock();
        buffer_queue.add(new Bytes.take(data));
        buffer_cond.signal();
        buffer_mutex.unlock();
    }

    private void generate_credentials() throws GLib.Error {
        int err = 0;

        private_key = X509.PrivateKey.create();
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

        own_cert = new X509.Certificate[] { (owned)cert };
    }

    public async void setup_dtls_connection(bool server) {
        InitFlags server_or_client = server ? InitFlags.SERVER : InitFlags.CLIENT;
        debug("Setting up DTLS connection. We're %s", server_or_client.to_string());

        CertificateCredentials cert_cred = CertificateCredentials.create();
        int err = cert_cred.set_x509_key(own_cert, private_key);
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

        Thread<int> thread = new Thread<int> (null, () => {
            DateTime maximum_time = new DateTime.now_utc().add_seconds(20);
            do {
                err = session.handshake();

                DateTime current_time = new DateTime.now_utc();
                if (maximum_time.compare(current_time) < 0) {
                    warning("DTLS handshake timeouted");
                    return -1;
                }
            } while (err < 0 && !((ErrorCode)err).is_fatal());
            Idle.add(setup_dtls_connection.callback);
            return err;
        });
        yield;
        err = thread.join();

        uint8[] km = new uint8[150];
        Datum? client_key, client_salt, server_key, server_salt;
        session.get_srtp_keys(km, km.length, out client_key, out client_salt, out server_key, out server_salt);
        if (client_key == null || client_salt == null || server_key == null || server_salt == null) {
            warning("SRTP client/server key/salt null");
        }

        if (server) {
            srtp_session.set_encryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, server_key.extract(), server_salt.extract());
            srtp_session.set_decryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, client_key.extract(), client_salt.extract());
        } else {
            srtp_session.set_encryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, client_key.extract(), client_salt.extract());
            srtp_session.set_decryption_key(Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, server_key.extract(), server_salt.extract());
        }
    }

    private static ssize_t pull_function(void* transport_ptr, uint8[] buffer) {
        DtlsSrtp self = transport_ptr as DtlsSrtp;

        self.buffer_mutex.lock();
        while (self.buffer_queue.size == 0) {
            self.buffer_cond.wait(self.buffer_mutex);
        }
        owned Bytes data = self.buffer_queue.remove_at(0);
        self.buffer_mutex.unlock();

        uint8[] data_uint8 = Bytes.unref_to_data(data);
        Memory.copy(buffer, data_uint8, data_uint8.length);

        // The callback should return 0 on connection termination, a positive number indicating the number of bytes received, and -1 on error.
        return (ssize_t)data.length;
    }

    private static int pull_timeout_function(void* transport_ptr, uint ms) {
        DtlsSrtp self = transport_ptr as DtlsSrtp;

        DateTime current_time = new DateTime.now_utc();
        current_time.add_seconds(ms/1000);
        int64 end_time = current_time.to_unix();

        self.buffer_mutex.lock();
        while (self.buffer_queue.size == 0) {
            self.buffer_cond.wait_until(self.buffer_mutex, end_time);

            DateTime new_current_time = new DateTime.now_utc();
            if (new_current_time.compare(current_time) > 0) {
                break;
            }
        }
        self.buffer_mutex.unlock();

        // The callback should return 0 on timeout, a positive number if data can be received, and -1 on error.
        return 1;
    }

    private static ssize_t push_function(void* transport_ptr, uint8[] buffer) {
        DtlsSrtp self = transport_ptr as DtlsSrtp;
        self.send_data(buffer);

        // The callback should return a positive number indicating the bytes sent, and -1 on error.
        return (ssize_t)buffer.length;
    }

    private static int verify_function(Session session) {
        DtlsSrtp self = session.get_transport_pointer() as DtlsSrtp;
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

        string peer_fp_str = format_certificate(peer_cert, DigestAlgorithm.SHA256);
        if (peer_fp_str.down() != this.peer_fingerprint.down()) {
            warning("First cert in peer cert list doesn't equal advertised one %s vs %s", peer_fp_str, this.peer_fingerprint);
            return false;
        }

        return true;
    }

    private string format_certificate(X509.Certificate certificate, DigestAlgorithm digest_algo) {
        uint8[] buf = new uint8[512];
        size_t buf_out_size = 512;
        certificate.get_fingerprint(digest_algo, buf, ref buf_out_size);

        var sb = new StringBuilder();
        for (int i = 0; i < buf_out_size; i++) {
            sb.append("%02x".printf(buf[i]));
            if (i < buf_out_size - 1) {
                sb.append(":");
            }
        }
        return sb.str;
    }

    private uint8[] uint8_pt_to_a(uint8* data, uint size) {
        uint8[size] ret = new uint8[size];
        for (int i = 0; i < size; i++) {
            ret[i] = data[i];
        }
        return ret;
    }
}