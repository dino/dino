using Gee;
using Signal;
using Xmpp;

namespace Dino.Plugins.Omemo {

public class Bundle {
    private StanzaNode? node;

    public Bundle(StanzaNode? node) {
        this.node = node;
        assert(Plugin.ensure_context());
    }

    public int32 signed_pre_key_id { owned get {
        if (node == null) return -1;
        string? id = ((!)node).get_deep_attribute("signedPreKeyPublic", "signedPreKeyId");
        if (id == null) return -1;
        return int.parse((!)id);
    }}

    public ECPublicKey? signed_pre_key { owned get {
        if (node == null) return null;
        string? key = ((!)node).get_deep_string_content("signedPreKeyPublic");
        if (key == null) return null;
        try {
            return Plugin.get_context().decode_public_key(Base64.decode((!)key));
        } catch (Error e) {
            return null;
        }
    }}

    public uint8[]? signed_pre_key_signature { owned get {
        if (node == null) return null;
        string? sig = ((!)node).get_deep_string_content("signedPreKeySignature");
        if (sig == null) return null;
        return Base64.decode((!)sig);
    }}

    public ECPublicKey? identity_key { owned get {
        if (node == null) return null;
        string? key = ((!)node).get_deep_string_content("identityKey");
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
        ((!)node).get_deep_subnodes("prekeys", "preKeyPublic")
                .filter((node) => ((!)node).get_attribute("preKeyId") != null)
                .map<PreKey>(PreKey.create)
                .foreach((key) => list.add(key));
        return list;
    }}

    public class PreKey {
        private StanzaNode node;

        public static PreKey create(owned StanzaNode node) {
            return new PreKey(node);
        }

        public PreKey(StanzaNode node) {
            this.node = node;
        }

        public int32 key_id { owned get {
            return int.parse(node.get_attribute("preKeyId") ?? "-1");
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