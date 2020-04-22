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
    private Omemo.Plugin plugin;

    public Module(Omemo.Plugin plugin) {
        this.plugin = plugin;
    }

    public override void attach(XmppStream stream) {
        if (stream.get_module(Jet.Module.IDENTITY) != null) {
            stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
            stream.get_module(Jet.Module.IDENTITY).register_envelop_encoding(this);
            stream.get_module(Jet.Module.IDENTITY).register_cipher(new AesGcmCipher(16, AES_128_GCM_URI));
        }
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

    public bool is_available(XmppStream stream, Jid full_jid) {
        bool? has_feature = stream.get_flag(ServiceDiscovery.Flag.IDENTITY).has_entity_feature(full_jid, NS_URI);
        if (has_feature == null || !(!)has_feature) {
            return false;
        }
        return stream.get_module(Xep.Jet.Module.IDENTITY).is_available(stream, full_jid);
    }

    public string get_type_uri() {
        return Omemo.NS_URI;
    }

    public Jet.TransportSecret decode_envolop(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode security) throws Jingle.IqError {
        Store store = stream.get_module(Omemo.StreamModule.IDENTITY).store;
        StanzaNode? encrypted = security.get_subnode("encrypted", Omemo.NS_URI);
        if (encrypted == null) throw new Jingle.IqError.BAD_REQUEST("Invalid JET-OMEMO envelop: missing encrypted element");
        StanzaNode? header = encrypted.get_subnode("header", Omemo.NS_URI);
        if (header == null) throw new Jingle.IqError.BAD_REQUEST("Invalid JET-OMEMO envelop: missing header element");
        string? iv_node = header.get_deep_string_content("iv");
        if (header == null) throw new Jingle.IqError.BAD_REQUEST("Invalid JET-OMEMO envelop: missing iv element");
        uint8[] iv = Base64.decode((!)iv_node);
        foreach (StanzaNode key_node in header.get_subnodes("key")) {
            if (key_node.get_attribute_int("rid") == store.local_registration_id) {
                string? key_node_content = key_node.get_string_content();

                uint8[] key;
                Address address = new Address(peer_full_jid.bare_jid.to_string(), header.get_attribute_int("sid"));
                if (key_node.get_attribute_bool("prekey")) {
                    PreKeySignalMessage msg = Omemo.Plugin.get_context().deserialize_pre_key_signal_message(Base64.decode((!)key_node_content));
                    SessionCipher cipher = store.create_session_cipher(address);
                    key = cipher.decrypt_pre_key_signal_message(msg);
                } else {
                    SignalMessage msg = Omemo.Plugin.get_context().deserialize_signal_message(Base64.decode((!)key_node_content));
                    SessionCipher cipher = store.create_session_cipher(address);
                    key = cipher.decrypt_signal_message(msg);
                }
                address.device_id = 0; // TODO: Hack to have address obj live longer

                uint8[] authtag = null;
                if (key.length >= 32) {
                    int authtaglength = key.length - 16;
                    authtag = new uint8[authtaglength];
                    uint8[] new_key = new uint8[16];
                    Memory.copy(authtag, (uint8*)key + 16, 16);
                    Memory.copy(new_key, key, 16);
                    key = new_key;
                }
                // TODO: authtag?
                return new Jet.TransportSecret(key, iv);
            }
        }
        throw new Jingle.IqError.NOT_ACCEPTABLE("Not encrypted for targeted device");
    }

    public void encode_envelop(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, Jet.SecurityParameters security_params, StanzaNode security) {
        ArrayList<Account> accounts = plugin.app.stream_interactor.get_accounts();
        Store store = stream.get_module(Omemo.StreamModule.IDENTITY).store;
        Account? account = null;
        foreach (Account compare in accounts) {
            if (compare.bare_jid.equals_bare(local_full_jid)) {
                account = compare;
                break;
            }
        }
        if (account == null) {
            // TODO
            critical("Sending from offline account %s", local_full_jid.to_string());
        }

        StanzaNode header_node;
        StanzaNode encrypted_node = new StanzaNode.build("encrypted", Omemo.NS_URI).add_self_xmlns()
                .put_node(header_node = new StanzaNode.build("header", Omemo.NS_URI)
                    .put_attribute("sid", store.local_registration_id.to_string())
                    .put_node(new StanzaNode.build("iv", Omemo.NS_URI)
                        .put_node(new StanzaNode.text(Base64.encode(security_params.secret.initialization_vector)))));

        plugin.trust_manager.encrypt_key(header_node, security_params.secret.transport_key, local_full_jid.bare_jid, new ArrayList<Jid>.wrap(new Jid[] {peer_full_jid.bare_jid}), stream, account);
        security.put_node(encrypted_node);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class AesGcmCipher : Jet.Cipher, Object {
    private int key_size;
    private string uri;
    public AesGcmCipher(int key_size, string uri) {
        this.key_size = key_size;
        this.uri = uri;
    }
    public string get_cipher_uri() {
        return uri;
    }
    public Jet.TransportSecret generate_random_secret() {
        uint8[] iv = new uint8[16];
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
