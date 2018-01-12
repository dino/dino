using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui {

public class AddConferenceDialog : Gtk.Dialog {

    public signal void conversation_opened(Conversation conversation);

    private Stack stack = new Stack();
    private Button cancel_button;
    private Button ok_button;
    private Label cancel_label = new Label(_("Cancel")) {visible=true};
    private Image cancel_image = new Image.from_icon_name("go-previous-symbolic", IconSize.MENU) {visible=true};

    private SelectJidFragment select_fragment;
    private ConferenceDetailsFragment details_fragment;
    private ConferenceList conference_list;

    private StreamInteractor stream_interactor;

    public AddConferenceDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : 1);
        this.title = _("Join Conference");
        this.modal = true;
        this.stream_interactor = stream_interactor;

        stack.visible = true;
        stack.vhomogeneous = false;
        get_content_area().add(stack);

        setup_headerbar();
        setup_jid_add_view();
        setup_conference_details_view();
        show_jid_add_view();

        stream_interactor.get_module(MucManager.IDENTITY).joined.connect(on_joined);
    }

    private void show_jid_add_view() {
        if (cancel_image.get_parent() != null) cancel_button.remove(cancel_image);
        cancel_button.add(cancel_label);
        cancel_button.clicked.disconnect(show_jid_add_view);
        cancel_button.clicked.connect(on_cancel);
        ok_button.label = _("Next");
        ok_button.sensitive = select_fragment.done;
        ok_button.clicked.disconnect(on_ok_button_clicked);
        ok_button.clicked.connect(on_next_button_clicked);
        details_fragment.notify["done"].disconnect(set_ok_sensitive_from_details);
        select_fragment.notify["done"].connect(set_ok_sensitive_from_select);
        stack.transition_type = StackTransitionType.SLIDE_RIGHT;
        stack.set_visible_child_name("select");
    }

    private void show_conference_details_view() {
        if (cancel_label.get_parent() != null) cancel_button.remove(cancel_label);
        cancel_button.add(cancel_image);
        cancel_button.clicked.disconnect(on_cancel);
        cancel_button.clicked.connect(show_jid_add_view);
        ok_button.label = _("Join");
        ok_button.sensitive = details_fragment.done;
        ok_button.clicked.disconnect(on_next_button_clicked);
        ok_button.clicked.connect(on_ok_button_clicked);
        select_fragment.notify["done"].disconnect(set_ok_sensitive_from_select);
        details_fragment.notify["done"].connect(set_ok_sensitive_from_details);
        stack.transition_type = StackTransitionType.SLIDE_LEFT;
        stack.set_visible_child_name("details");
        animate_window_resize();
    }

    private void setup_headerbar() {
        HeaderBar header_bar = get_header_bar() as HeaderBar;
        header_bar.show_close_button = false;

        cancel_button = new Button();
        header_bar.pack_start(cancel_button);
        cancel_button.visible = true;

        ok_button = new Button();
        header_bar.pack_end(ok_button);
        ok_button.get_style_context().add_class("suggested-action");
        ok_button.visible = true;
        ok_button.can_focus = true;
        ok_button.can_default = true;
        ok_button.has_default = true;
    }

    private void setup_jid_add_view() {
        conference_list = new ConferenceList(stream_interactor);
        conference_list.row_activated.connect(() => { ok_button.clicked(); });
        select_fragment = new SelectJidFragment(stream_interactor, conference_list, stream_interactor.get_accounts());
        select_fragment.add_jid.connect((row) => {
            AddGroupchatDialog dialog = new AddGroupchatDialog(stream_interactor);
            dialog.set_transient_for(this);
            dialog.present();
        });
        select_fragment.remove_jid.connect((row) => {
            ConferenceListRow conference_row = row as ConferenceListRow;
            stream_interactor.get_module(MucManager.IDENTITY).remove_bookmark(conference_row.account, conference_row.bookmark);
        });
        stack.add_named(select_fragment, "select");
    }

    private void setup_conference_details_view() {
        details_fragment = new ConferenceDetailsFragment(stream_interactor, ok_button);
        stack.add_named(details_fragment, "details");
    }

    private void set_ok_sensitive_from_select() {
        ok_button.sensitive = select_fragment.done;
    }

    private void set_ok_sensitive_from_details() {
        ok_button.sensitive = select_fragment.done;
    }

    private void on_next_button_clicked() {
        details_fragment.clear();
        ListRow? row = conference_list.get_selected_row() as ListRow;
        ConferenceListRow? conference_row = conference_list.get_selected_row() as ConferenceListRow;
        if (conference_row != null) {
            details_fragment.account = conference_row.account;
            details_fragment.jid = conference_row.bookmark.jid.to_string();
            details_fragment.nick = conference_row.bookmark.nick;
            if (conference_row.bookmark.password != null) details_fragment.password = conference_row.bookmark.password;
            ok_button.grab_focus();
        } else if (row != null) {
            details_fragment.account = row.account;
            details_fragment.jid = row.jid.to_string();
            details_fragment.set_editable();
        }
        show_conference_details_view();
    }

    private void on_ok_button_clicked() {
        stream_interactor.get_module(MucManager.IDENTITY).join(details_fragment.account, new Jid(details_fragment.jid), details_fragment.nick, details_fragment.password);
    }

    private void on_joined(Account account, Jid jid, string nick) {
        if (account.equals(details_fragment.account) && jid.equals_bare(new Jid(details_fragment.jid))) {
            Conversation conversation = stream_interactor.get_module(ConversationManager.IDENTITY).create_conversation(jid, account, Conversation.Type.GROUPCHAT);
            stream_interactor.get_module(ConversationManager.IDENTITY).start_conversation(conversation, true);
            conversation_opened(conversation);
            close();
        }
    }

    private void on_cancel() {
        close();
    }

    private void animate_window_resize() {
        int def_height, curr_width, curr_height;
        get_size(out curr_width, out curr_height);
        stack.get_preferred_height(null, out def_height);
        int difference = def_height - curr_height;
        Timer timer = new Timer();
        Timeout.add((int) (stack.transition_duration / 30),
            () => {
                ulong microsec;
                timer.elapsed(out microsec);
                ulong millisec = microsec / 1000;
                double partial = double.min(1, (double) millisec / stack.transition_duration);
                resize(curr_width, (int) (curr_height + difference * partial));
                return millisec < stack.transition_duration;
            });
    }
}

}
