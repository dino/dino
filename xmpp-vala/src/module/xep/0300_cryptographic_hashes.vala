using GLib;
using Gee;

namespace Xmpp.Xep.CryptographicHashes {
    public const string NS_URI = "urn:xmpp:hashes:2";

    public Gee.List<Hash> get_hashes(StanzaNode node) {
        var hashes = new ArrayList<Hash>();
        foreach (StanzaNode hash_node in node.get_subnodes("hash", NS_URI)) {
            hashes.add(new Hash.from_stanza_node(hash_node));
        }
        return hashes;
    }

    public Gee.List<Hash> get_supported_hashes(Gee.List<Hash> hashes) {
        var ret = new ArrayList<Hash>();
        foreach (Hash hash in hashes) {
            ChecksumType? hash_type = hash_string_to_type(hash.algo);
            if (hash_type != null) {
                ret.add(hash);
            }
        }
        return ret;
    }

    public bool has_supported_hashes(Gee.List<Hash> hashes) {
        foreach (Hash hash in hashes) {
            ChecksumType? hash_type = hash_string_to_type(hash.algo);
            if (hash_type != null) return true;
        }
        return false;
    }

    public class Hash : Object {
        public string algo;
        // hash encoded in Base64
        public string val;

        public Hash.with_checksum(ChecksumType checksum_type, string hash) {
            algo = hash_type_to_string(checksum_type);
            val = hash;
        }

        public Hash.compute(GLib.ChecksumType type, uint8[] data) {
            GLib.Checksum checksum = new GLib.Checksum(type);
            checksum.update(data, data.length);
            // 64 * 8 = 512 (sha-512 is the longest hash variant)
            uint8[] digest = new uint8[64];
            size_t length = digest.length;
            checksum.get_digest(digest, ref length);
            this.algo = hash_type_to_string(type);
            this.val = GLib.Base64.encode(digest[0:length]);
        }

        public StanzaNode to_stanza_node() {
            return new StanzaNode.build("hash", NS_URI).add_self_xmlns()
                    .put_attribute("algo", this.algo)
                    .put_node(new StanzaNode.text(this.val));
        }

        public Hash.from_stanza_node(StanzaNode node) {
            this.algo = node.get_attribute("algo");
            this.val = node.get_string_content();
        }
    }

    public static string hash_type_to_string(ChecksumType type) {
        switch(type) {
            case ChecksumType.MD5:
                return "md5";
            case ChecksumType.SHA1:
                return "sha-1";
            case ChecksumType.SHA256:
                return "sha-256";
            case ChecksumType.SHA384:
                return "sha-384";
            case ChecksumType.SHA512:
                return "sha-512";
        }
        return "(null)";
    }

    public static ChecksumType? hash_string_to_type(string hash) {
        switch (hash) {
            case "sha-1":
                return ChecksumType.SHA1;
            case "sha-256":
                return ChecksumType.SHA256;
            case "sha-384":
                return ChecksumType.SHA384;
            case "sha-512":
                return ChecksumType.SHA512;
        }
        return null;
    }
}
