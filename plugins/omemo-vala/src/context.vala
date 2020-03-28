namespace Omemo {

public class Context {
    internal NativeContext native_context;
    private RecMutex mutex = RecMutex();

    static void locking_function_lock(void* user_data) {
        Context ctx = (Context) user_data;
        ctx.mutex.lock();
    }

    static void locking_function_unlock(void* user_data) {
        Context ctx = (Context) user_data;
        ctx.mutex.unlock();
    }

    static void stderr_log(LogLevel level, string message, size_t len, void* user_data) {
        printerr(@"$level: $message\n");
    }

    public Context(bool log = false) throws Error {
        throw_by_code(NativeContext.create(out native_context, this), "Error initializing native context");
        throw_by_code(native_context.set_locking_functions(locking_function_lock, locking_function_unlock), "Error initializing native locking functions");
        if (log) native_context.set_log_function(stderr_log);
        setup_crypto_provider(native_context);
    }

    public Store create_store() {
        return new Store(this);
    }

    public void randomize(uint8[] data) throws Error {
        throw_by_code(native_random(data));
    }

    public SignedPreKeyRecord generate_signed_pre_key(IdentityKeyPair identity_key_pair, int32 id, uint64 timestamp = 0) throws Error {
        if (timestamp == 0) timestamp = new DateTime.now_utc().to_unix();
        SignedPreKeyRecord res;
        throw_by_code(Protocol.KeyHelper.generate_signed_pre_key(out res, identity_key_pair, id, timestamp, native_context));
        return res;
    }

    public Gee.Set<PreKeyRecord> generate_pre_keys(uint start, uint count) throws Error {
        Gee.Set<PreKeyRecord> res = new Gee.HashSet<PreKeyRecord>();
        for(uint i = start; i < start+count; i++) {
            ECKeyPair pair = generate_key_pair();
            PreKeyRecord record;
            throw_by_code(PreKeyRecord.create(out record, i, pair));
            res.add(record);
        }
        return res;
    }

    public ECPublicKey decode_public_key(uint8[] bytes) throws Error {
        ECPublicKey public_key;
        throw_by_code(curve_decode_point(out public_key, bytes, native_context), "Error decoding public key");
        return public_key;
    }

    public ECPrivateKey decode_private_key(uint8[] bytes) throws Error {
        ECPrivateKey private_key;
        throw_by_code(curve_decode_private_point(out private_key, bytes, native_context), "Error decoding private key");
        return private_key;
    }

    public ECKeyPair generate_key_pair() throws Error {
        ECKeyPair key_pair;
        throw_by_code(curve_generate_key_pair(native_context, out key_pair), "Error generating key pair");
        return key_pair;
    }

    public uint8[] calculate_signature(ECPrivateKey signing_key, uint8[] message) throws Error {
        Buffer signature;
        throw_by_code(Curve.calculate_signature(native_context, out signature, signing_key, message), "Error calculating signature");
        return signature.data;
    }

    public SignalMessage deserialize_signal_message(uint8[] data) throws Error {
        SignalMessage res;
        throw_by_code(signal_message_deserialize(out res, data, native_context));
        return res;
    }

    public SignalMessage copy_signal_message(CiphertextMessage original) throws Error {
        SignalMessage res;
        throw_by_code(signal_message_copy(out res, (SignalMessage) original, native_context));
        return res;
    }

    public PreKeySignalMessage deserialize_pre_key_signal_message(uint8[] data) throws Error {
        PreKeySignalMessage res;
        throw_by_code(pre_key_signal_message_deserialize(out res, data, native_context));
        return res;
    }

    public PreKeySignalMessage copy_pre_key_signal_message(CiphertextMessage original) throws Error {
        PreKeySignalMessage res;
        throw_by_code(pre_key_signal_message_copy(out res, (PreKeySignalMessage) original, native_context));
        return res;
    }
}

}
