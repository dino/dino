using Gtk;

using Dino.Entities;

namespace Dino.Ui.OccupantMenu {
public class View : Popover {

    private StreamInteractor stream_interactor;
    private Conversation conversation;

    private Stack stack = new Stack() { vhomogeneous=false, visible=true };
    private List list;
    private Label header_label = new Label("") { xalign=0.5f, hexpand=true, visible=true };

    public View(StreamInteractor stream_interactor, Conversation conversation) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;

        list = new List(stream_interactor, conversation) { visible=true };
        stack.add_named(list, "list");
        setup_menu();
        add(stack);
        stack.visible_child_name = "list";

        list.list_box.row_activated.connect((row) => {
            ListRow list_row = row as ListRow;
            header_label.label = list_row.name_label.label;
            show_menu();
        });

        hide.connect(reset);
    }

    public void reset() {
        stack.transition_type = StackTransitionType.NONE;
        stack.visible_child_name = "list";
        list.list_box.unselect_all();
    }

    private void setup_menu() {
        Box header_box = new Box(Orientation.HORIZONTAL, 5) { visible=true };
        header_box.add(new Image.from_icon_name("pan-start-symbolic", IconSize.SMALL_TOOLBAR) { visible=true });
        header_box.add(header_label);

        Button header_button = new Button() { relief=ReliefStyle.NONE, visible=true };
        header_button.add(header_box);

        ModelButton private_button = new ModelButton()  { active=true, text=_("Start private conversation"), visible=true };

        Box outer_box = new Box(Orientation.VERTICAL, 5) { margin=10, visible=true };
        outer_box.add(header_button);
        outer_box.add(private_button);
        stack.add_named(outer_box, "menu");

        header_button.clicked.connect(show_list);
        private_button.clicked.connect(private_conversation_button_clicked);
    }

    private void show_list() {
        list.list_box.unselect_all();
        stack.transition_type = StackTransitionType.SLIDE_RIGHT;
        stack.visible_child_name = "list";
    }

    private void show_menu() {
        stack.transition_type = StackTransitionType.SLIDE_LEFT;
        stack.visible_child_name = "menu";
    }

    private void private_conversation_button_clicked() {
        ListRow? list_row = list.list_box.get_selected_row() as ListRow;
        if (list_row == null) return;

        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(list_row.jid, list_row.account, Conversation.Type.GROUPCHAT_PM);
        stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation, true);
    }
}

}