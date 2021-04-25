using Crypto;
using Dino;
using Dino.Entities;
using Gee;
using Signal;
using Xmpp;
using Xmpp.Xep;

namespace Dino.Plugins.JetOmemo {

private const string NS_URI = "urn:xmpp:jingle:jet-omemo:0";
private const string AES_128_GCM_URI = "urn:xmpp:ciphers:aes-128-gcm-nopadding";

public class Module : XmppStreamModule, Jet.EnvelopEncoding {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0396_jet_omemo");
    const uint KEY_SIZE = 16;
    const uint IV_SIZE = 12;

    public override void attach(XmppStream stream) {
        if (stream.get_module(Jet.Module.IDENTITY) != null) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            stream.get_module(Jet.Module.IDENTITY).register_envelop_encoding(this);
            stream.get_module(Jet.Module.IDENTITY).register_cipher(new AesGcmCipher(KEY_SIZE, IV_SIZE, AES_128_GCM_URI));
        }
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

    public async bool is_available(XmppStream stream, Jid full_jid) {
        bool? has_feature = yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
        if (has_feature == null || !(!)has_feature) {
            return false;
        }
        return yield stream.get_module(Xep.Jet.Module.IDENTITY).is_available(stream, full_jid);
    }

    public string get_type_uri() {
        return Omemo.NS_URI;
    }

    public Jet.TransportSecret decode_envolop(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode security) throws Jingle.IqError {
        StanzaNode? encrypted = security.get_subnode("encrypted", Omemo.NS_URI);
        if (encrypted == null) throw new Jingle.IqError.BAD_REQUEST("Invalid JET-OMEMO envelop: missing encrypted element");

        Xep.Omemo.OmemoDecryptor decryptor = stream.get_module(Xep.Omemo.OmemoDecryptor.IDENTITY);

        Xmpp.Xep.Omemo.ParsedData? data = decryptor.parse_node(encrypted);
        if (data == null)  throw new Jingle.IqError.BAD_REQUEST("Invalid JET-OMEMO envelop: bad encrypted element");

        foreach (Bytes encr_key in data.our_potential_encrypted_keys.keys) {
            data.is_prekey = data.our_potential_encrypted_keys[encr_key];
            data.encrypted_key = encr_key.get_data();

            try {
                uint8[] key = decryptor.decrypt_key(data, peer_full_jid.bare_jid);
                return new Jet.TransportSecret(key, data.iv);
            } catch (GLib.Error e) {
                debug("Decrypting JET key from %s/%d failed: %s", peer_full_jid.bare_jid.to_string(), data.sid, e.message);
            }
        }
        throw new Jingle.IqError.NOT_ACCEPTABLE("Not encrypted for targeted device");
    }

    public void encode_envelop(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, Jet.SecurityParameters security_params, StanzaNode security) {
        Store store = stream.get_module(Omemo.StreamModule.IDENTITY).store;

        var encryption_data = new Xep.Omemo.EncryptionData(store.local_registration_id);
        encryption_data.iv = security_params.secret.initialization_vector;
        encryption_data.keytag = security_params.secret.transport_key;
        Xep.Omemo.OmemoEncryptor encryptor = stream.get_module(Xep.Omemo.OmemoEncryptor.IDENTITY);
        encryptor.encrypt_key_to_recipient(stream, encryption_data, peer_full_jid.bare_jid);

        security.put_node(encryption_data.get_encrypted_node());
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class AesGcmCipher : Jet.Cipher, Object {
    private uint key_size;
    private uint default_iv_size;
    private string uri;
    public AesGcmCipher(uint key_size, uint default_iv_size, string uri) {
        this.key_size = key_size;
        this.default_iv_size = default_iv_size;
        this.uri = uri;
    }
    public string get_cipher_uri() {
        return uri;
    }
    public Jet.TransportSecret generate_random_secret() {
        uint8[] iv = new uint8[default_iv_size];
        Omemo.Plugin.get_context().randomize(iv);
        uint8[] key = new uint8[key_size];
        Omemo.Plugin.get_context().randomize(key);
        return new Jet.TransportSecret(key, iv);
    }
    public InputStream wrap_input_stream(InputStream input, Jet.TransportSecret secret) requires (secret.transport_key.length == key_size) {
        SymmetricCipher cipher = new SymmetricCipher("AES-GCM");
        cipher.set_key(secret.transport_key);
        cipher.set_iv(secret.initialization_vector);
        return new ConverterInputStream(input, new SymmetricCipherDecrypter((owned) cipher, 16));
    }
    public OutputStream wrap_output_stream(OutputStream output, Jet.TransportSecret secret) requires (secret.transport_key.length == key_size) {
        Crypto.SymmetricCipher cipher = new SymmetricCipher("AES-GCM");
        cipher.set_key(secret.transport_key);
        cipher.set_iv(secret.initialization_vector);
        return new ConverterOutputStream(output, new SymmetricCipherEncrypter((owned) cipher, 16));
    }
}
}
