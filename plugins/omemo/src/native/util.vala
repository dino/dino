namespace Omemo {

public ECPublicKey generate_public_key(ECPrivateKey private_key) throws Error {
    ECPublicKey public_key;
    throw_by_code(ECPublicKey.generate(out public_key, private_key), "Error generating public key");

    return public_key;
}

public uint8[] calculate_agreement(ECPublicKey public_key, ECPrivateKey private_key) throws Error {
    uint8[] res;
    int len = Curve.calculate_agreement(out res, public_key, private_key);
    throw_by_code(len, "Error calculating agreement");
    res.length = len;
    return res;
}

public bool verify_signature(ECPublicKey signing_key, uint8[] message, uint8[] signature) throws Error {
    return throw_by_code(Curve.verify_signature(signing_key, message, signature)) == 1;
}

public PreKeyBundle create_pre_key_bundle(uint32 registration_id, int device_id, uint32 pre_key_id, ECPublicKey? pre_key_public,
        uint32 signed_pre_key_id, ECPublicKey? signed_pre_key_public, uint8[]? signed_pre_key_signature, ECPublicKey? identity_key) throws Error {
    PreKeyBundle res;
    throw_by_code(PreKeyBundle.create(out res, registration_id, device_id, pre_key_id, pre_key_public, signed_pre_key_id, signed_pre_key_public, signed_pre_key_signature, identity_key), "Error creating PreKeyBundle");
    return res;
}

internal string carr_to_string(char[] carr) {
    char[] nu = new char[carr.length + 1];
    Memory.copy(nu, carr, carr.length);
    return (string) nu;
}

internal delegate int CodeErroringFunc() throws Error;

internal int catch_to_code(CodeErroringFunc func) {
    try {
        return func();
    } catch (Error e) {
        return e.code;
    }
}

}