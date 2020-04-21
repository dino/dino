using Gee;
using Xmpp.Xep.Jingle;

namespace Xmpp.Xep.Jet {
public const string NS_URI = "urn:xmpp:jingle:jet:0";

public class Module : XmppStreamModule, SecurityPrecondition {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0391_jet");
    private HashMap<string, EnvelopEncoding> envelop_encodings = new HashMap<string, EnvelopEncoding>();
    private HashMap<string, Cipher> ciphers = new HashMap<string, Cipher>();

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(Jingle.Module.IDENTITY).register_security_precondition(this);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
    }

    public bool is_available(XmppStream stream, Jid full_jid) {
        bool? has_feature = stream.get_flag(ServiceDiscovery.Flag.IDENTITY).has_entity_feature(full_jid, NS_URI);
        return has_feature != null && (!)has_feature;
    }

    public void register_envelop_encoding(EnvelopEncoding encoding) {
        envelop_encodings[encoding.get_type_uri()] = encoding;
    }

    public void register_cipher(Cipher cipher) {
        ciphers[cipher.get_cipher_uri()] = cipher;
    }

    public string security_ns_uri() {
        return NS_URI;
    }

    public Jingle.SecurityParameters? create_security_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, Object options) throws Jingle.Error requires (options is Options) {
        Options jet_options = (Options) options;
        string cipher = jet_options.cipher_uri;
        string type = jet_options.type_uri;
        if (!envelop_encodings.has_key(type) || !ciphers.has_key(cipher)) {
            throw new Jingle.Error.UNSUPPORTED_SECURITY("JET cipher or type unknown");
        }
        EnvelopEncoding encoding = envelop_encodings[type];
        return new SecurityParameters(ciphers[cipher], encoding, ciphers[cipher].generate_random_secret(), jet_options);
    }

    public Jingle.SecurityParameters? parse_security_parameters(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode security) throws IqError {
        string? cipher = security.get_attribute("cipher");
        string? type = security.get_attribute("type");
        if (cipher == null || type == null) {
            throw new IqError.BAD_REQUEST("No cipher or type specified for JET");
        }
        if (!envelop_encodings.has_key(type) || !ciphers.has_key(cipher)) {
            throw new IqError.NOT_IMPLEMENTED("JET cipher or type unknown");
        }
        EnvelopEncoding encoding = envelop_encodings[type];
        TransportSecret secret = encoding.decode_envolop(stream, local_full_jid, peer_full_jid, security);
        return new SecurityParameters(ciphers[cipher], encoding, secret);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Options : Object {
    public string type_uri { get; private set; }
    public string cipher_uri { get; private set; }

    public Options(string type_uri, string cipher_uri) {
        this.type_uri = type_uri;
        this.cipher_uri = cipher_uri;
    }
}

public class SecurityParameters : Jingle.SecurityParameters, Object {
    public Cipher cipher { get; private set; }
    public EnvelopEncoding encoding { get; private set; }
    public TransportSecret secret { get; private set; }
    public Options? options { get; private set; }

    public SecurityParameters(Cipher cipher, EnvelopEncoding encoding, TransportSecret secret, Options? options = null) {
        this.cipher = cipher;
        this.encoding = encoding;
        this.secret = secret;
        this.options = options;
    }

    public string security_ns_uri() {
        return NS_URI;
    }
    public IOStream wrap_stream(IOStream stream) {
        debug("Wrapping stream into encrypted stream for %s/%s", encoding.get_type_uri(), cipher.get_cipher_uri());
        return new EncryptedStream(cipher, secret, stream);
    }
    public StanzaNode to_security_stanza_node(XmppStream stream, Jid local_full_jid, Jid peer_full_jid) {
        StanzaNode security = new StanzaNode.build("security", NS_URI)
                .add_self_xmlns()
                .put_attribute("cipher", cipher.get_cipher_uri())
                .put_attribute("type", encoding.get_type_uri());
        encoding.encode_envelop(stream, local_full_jid, peer_full_jid, this, security);
        return security;
    }
}

public interface Cipher : Object {
    public abstract string get_cipher_uri();
    public abstract TransportSecret generate_random_secret();
    public abstract InputStream wrap_input_stream(InputStream input, TransportSecret secret);
    public abstract OutputStream wrap_output_stream(OutputStream output, TransportSecret secret);
}

private class EncryptedStream : IOStream {
    private IOStream stream;
    private InputStream input;
    private OutputStream output;
    public override InputStream input_stream { get { return input; } }
    public override OutputStream output_stream { get { return output; } }

    public EncryptedStream(Cipher cipher, TransportSecret secret, IOStream stream) {
        this.stream = stream;
        input = cipher.wrap_input_stream(stream.input_stream, secret);
        output = cipher.wrap_output_stream(stream.output_stream, secret);
    }
}

public class TransportSecret {
    public uint8[] transport_key { get; private set; }
    public uint8[] initialization_vector { get; private set; }
    public TransportSecret(uint8[] transport_key, uint8[] initialization_vector) {
        this.transport_key = transport_key;
        this.initialization_vector = initialization_vector;
    }
}

public interface EnvelopEncoding : Object {
    public abstract string get_type_uri();
    public abstract TransportSecret decode_envolop(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, StanzaNode security) throws IqError;
    public abstract void encode_envelop(XmppStream stream, Jid local_full_jid, Jid peer_full_jid, SecurityParameters security_params, StanzaNode security);
}

}
