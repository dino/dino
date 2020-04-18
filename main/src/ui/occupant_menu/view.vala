using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.OccupantMenu {
public class View : Popover {

    private StreamInteractor stream_interactor;
    private Conversation conversation;

    private Stack stack = new Stack() { vhomogeneous=false, visible=true };
    private List list;
    private ListBox invite_list;
    private Box? jid_menu = null;

    private Jid? selected_jid;

    public View(StreamInteractor stream_interactor, Conversation conversation) {
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;

        Box list_box = new Box(Orientation.VERTICAL, 1) { visible=true };
        list = new List(stream_interactor, conversation) { visible=true };
        list_box.add(list);

        invite_list = new ListBox() { visible=true };
        invite_list.add(new ListRow.label("+", _("Invite")) {visible=true});
        list_box.add(invite_list);
        invite_list.row_activated.connect((row) => {
            hide();
            Gee.List<Account> acc_list = new ArrayList<Account>(Account.equals_func);
            acc_list.add(conversation.account);
            SelectContactDialog add_chat_dialog = new SelectContactDialog(stream_interactor, acc_list);
            add_chat_dialog.set_transient_for((Window) get_toplevel());
            add_chat_dialog.title = _("Invite to Conference");
            add_chat_dialog.ok_button.label = _("Invite");
            add_chat_dialog.selected.connect((account, jid) => {
                stream_interactor.get_module(MucManager.IDENTITY).invite(conversation.account, conversation.counterpart, jid);
            });
            add_chat_dialog.present();
        });

        stack.add_named(list_box, "list");
        add(stack);
        stack.visible_child_name = "list";

        list.list_box.row_activated.connect((row) => {
            ListRow list_row = row as ListRow;
            show_menu(list_row.jid, list_row.name_label.label);
        });

        hide.connect(reset);
    }

    public void reset() {
        stack.transition_type = StackTransitionType.NONE;
        stack.visible_child_name = "list";
        list.list_box.unselect_all();
        invite_list.unselect_all();
    }

    private void show_list() {
        list.list_box.unselect_all();
        stack.transition_type = StackTransitionType.SLIDE_RIGHT;
        stack.visible_child_name = "list";
    }

    private void show_menu(Jid jid, string name_) {
        selected_jid = jid;
        stack.transition_type = StackTransitionType.SLIDE_LEFT;

        string name = name_;
        Jid? real_jid = stream_interactor.get_module(MucManager.IDENTITY).get_real_jid(jid, conversation.account);
        if (real_jid != null) name += @"\n<span font=\'8\'>$(real_jid.bare_jid)</span>";

        Box header_box = new Box(Orientation.HORIZONTAL, 5) { visible=true };
        header_box.add(new Image.from_icon_name("pan-start-symbolic", IconSize.SMALL_TOOLBAR) { visible=true });
        header_box.add(new Label(name) { xalign=0, use_markup=true, hexpand=true, visible=true });
        Button header_button = new Button() { relief=ReliefStyle.NONE, visible=true };
        header_button.add(header_box);

        Box outer_box = new Box(Orientation.VERTICAL, 5) { margin=10, visible=true };
        outer_box.add(header_button);
        header_button.clicked.connect(show_list);

        ModelButton private_button = new ModelButton()  { active=true, text=_("Start private conversation"), visible=true };
        outer_box.add(private_button);
        private_button.clicked.connect(private_conversation_button_clicked);

        Jid? own_jid = stream_interactor.get_module(MucManager.IDENTITY).get_own_jid(conversation.counterpart, conversation.account);
        Xmpp.Xep.Muc.Role? role = stream_interactor.get_module(MucManager.IDENTITY).get_role(own_jid, conversation.account);

        if (role ==  Xmpp.Xep.Muc.Role.MODERATOR && stream_interactor.get_module(MucManager.IDENTITY).kick_possible(conversation.account, jid)) {
            ModelButton kick_button = new ModelButton()  { active=true, text=_("Kick"), visible=true };
            outer_box.add(kick_button);
            kick_button.clicked.connect(kick_button_clicked);
        }
        if (stream_interactor.get_module(MucManager.IDENTITY).is_moderated_room(conversation.account, conversation.counterpart) && role ==  Xmpp.Xep.Muc.Role.MODERATOR){
            if (stream_interactor.get_module(MucManager.IDENTITY).get_role(selected_jid, conversation.account) ==  Xmpp.Xep.Muc.Role.VISITOR) {
                ModelButton voice_button = new ModelButton()  { active=true, text=_("Grant write permission"), visible=true };
                outer_box.add(voice_button);
                voice_button.clicked.connect(() => 
                    voice_button_clicked("participant"));
            } 
            else if (stream_interactor.get_module(MucManager.IDENTITY).get_role(selected_jid, conversation.account) ==  Xmpp.Xep.Muc.Role.PARTICIPANT){
                ModelButton voice_button = new ModelButton()  { active=true, text=_("Revoke write permission"), visible=true };
                outer_box.add(voice_button);
                voice_button.clicked.connect(() => 
                    voice_button_clicked("visitor"));
            }
            
        }

        if (jid_menu != null) jid_menu.destroy();
        stack.add_named(outer_box, "menu");
        stack.visible_child_name = "menu";
        jid_menu = outer_box;
    }

    private void private_conversation_button_clicked() {
        if (selected_jid == null) return;

        Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(selected_jid, conversation.account, Conversation.Type.GROUPCHAT_PM);
        stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation);

        Application app = GLib.Application.get_default() as Application;
        app.controller.select_conversation(conversation);
    }

    private void kick_button_clicked() {
        if (selected_jid == null) return;

        stream_interactor.get_module(MucManager.IDENTITY).kick(conversation.account, conversation.counterpart, selected_jid.resourcepart);
    }

    private void voice_button_clicked(string role) {
        if (selected_jid == null) return;

        stream_interactor.get_module(MucManager.IDENTITY).change_role(conversation.account, conversation.counterpart, selected_jid.resourcepart, role);
    }
}

}
