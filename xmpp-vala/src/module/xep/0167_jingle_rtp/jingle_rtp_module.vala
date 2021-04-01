using Gee;
using Xmpp;
using Xmpp.Xep;

namespace Xmpp.Xep.JingleRtp {

public const string NS_URI = "urn:xmpp:jingle:apps:rtp:1";
public const string NS_URI_AUDIO = "urn:xmpp:jingle:apps:rtp:audio";
public const string NS_URI_VIDEO = "urn:xmpp:jingle:apps:rtp:video";

public abstract class Module : XmppStreamModule {
    public static Xmpp.ModuleIdentity<Module> IDENTITY = new Xmpp.ModuleIdentity<Module>(NS_URI, "0167_jingle_rtp");

    private ContentType content_type;
    public SessionInfoType session_info_type = new SessionInfoType();

    protected Module() {
        content_type = new ContentType(this);
    }

    public abstract async Gee.List<PayloadType> get_supported_payloads(string media);
    public abstract async PayloadType? pick_payload_type(string media, Gee.List<PayloadType> payloads);
    public abstract Crypto? generate_local_crypto();
    public abstract Crypto? pick_remote_crypto(Gee.List<Crypto> cryptos);
    public abstract Crypto? pick_local_crypto(Crypto? remote);
    public abstract Stream create_stream(Jingle.Content content);
    public abstract void close_stream(Stream stream);

    public async Jingle.Session start_call(XmppStream stream, Jid receiver_full_jid, bool video, string? sid = null) throws Jingle.Error {

        Jingle.Module jingle_module = stream.get_module(Jingle.Module.IDENTITY);

        Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
        if (my_jid == null) {
            throw new Jingle.Error.GENERAL("Couldn't determine own JID");
        }

        ArrayList<Jingle.Content> contents = new ArrayList<Jingle.Content>();

        // Create audio content
        Parameters audio_content_parameters = new Parameters(this, "audio", yield get_supported_payloads("audio"));
        audio_content_parameters.local_crypto = generate_local_crypto();
        Jingle.Transport? audio_transport = yield jingle_module.select_transport(stream, content_type.required_transport_type, content_type.required_components, receiver_full_jid, Set.empty());
        if (audio_transport == null) {
            throw new Jingle.Error.NO_SHARED_PROTOCOLS("No suitable audio transports");
        }
        Jingle.TransportParameters audio_transport_params = audio_transport.create_transport_parameters(stream, content_type.required_components, my_jid, receiver_full_jid);
        Jingle.Content audio_content = new Jingle.Content.initiate_sent("voice", Jingle.Senders.BOTH,
                content_type, audio_content_parameters,
                audio_transport, audio_transport_params,
                null, null,
                my_jid, receiver_full_jid);
        contents.add(audio_content);

        Jingle.Content? video_content = null;
        if (video) {
            // Create video content
            Parameters video_content_parameters = new Parameters(this, "video", yield get_supported_payloads("video"));
            video_content_parameters.local_crypto = generate_local_crypto();
            Jingle.Transport? video_transport = yield stream.get_module(Jingle.Module.IDENTITY).select_transport(stream, content_type.required_transport_type, content_type.required_components, receiver_full_jid, Set.empty());
            if (video_transport == null) {
                throw new Jingle.Error.NO_SHARED_PROTOCOLS("No suitable video transports");
            }
            Jingle.TransportParameters video_transport_params = video_transport.create_transport_parameters(stream, content_type.required_components, my_jid, receiver_full_jid);
            video_content = new Jingle.Content.initiate_sent("webcam", Jingle.Senders.BOTH,
                    content_type, video_content_parameters,
                    video_transport, video_transport_params,
                    null, null,
                    my_jid, receiver_full_jid);
            contents.add(video_content);
        }

        // Create session
        try {
            Jingle.Session session = yield jingle_module.create_session(stream, contents, receiver_full_jid, sid);
            return session;
        } catch (Jingle.Error e) {
            throw new Jingle.Error.GENERAL(@"Couldn't create Jingle session: $(e.message)");
        }
    }

