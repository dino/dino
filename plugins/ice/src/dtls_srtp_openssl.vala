using OpenSSL;

namespace Dino.Plugins.Ice.DtlsSrtp {

public class CredentialsCapsuleOpenSSL : CredentialsCapsule {
    public X509.Certificate own_cert;
    public EVP.Key private_key;
}

internal CredentialsCapsule generate_credentials () throws GLib.Error {
    EVP.Key key = new EVP.Key.generate_ecdsa ("prime256v1");

    var start_time = new DateTime.now_local().add_days(-1);
    var end_time = start_time.add_days (2);

    X509.Certificate cert = new X509.Certificate ();
    cert.set_public_key (key);
    cert.set_version (1);
    cert.not_before.set ((time_t) start_time.to_unix ());
    cert.not_after.set ((time_t) end_time.to_unix ());
    cert.serial_number.set (1);

    cert.sign (key, EVP.sha256 ());

    CredentialsCapsuleOpenSSL credentials = new CredentialsCapsuleOpenSSL ();
    credentials.own_fingerprint = cert.digest (EVP.sha256 ());
    credentials.own_cert = (owned) cert;
    credentials.private_key = (owned) key;
    return credentials;
}

public class Handler : AbstractHandler {

    public Handler.with_cert (CredentialsCapsule creds) {
        base.with_cert (creds);
    }

    protected override Xmpp.Xep.Jingle.ContentEncryption? setup_dtls_connection_thread () {
        debug("Setting up DTLS connection using OpenSSL. We're %s", mode.to_string());
        SSL.Context context = new SSL.Context (mode == Mode.SERVER ? SSL.Method.DTLS_SERVER : SSL.Method.DTLS_CLIENT);
        context.set_tlsext_use_srtp ("SRTP_AES128_CM_SHA1_80");
        context.use_certificate (((CredentialsCapsuleOpenSSL) credentials).own_cert);
        context.use_private_key (((CredentialsCapsuleOpenSSL) credentials).private_key);
        SSL session = new SSL (context);
        BIO<Handler> bio = new BIO<Handler>(get_handler_based_bio_method());
        bio.data = this;
        session.rbio = bio;
        session.wbio = bio;

        DateTime maximum_time = new DateTime.now_utc().add_seconds(20);
        int err = 0;
        if (mode == Mode.SERVER) {
            session.set_accept_state ();
        } else {
            session.set_connect_state ();
        }
        do {
            try {
                SSL.Error ret = session.do_handshake();
                switch (ret) {
                    case SSL.Error.NONE:
                        err = 1;
                        break;
                    case SSL.Error.WANT_READ:
                        debug ("DTLS wants to read, but nothing in queue, wait for buffer");
                        buffer_mutex.lock();
                        if (buffer_queue.size == 0) {
                            buffer_cond.wait_until(buffer_mutex, get_monotonic_time() + maximum_time.difference(new DateTime.now_utc()));
                        }
                        buffer_mutex.unlock();
                        err = -1;
                        break;
                    default:
                        warning ("DTLS Error: %s", @"$ret");
                        err = 4;
                        break;
                }
            } catch (Error e) {
                warning ("DTLS Error: %s", e.message);
                err = e.code;
            }

            DateTime current_time = new DateTime.now_utc();
            if (maximum_time.compare(current_time) < 0) {
                debug ("DTLS handshake timeouted");
                err = 2;
                break;
            }
            if (stop) {
                debug ("DTLS handshake stopped");
                err = 3;
                break;
            }
        } while (err < 0);

        buffer_mutex.lock();
        if (stop) {
            stop = false;
            running = false;
            bool restart = restart;
            buffer_mutex.unlock();
            if (restart) {
                debug ("Restarting DTLS handshake");
                return setup_dtls_connection_thread();
            }
            return null;
        }
        buffer_mutex.unlock();
        if (err != 1) {
            debug ("DTLS handshake failed");
            return null;
        }

        // TODO: Check peer certificate

        uint8[] km = new uint8[60];
        session.export_keying_material (km, "EXTRACTOR-dtls_srtp");
        uint8[] client_key = km[0:16];
        uint8[] server_key = km[16:32];
        uint8[] client_salt = km[32:46];
        uint8[] server_salt = km[46:60];

        debug ("Finished DTLS connection. We're %s", mode.to_string());
        if (mode == Mode.SERVER) {
            srtp_session.set_encryption_key (Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, server_key, server_salt);
            srtp_session.set_decryption_key (Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, client_key, client_salt);
        } else {
            srtp_session.set_encryption_key (Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, client_key, client_salt);
            srtp_session.set_decryption_key (Crypto.Srtp.AES_CM_128_HMAC_SHA1_80, server_key, server_salt);
        }
        return new Xmpp.Xep.Jingle.ContentEncryption (Xmpp.Xep.JingleIceUdp.DTLS_NS_URI, "DTLS-SRTP", credentials.own_fingerprint, peer_fingerprint);
    }

    private int read_impl (BIO<Handler> bio, uint8[] out_buf) {
        Bytes data = get_buffer_if_present ();
        if (data == null) {
            if (!stop) {
                debug ("No pending buffer in queue, but end not reached yet, set_retry_read");
                bio.set_retry_read ();
            }
            return -1;
        }
        if (data.length > out_buf.length) {
            warning ("Buffer in queue does not fit in out_buf");
            return -1;
        }
        debug ("Read %d bytes from queue", data.length);

        uint8[] data_uint8 = Bytes.unref_to_data((owned) data);
        Memory.copy (out_buf, data_uint8, data_uint8.length);
        bio.clear_retry_flags ();
        return data_uint8.length;
    }

    private int write_impl (BIO<Handler> bio, uint8[] buf) {
        debug ("Write %d bytes to network", buf.length);
        send_data (buf);
        return buf.length;
    }

    private long ctrl_impl (BIO<Handler> bio, BIO.ControlCommand cmd, long num, void* ptr) {
        switch (cmd) {
            case BIO.ControlCommand.FLUSH:
                // Datagrams are sent out immediately
                return 1;
            case BIO.ControlCommand.DGRAM_SET_NEXT_TIMEOUT:
                // Datagrams are sent out immediately
                return 1;
            case BIO.ControlCommand.DGRAM_GET_MTU_OVERHEAD:
                // Just some safe estimate
                return 70;
            case BIO.ControlCommand.DGRAM_QUERY_MTU:
                // Just some safe estimate
                return 1200;
            case BIO.ControlCommand.WPENDING:
                // Datagrams are sent out immediately
                return 0;
            case BIO.ControlCommand.POP:
            case BIO.ControlCommand.PUSH:
                // Ignored
                return 0;
            default:
                warning (@"Unimplemented ctrl cmd:$cmd, num:$num");
                return 0;
        }
    }

    private static BIO.Method<Handler> _handler_based_bio_method_instance = null;

    private static unowned BIO.Method<Handler> get_handler_based_bio_method () {
        if (_handler_based_bio_method_instance != null) return _handler_based_bio_method_instance;
        _handler_based_bio_method_instance = new BIO.Method<Handler> (BIO.Type.SOURCE_SINK | BIO.Type.DGRAM, "Dino DTLS Handler BIO");
        _handler_based_bio_method_instance.read = (bio, out_buf) => bio.data.read_impl (bio, out_buf);
        _handler_based_bio_method_instance.write = (bio, buf) => bio.data.write_impl (bio, buf);
        _handler_based_bio_method_instance.ctrl = (bio, cmd, num, ptr) => bio.data.ctrl_impl (bio, cmd, num, ptr);
        return _handler_based_bio_method_instance;
    }
}



}