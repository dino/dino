using Xmpp;
using Gee;
using Qlite;

using Dino.Entities;

public class Dino.Model.ConversationDisplayName : Object {
    public string display_name { get; set; }
}

namespace Dino {
    public class ContactModels : StreamInteractionModule, Object {
        public static ModuleIdentity<ContactModels> IDENTITY = new ModuleIdentity<ContactModels>("contact_models");
        public string id { get { return IDENTITY.id; } }

        private StreamInteractor stream_interactor;
        private HashMap<Conversation, Model.ConversationDisplayName> conversation_models = new HashMap<Conversation, Model.ConversationDisplayName>(Conversation.hash_func, Conversation.equals_func);

        public static void start(StreamInteractor stream_interactor) {
            ContactModels m = new ContactModels(stream_interactor);
            stream_interactor.add_module(m);
        }

        private ContactModels(StreamInteractor stream_interactor) {
            this.stream_interactor = stream_interactor;

            stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect((account, jid) => {
                check_update_models(account, jid, Conversation.Type.GROUPCHAT);
            });
            stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.connect((account, room, occupant) => {
                check_update_models(account, room, Conversation.Type.GROUPCHAT);
            });
            stream_interactor.get_module(MucManager.IDENTITY).subject_set.connect((account, jid, subject) => {
                check_update_models(account, jid, Conversation.Type.GROUPCHAT);
            });
            stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
                check_update_models(account, jid, Conversation.Type.CHAT);
            });
        }

        private void check_update_models(Account account, Jid jid, Conversation.Type conversation_ty) {
            var conversation = stream_interactor.get_module(ConversationManager.IDENTITY).get_conversation(jid, account, conversation_ty);
            if (conversation == null) return;
            var display_name_model = conversation_models[conversation];
            if (display_name_model == null) return;
            display_name_model.display_name = Dino.get_conversation_display_name(stream_interactor, conversation, "%s (%s)");
        }

        public Model.ConversationDisplayName get_display_name_model(Conversation conversation) {
            if (conversation_models.has_key(conversation)) return conversation_models[conversation];

            var model = new Model.ConversationDisplayName();
            model.display_name = Dino.get_conversation_display_name(stream_interactor, conversation, "%s (%s)");
            conversation_models[conversation] = model;
            return model;
        }
    }
}