    public async Jingle.Content add_outgoing_video_content(XmppStream stream, Jingle.Session session) {
        Jid my_jid = session.local_full_jid;
        Jid receiver_full_jid = session.peer_full_jid;

        Jingle.Content? content = null;
        foreach (Jingle.Content c in session.contents) {
            Parameters? parameters = c.content_params as Parameters;
            if (parameters == null) continue;

            if (parameters.media == "video") {
                content = c;
                break;
            }
        }

        if (content == null) {
            // Content for video does not yet exist -> create it
            Parameters video_content_parameters = new Parameters(this, "video", yield get_supported_payloads("video"));
            video_content_parameters.local_crypto = generate_local_crypto();
            Jingle.Transport? video_transport = yield stream.get_module(Jingle.Module.IDENTITY).select_transport(stream, content_type.required_transport_type, content_type.required_components, receiver_full_jid, Set.empty());
            if (video_transport == null) {
                throw new Jingle.Error.NO_SHARED_PROTOCOLS("No suitable video transports");
            }
            Jingle.TransportParameters video_transport_params = video_transport.create_transport_parameters(stream, content_type.required_components, my_jid, receiver_full_jid);
            content = new Jingle.Content.initiate_sent("webcam",
                    session.we_initiated ? Jingle.Senders.INITIATOR : Jingle.Senders.RESPONDER,
                    content_type, video_content_parameters,
                    video_transport, video_transport_params,
                    null, null,
                    my_jid, receiver_full_jid);

            session.add_content.begin(content);
        } else {
            // Content for video already exists -> modify senders
            bool we_initiated = session.we_initiated;
            Jingle.Senders want_sender = we_initiated ? Jingle.Senders.INITIATOR : Jingle.Senders.RESPONDER;
            if (content.senders == Jingle.Senders.BOTH || content.senders == want_sender) {
                warning("want to add video but senders is already both/target");
            } else if (content.senders == Jingle.Senders.NONE) {
                content.modify(want_sender);
            } else {
                content.modify(Jingle.Senders.BOTH);
            }
        }

        return content;
    }

    public override void attach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI_AUDIO);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).add_feature(stream, NS_URI_VIDEO);
        stream.get_module(Jingle.Module.IDENTITY).register_content_type(content_type);
        stream.get_module(Jingle.Module.IDENTITY).register_session_info_type(session_info_type);
    }

    public override void detach(XmppStream stream) {
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI_AUDIO);
        stream.get_module(ServiceDiscovery.Module.IDENTITY).remove_feature(stream, NS_URI_VIDEO);
    }

    public async bool is_available(XmppStream stream, Jid full_jid) {
        bool? has_feature = yield stream.get_module(ServiceDiscovery.Module.IDENTITY).has_entity_feature(stream, full_jid, NS_URI);
        if (has_feature == null || !(!)has_feature) {
            return false;
        }
        return yield stream.get_module(Jingle.Module.IDENTITY).is_available(stream, content_type.required_transport_type, content_type.required_components, full_jid);
    }

    public override string get_ns() { return NS_URI; }
    public override string get_id() { return IDENTITY.id; }
}

public class Crypto {
    public const string AES_CM_128_HMAC_SHA1_80 = "AES_CM_128_HMAC_SHA1_80";
    public const string AES_CM_128_HMAC_SHA1_32 = "AES_CM_128_HMAC_SHA1_32";
    public const string F8_128_HMAC_SHA1_80 = "F8_128_HMAC_SHA1_80";

    public string crypto_suite { get; private set; }
    public string key_params { get; private set; }
    public string? session_params { get; private set; }
    public string tag { get; private set; }

    public uint8[] key_and_salt { owned get {
        if (!key_params.has_prefix("inline:")) return null;
        int endIndex = key_params.index_of("|");
        if (endIndex < 0) endIndex = key_params.length;
        string sub = key_params.substring(7, endIndex - 7);
        return Base64.decode(sub);
    }}

