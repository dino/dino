using Gee;
using Xmpp.Xep;
using Xmpp;

namespace Xmpp.Xep.Jingle {

    class ContentNode {
        public Role creator;
        public string name;
        public Senders senders;
        public StanzaNode? description;
        public StanzaNode? transport;
        public StanzaNode? security;
    }

    [Version(deprecated = true)]
    ContentNode get_single_content_node(StanzaNode jingle) throws IqError {
        Gee.List<StanzaNode> contents = jingle.get_subnodes("content");
        if (contents.size == 0) {
            throw new IqError.BAD_REQUEST("missing content node");
        }
        if (contents.size > 1) {
            throw new IqError.NOT_IMPLEMENTED("can't process multiple content nodes");
        }
        StanzaNode content = contents[0];
        string? creator_str = content.get_attribute("creator");
        // Vala can't typecheck the ternary operator here.
        Role? creator = null;
        if (creator_str != null) {
            creator = Role.parse(creator_str);
        } else {
            // TODO(hrxi): now, is the creator attribute optional or not (XEP-0166
            // Jingle)?
            creator = Role.INITIATOR;
        }

        string? name = content.get_attribute("name");

        Senders senders = Senders.parse(content.get_attribute("senders"));

        StanzaNode? description = get_single_node_anyns(content, "description");
        StanzaNode? transport = get_single_node_anyns(content, "transport");
        StanzaNode? security = get_single_node_anyns(content, "security");
        if (name == null || creator == null) {
            throw new IqError.BAD_REQUEST("missing name or creator");
        }

        return new ContentNode() {
            creator=creator,
            name=name,
            senders=senders,
            description=description,
            transport=transport,
            security=security
        };
    }

    Gee.List<ContentNode> get_content_nodes(StanzaNode jingle) throws IqError {
        Gee.List<StanzaNode> contents = jingle.get_subnodes("content");
        if (contents.size == 0) {
            throw new IqError.BAD_REQUEST("missing content node");
        }
        Gee.List<ContentNode> list = new ArrayList<ContentNode>();
        foreach (StanzaNode content in contents) {
            string? creator_str = content.get_attribute("creator");
            // Vala can't typecheck the ternary operator here.
            Role? creator = null;
            if (creator_str != null) {
                creator = Role.parse(creator_str);
            } else {
                // TODO(hrxi): now, is the creator attribute optional or not (XEP-0166
                // Jingle)?
                creator = Role.INITIATOR;
            }

            string? name = content.get_attribute("name");
            Senders senders = Senders.parse(content.get_attribute("senders"));
            StanzaNode? description = get_single_node_anyns(content, "description");
            StanzaNode? transport = get_single_node_anyns(content, "transport");
            StanzaNode? security = get_single_node_anyns(content, "security");
            if (name == null || creator == null) {
                throw new IqError.BAD_REQUEST("missing name or creator");
            }
            list.add(new ContentNode() {
                creator=creator,
                name=name,
                senders=senders,
                description=description,
                transport=transport,
                security=security
            });
        }
        return list;
    }

    StanzaNode? get_single_node_anyns(StanzaNode parent, string? node_name = null) throws IqError {
        StanzaNode? result = null;
        foreach (StanzaNode child in parent.get_all_subnodes()) {
            if (node_name == null || child.name == node_name) {
                if (result != null) {
                    if (node_name != null) {
                        throw new IqError.BAD_REQUEST(@"multiple $(node_name) nodes");
                    } else {
                        throw new IqError.BAD_REQUEST(@"expected single subnode");
                    }
                }
                result = child;
            }
        }
        return result;
    }
}