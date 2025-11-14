using Gee;

using Xmpp;
using Xmpp.Xep;
using Dino.Entities;
using Qlite;

namespace Dino {

    public class MessageDeletion : StreamInteractionModule, MessageListener {
        public static ModuleIdentity<MessageDeletion> IDENTITY = new ModuleIdentity<MessageDeletion>("message_deletion");
        public string id { get { return IDENTITY.id; } }

        public signal void item_deleted(ContentItem content_item);

        private StreamInteractor stream_interactor;
        private Database db;

        public static void start(StreamInteractor stream_interactor, Database db) {
            MessageDeletion m = new MessageDeletion(stream_interactor, db);
            stream_interactor.add_module(m);
        }

        public MessageDeletion(StreamInteractor stream_interactor, Database db) {
            this.stream_interactor = stream_interactor;
            this.db = db;

            stream_interactor.get_module(MessageProcessor.IDENTITY).received_pipeline.connect(this);
        }

        public bool is_deletable(Conversation conversation, ContentItem content_item) {
            MessageItem? message_item = content_item as MessageItem;
            return message_item != null && message_item.message.body != "";
        }

        public bool can_delete_for_everyone(Conversation conversation, ContentItem content_item) {
            if (conversation.type_.is_muc_semantic()) {
                bool muc_supports_moderation = stream_interactor.get_module(EntityInfo.IDENTITY)
                        .has_feature_cached(conversation.account, conversation.counterpart, Xmpp.Xep.MessageModeration.NS_URI);
                bool we_are_moderator = stream_interactor.get_module(MucManager.IDENTITY).get_own_role(conversation) == Xmpp.Xep.Muc.Role.MODERATOR;
                return muc_supports_moderation && we_are_moderator;
            } else {
                return content_item.jid.equals_bare(conversation.account.bare_jid);
            }
        }

        public void delete_globally(Conversation conversation, ContentItem content_item) {
            var stream = stream_interactor.get_stream(conversation.account);
            if (stream == null) return;

            string message_id_to_delete = stream_interactor.get_module(ContentItemStore.IDENTITY).get_message_id_for_content_item(conversation, content_item);

            if (conversation.type_ == Conversation.Type.CHAT) {
                MessageStanza stanza = new MessageStanza() { to = conversation.counterpart };
                Xmpp.Xep.MessageRetraction.set_retract_id(stanza, message_id_to_delete);
                stream.get_module(MessageModule.IDENTITY).send_message(stream, stanza);
                delete_locally(conversation, content_item, conversation.account.bare_jid);
            } else if (conversation.type_.is_muc_semantic()) {
                MessageStanza stanza = new MessageStanza() { to = conversation.counterpart };
                Xmpp.Xep.MessageModeration.moderate.begin(stream, conversation.counterpart, message_id_to_delete);
                // Message will be deleted locally when the MUC server sends out a moderation message
            }
        }

        public void delete_locally(Conversation conversation, ContentItem content_item, Jid removed_by) {
            // If it's a file transfer, remove the file
            if (content_item.type_ == FileItem.TYPE) {
                FileItem file_item = (FileItem) content_item;
                if (file_item.file_transfer.path != null) {
                    FileUtils.remove(file_item.file_transfer.path);
                }
            }

            // Mark the (underlying) message as removed and clear the body
            Message? message = stream_interactor.get_module(ContentItemStore.IDENTITY).get_message_for_content_item(conversation, content_item);
            if (message != null) {
                message.body = "";
            }

            item_deleted(content_item);
        }

        public string[] after_actions_const = new string[]{ };
        public override string action_group { get { return "DELETE"; } }
        public override string[] after_actions { get { return after_actions_const; } }

        public override async bool run(Entities.Message message, Xmpp.MessageStanza stanza, Conversation conversation) {
            string? delete_message_id = Xep.MessageRetraction.get_retract_id(stanza);
            if (delete_message_id == null) return false;

            ContentItem? content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_content_item_for_referencing_id(conversation, delete_message_id);
            if (content_item != null) {
                debug("Deletion request: %s wants to remove message %s content item id %i. Allowed: %b",
                        message.from.to_string(), delete_message_id, content_item.id,
                        is_removal_allowed(conversation, content_item, stanza.from));
                delete_locally(conversation, content_item, stanza.from);
            }

            return false;
        }

        private bool is_removal_allowed(Conversation conversation, ContentItem content_item, Jid removed_by) {
            if (conversation.type_ == Conversation.Type.CHAT) {
                return removed_by.equals_bare(content_item.jid);
            } else if (conversation.type_.is_muc_semantic()) {
                // Only accept MUC message removals if the MUC server announced support.
                // MUC moderations should always come from the MUC bare JID.
                bool muc_supports_moderation = stream_interactor.get_module(EntityInfo.IDENTITY)
                        .has_feature_cached(conversation.account, conversation.counterpart, Xmpp.Xep.MessageModeration.NS_URI);
                return muc_supports_moderation && removed_by.equals(conversation.counterpart);
            }

            return false;
        }
    }

}