    public string? lifetime { owned get {
        if (!key_params.has_prefix("inline:")) return null;
        int firstIndex = key_params.index_of("|");
        if (firstIndex < 0) return null;
        int endIndex = key_params.index_of("|", firstIndex + 1);
        if (endIndex < 0) {
            if (key_params.index_of(":", firstIndex) > 0) return null; // Is MKI
            endIndex = key_params.length;
        }
        return key_params.substring(firstIndex + 1, endIndex);
    }}

    public int mki { get {
        if (!key_params.has_prefix("inline:")) return -1;
        int firstIndex = key_params.index_of("|");
        if (firstIndex < 0) return -1;
        int splitIndex = key_params.index_of(":", firstIndex);
        if (splitIndex < 0) return -1;
        int secondIndex = key_params.index_of("|", firstIndex + 1);
        if (secondIndex < 0) {
            return int.parse(key_params.substring(firstIndex + 1, splitIndex));
        } else if (splitIndex > secondIndex) {
            return int.parse(key_params.substring(secondIndex + 1, splitIndex));
        }
        return -1;
    }}

    public int mki_length { get {
        if (!key_params.has_prefix("inline:")) return -1;
        int firstIndex = key_params.index_of("|");
        if (firstIndex < 0) return -1;
        int splitIndex = key_params.index_of(":", firstIndex);
        if (splitIndex < 0) return -1;
        int secondIndex = key_params.index_of("|", firstIndex + 1);
        if (secondIndex < 0 || splitIndex > secondIndex) {
            return int.parse(key_params.substring(splitIndex + 1, key_params.length));
        }
        return -1;
    }}

    public bool is_valid { get {
        switch(crypto_suite) {
            case AES_CM_128_HMAC_SHA1_80:
            case AES_CM_128_HMAC_SHA1_32:
            case F8_128_HMAC_SHA1_80:
                return key_and_salt.length == 30;
        }
        return false;
    }}

    public uint8[] key { owned get {
        uint8[] key_and_salt = key_and_salt;
        switch(crypto_suite) {
            case AES_CM_128_HMAC_SHA1_80:
            case AES_CM_128_HMAC_SHA1_32:
            case F8_128_HMAC_SHA1_80:
                if (key_and_salt.length >= 16) return key_and_salt[0:16];
                break;
        }
        return null;
    }}

    public uint8[] salt { owned get {
        uint8[] keyAndSalt = key_and_salt;
        switch(crypto_suite) {
            case AES_CM_128_HMAC_SHA1_80:
            case AES_CM_128_HMAC_SHA1_32:
            case F8_128_HMAC_SHA1_80:
                if (keyAndSalt.length >= 30) return keyAndSalt[16:30];
                break;
        }
        return null;
    }}

    public static Crypto create(string crypto_suite, uint8[] key_and_salt, string? session_params = null, string tag = "1") {
        Crypto crypto = new Crypto();
        crypto.crypto_suite = crypto_suite;
        crypto.key_params = "inline:" + Base64.encode(key_and_salt);
        crypto.session_params = session_params;
        crypto.tag = tag;
        return crypto;
    }

    public Crypto rekey(uint8[] key_and_salt) {
        Crypto crypto = new Crypto();
        crypto.crypto_suite = crypto_suite;
        crypto.key_params = "inline:" + Base64.encode(key_and_salt);
        crypto.session_params = session_params;
        crypto.tag = tag;
        return crypto;
    }

    public static Crypto parse(StanzaNode node) {
        Crypto crypto = new Crypto();
        crypto.crypto_suite = node.get_attribute("crypto-suite");
        crypto.key_params = node.get_attribute("key-params");
        crypto.session_params = node.get_attribute("session-params");
        crypto.tag = node.get_attribute("tag");
        return crypto;
    }

    public StanzaNode to_xml() {
        StanzaNode node = new StanzaNode.build("crypto", NS_URI)
                .put_attribute("crypto-suite", crypto_suite)
                .put_attribute("key-params", key_params)
                .put_attribute("tag", tag);
        if (session_params != null) node.put_attribute("session-params", session_params);
        return node;
    }
}

}
