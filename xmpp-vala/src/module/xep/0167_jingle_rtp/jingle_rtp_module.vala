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
    public abstract Stream create_stream(Jingle.Content content);
    public abstract void close_stream(Stream stream);

    public async Jingle.Session start_call(XmppStream stream, Jid receiver_full_jid, bool video) throws Jingle.Error {

        Jingle.Module jingle_module = stream.get_module(Jingle.Module.IDENTITY);

        Jid? my_jid = stream.get_flag(Bind.Flag.IDENTITY).my_jid;
        if (my_jid == null) {
            throw new Jingle.Error.GENERAL("Couldn't determine own JID");
        }

        ArrayList<Jingle.Content> contents = new ArrayList<Jingle.Content>();

        // Create audio content
        Parameters audio_content_parameters = new Parameters(this, "audio", yield get_supported_payloads("audio"));
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
            Jingle.Session session = yield jingle_module.create_session(stream, contents, receiver_full_jid);
            return session;
        } catch (Jingle.Error e) {
            throw new Jingle.Error.GENERAL(@"Couldn't create Jingle session: $(e.message)");
        }
    }

    public async Jingle.Content add_outgoing_video_content(XmppStream stream, Jingle.Session session) {
        Jid my_jid = session.local_full_jid;
        Jid receiver_full_jid = session.peer_full_jid;

        Jingle.Content? content = null;
        foreach (Jingle.Content c in session.contents.values) {
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
    public string cryptoSuite { get; private set; }
    public string keyParams { get; private set; }
    public string? sessionParams { get; private set; }
    public string? tag { get; private set; }

    public static Crypto parse(StanzaNode node) {
        Crypto crypto = new Crypto();
        crypto.cryptoSuite = node.get_attribute("crypto-suite");
        crypto.keyParams = node.get_attribute("key-params");
        crypto.sessionParams = node.get_attribute("session-params");
        crypto.tag = node.get_attribute("tag");
        return crypto;
    }

    public StanzaNode to_xml() {
        StanzaNode node = new StanzaNode.build("crypto", NS_URI)
                .put_attribute("crypto-suite", cryptoSuite)
                .put_attribute("key-params", keyParams);
        if (sessionParams != null) node.put_attribute("session-params", sessionParams);
        if (tag != null) node.put_attribute("tag", tag);
        return node;
    }
}

}
