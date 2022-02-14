using Gtk;
using Dino.Entities;
using Dino;
using Gee;
using Xmpp;

public class Dino.Ui.ConversationViewModel : Object {
    public signal void closed();

    public StreamInteractor stream_interactor { get; set; }
    public Conversation conversation { get; set; }
    public string name { get; set; }
    public ContentItem? latest_content_item { get; set; }
    public int unread_count { get; set; }
}

public class Dino.Ui.ConversationListModel : Object, ListModel {

    public signal void closed_conversation(Conversation conversation);

    private HashMap<Conversation, ConversationViewModel> conversation_view_model_hm = new HashMap<Conversation, ConversationViewModel>(Conversation.hash_func, Conversation.equals_func);
    private ArrayList<ConversationViewModel> view_models = new ArrayList<ConversationViewModel>();
    private StreamInteractor stream_interactor;

    public ConversationListModel(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_activated.connect(add_conversation);
        stream_interactor.get_module(ConversationManager.IDENTITY).conversation_deactivated.connect(remove_conversation);
        stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect(on_content_item_received);

        foreach (Conversation conversation in stream_interactor.get_module(ConversationManager.IDENTITY).get_active_conversations()) {
            var view_model = create_view_model(conversation);
            view_models.add(view_model);
            conversation_view_model_hm[conversation] = view_model;
        }
        view_models.sort(sort);
        items_changed(0, 0, get_n_items());

        stream_interactor.get_module(RosterManager.IDENTITY).updated_roster_item.connect((account, jid, roster_item) => {
            ConversationViewModel? view_model = get_view_model(account, jid, Conversation.Type.CHAT);
            if (view_model == null) return;
            view_model.name = Util.get_conversation_display_name(stream_interactor, view_model.conversation);
        });
        stream_interactor.get_module(MucManager.IDENTITY).room_info_updated.connect((account, jid) => {
            ConversationViewModel? view_model = get_view_model(account, jid, Conversation.Type.GROUPCHAT);
            if (view_model == null) return;
            view_model.name = Util.get_conversation_display_name(stream_interactor, view_model.conversation);
            // bubble color might have changed
            view_model.unread_count = stream_interactor.get_module(ChatInteraction.IDENTITY).get_num_unread(view_model.conversation);
        });
        stream_interactor.get_module(MucManager.IDENTITY).private_room_occupant_updated.connect((account, room, occupant) => {
            ConversationViewModel? view_model = get_view_model(account, room.bare_jid, Conversation.Type.GROUPCHAT);
            if (view_model == null) return;
            view_model.name = Util.get_conversation_display_name(stream_interactor, view_model.conversation);
        });
    }

    public GLib.Object? get_item (uint position) {
        if (position >= view_models.size) return null;
        return view_models[(int)position];
    }

    public GLib.Type get_item_type () {
        return GLib.Type.OBJECT;
    }

    public uint get_n_items () {
        return view_models.size;
    }

    private ConversationViewModel create_view_model(Conversation conversation) {
        var view_model = new ConversationViewModel();
        view_model.stream_interactor = stream_interactor;
        view_model.conversation = conversation;
        view_model.name = Util.get_conversation_display_name(stream_interactor, conversation);
        view_model.latest_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(conversation);
        view_model.unread_count = stream_interactor.get_module(ChatInteraction.IDENTITY).get_num_unread(conversation);
        view_model.closed.connect(() => closed_conversation(conversation));

        return view_model;
    }

    private void add_conversation(Conversation conversation) {
        var view_model = create_view_model(conversation);

        view_models.add(view_model);
        conversation_view_model_hm[conversation] = view_model;
        view_models.sort(sort);

        int idx = view_models.index_of(view_model);
        items_changed(idx, 0, 1);
    }

    private async void remove_conversation(Conversation conversation) {
        ConversationViewModel? view_model = conversation_view_model_hm[conversation];
        if (view_model == null) return;

        int idx = view_models.index_of(view_model);
        view_models.remove(view_model);
        conversation_view_model_hm.unset(conversation);
        items_changed(idx, 1, 0);
    }

    private void on_content_item_received(ContentItem item, Conversation conversation) {
        ConversationViewModel? view_model = conversation_view_model_hm[conversation];
        if (view_model == null) return;

        view_model.latest_content_item = stream_interactor.get_module(ContentItemStore.IDENTITY).get_latest(conversation);
        view_model.unread_count = stream_interactor.get_module(ChatInteraction.IDENTITY).get_num_unread(conversation);

        view_models.sort(sort);
        items_changed(0, view_models.size, view_models.size); // TODO better
    }

    private ConversationViewModel? get_view_model(Account account, Jid jid, Conversation.Type? conversation_ty) {
        foreach (ConversationViewModel view_model in view_models) {
            Conversation conversation = view_model.conversation;
            if (conversation.account.equals(account) && conversation.counterpart.equals(jid)) {
                if (conversation_ty != null && conversation.type_ != conversation_ty) continue;
                return view_model;
            }
        }
        return null;
    }

    private int sort(ConversationViewModel vm1, ConversationViewModel vm2) {
        Conversation c1 = vm1.conversation;
        Conversation c2 = vm2.conversation;

        if (c1 == null || c2 == null) return 0;
        if (c1.last_active == null) return -1;
        if (c2.last_active == null) return 1;

        int comp = c2.last_active.compare(c1.last_active);
        if (comp != 0) return comp;

        return Util.get_conversation_display_name(stream_interactor, c1)
                .collate(Util.get_conversation_display_name(stream_interactor, c2));
    }
}