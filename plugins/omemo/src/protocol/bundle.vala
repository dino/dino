using Gee;
using Omemo;
using Xmpp;

namespace Dino.Plugins.Omemo {

public class Bundle {
    public StanzaNode? node;

    public Bundle(StanzaNode? node) {
        this.node = node;
        assert(Plugin.ensure_context());
    }

    public ProtocolVersion version { get {
        switch(node.ns_uri) {
            case Legacy.NS_URI: return ProtocolVersion.LEGACY;
            case V1.NS_URI: return ProtocolVersion.V1;
        }
        return ProtocolVersion.UNKNOWN;
    }}

    public int32 signed_pre_key_id { owned get {
        if (node == null) return -1;
        string? id = null;
        switch(version) {
            case ProtocolVersion.LEGACY:
                id = ((!)node).get_deep_attribute("signedPreKeyPublic", "signedPreKeyId");
                break;
            case ProtocolVersion.V1:
                id = ((!)node).get_deep_attribute("spk", "id");
                break;
        }
        if (id == null) return -1;
        return int.parse((!)id);
    }}

    public ECPublicKey? signed_pre_key { owned get {
        if (node == null) return null;
        string? key = null;
        switch(version) {
            case ProtocolVersion.LEGACY:
                key = ((!)node).get_deep_string_content("signedPreKeyPublic");
                break;
            case ProtocolVersion.V1:
                key = ((!)node).get_deep_string_content("spk");
                break;
        }
        if (key == null) return null;
        try {
            return Plugin.get_context().decode_public_key(Base64.decode((!)key));
        } catch (Error e) {
            return null;
        }
    }}

    public uint8[]? signed_pre_key_signature { owned get {
        if (node == null) return null;
        string? sig = null;
        switch(version) {
            case ProtocolVersion.LEGACY:
                sig = ((!)node).get_deep_string_content("signedPreKeySignature");
                break;
            case ProtocolVersion.V1:
                sig = ((!)node).get_deep_string_content("spks");
                break;
        }
        if (sig == null) return null;
        return Base64.decode((!)sig);
    }}

    public ECPublicKey? identity_key { owned get {
        if (node == null) return null;
        string? key = null;
        switch(version) {
            case ProtocolVersion.LEGACY:
                key = ((!)node).get_deep_string_content("identityKey");
                break;
            case ProtocolVersion.V1:
                key = ((!)node).get_deep_string_content("ik");
                break;
        }
        if (key == null) return null;
        try {
            return Plugin.get_context().decode_public_key(Base64.decode((!)key));
        } catch (Error e) {
            return null;
        }
    }}

    public ArrayList<PreKey> pre_keys { owned get {
        ArrayList<PreKey> list = new ArrayList<PreKey>();
        if (node == null || ((!)node).get_subnode("prekeys") == null) return list;

        switch(version) {
            case ProtocolVersion.LEGACY:
                ((!)node).get_deep_subnodes("prekeys", "preKeyPublic")
                        .filter((node) => ((!)node).get_attribute("preKeyId") != null)
                        .map<PreKey>(PreKey.create)
                        .foreach((key) => list.add(key));
                break;
            case ProtocolVersion.V1:
                ((!)node).get_deep_subnodes("prekeys", "pk")
                        .filter((node) => ((!)node).get_attribute("id") != null)
                        .map<PreKey>(PreKey.create)
                        .foreach((key) => list.add(key));
                break;
        }
        return list;
    }}

    public class PreKey {
        private StanzaNode node;

        public static PreKey create(owned StanzaNode node) {
            return new PreKey(node);
        }

        public ProtocolVersion version { get {
            switch(node.ns_uri) {
                case Legacy.NS_URI: return ProtocolVersion.LEGACY;
                case V1.NS_URI: return ProtocolVersion.V1;
            }
            return ProtocolVersion.UNKNOWN;
        }}

        public PreKey(StanzaNode node) {
            this.node = node;
        }

        public int32 key_id { owned get {
            switch(version) {
                case ProtocolVersion.LEGACY:
                   return int.parse(node.get_attribute("preKeyId") ?? "-1");
                case ProtocolVersion.V1:
                    return int.parse(node.get_attribute("id") ?? "-1");
            }
            return -1;
        }}

        public ECPublicKey? key { owned get {
            string? key = node.get_string_content();
            if (key == null) return null;
            try {
                return Plugin.get_context().decode_public_key(Base64.decode((!)key));
            } catch (Error e) {
                return null;
            }
        }}
    }
}

}
