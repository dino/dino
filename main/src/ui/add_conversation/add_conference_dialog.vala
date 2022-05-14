using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;
using Xmpp.Xep;

namespace Dino.Ui {

public class AddConferenceDialog : Gtk.Dialog {

    private Stack stack = new Stack();
    private Button cancel_button = new Button();
    private Button ok_button;

    private SelectJidFragment select_fragment;
    private ConferenceDetailsFragment details_fragment;
    private ConferenceList conference_list;
    private ListBox conference_list_box;

    private StreamInteractor stream_interactor;

    public AddConferenceDialog(StreamInteractor stream_interactor) {
        Object(use_header_bar : Util.use_csd() ? 1 : 0);
        this.title = _("Join Channel");
        this.modal = true;
        this.stream_interactor = stream_interactor;

        stack.visible = true;
        stack.vhomogeneous = false;
        get_content_area().append(stack);

        setup_headerbar();
        setup_jid_add_view();
        setup_conference_details_view();
        show_jid_add_view();
    }

    private void show_jid_add_view() {
        // Rewire headerbar (if CSD)
        if (Util.use_csd()) {
            cancel_button.set_label(_("Cancel"));
            cancel_button.clicked.disconnect(show_jid_add_view);
            cancel_button.clicked.connect(on_cancel);
            ok_button.label = _("Next");
            ok_button.sensitive = select_fragment.done;
            ok_button.clicked.connect(on_next_button_clicked);
            details_fragment.fragment_active = false;
            details_fragment.notify["done"].disconnect(set_ok_sensitive_from_details);
            select_fragment.notify["done"].connect(set_ok_sensitive_from_select);
        }

        stack.transition_type = StackTransitionType.SLIDE_RIGHT;
        stack.set_visible_child_name("select");
    }

    private void show_conference_details_view() {
        // Rewire headerbar (if CSD)
        if (Util.use_csd()) {
            cancel_button.set_icon_name("go-previous-symbolic");
            cancel_button.clicked.disconnect(on_cancel);
            cancel_button.clicked.connect(show_jid_add_view);
            ok_button.label = _("Join");
            ok_button.sensitive = details_fragment.done;
            ok_button.clicked.disconnect(on_next_button_clicked);
            details_fragment.fragment_active = true;
            select_fragment.notify["done"].disconnect(set_ok_sensitive_from_select);
            details_fragment.notify["done"].connect(set_ok_sensitive_from_details);
        }

        stack.transition_type = StackTransitionType.SLIDE_LEFT;
        stack.set_visible_child_name("details");
        animate_window_resize(details_fragment);
    }

    private void setup_headerbar() {
        ok_button = new Button() { can_focus=true };
        ok_button.add_css_class("suggested-action");

        if (Util.use_csd()) {
            HeaderBar header_bar = get_header_bar() as HeaderBar;
            header_bar.show_title_buttons = false;

            header_bar.pack_start(cancel_button);
            header_bar.pack_end(ok_button);

//            ok_button.has_default = true;
        }
    }

    private void setup_jid_add_view() {
        conference_list = new ConferenceList(stream_interactor);
        conference_list_box = conference_list.get_list_box();
        conference_list_box.row_activated.connect(() => { ok_button.clicked(); });

        select_fragment = new SelectJidFragment(stream_interactor, conference_list_box, stream_interactor.get_accounts());
        select_fragment.add_jid.connect((row) => {
            AddGroupchatDialog dialog = new AddGroupchatDialog(stream_interactor);
            dialog.set_transient_for(this);
            dialog.present();
        });
        select_fragment.remove_jid.connect((row) => {
            ConferenceListRow conference_row = row as ConferenceListRow;
            stream_interactor.get_module(MucManager.IDENTITY).remove_bookmark(conference_row.account, conference_row.bookmark);
        });

        Box wrap_box = new Box(Orientation.VERTICAL, 0);
        wrap_box.append(select_fragment);
        stack.add_named(wrap_box, "select");

        if (!Util.use_csd()) {
            Box box = new Box(Orientation.HORIZONTAL, 5) { halign=Align.END, margin_bottom=15, margin_start=80, margin_end=80 };

            Button ok_button = new Button.with_label(_("Next")) { sensitive=false, halign = Align.END, can_focus=true };
            ok_button.add_css_class("suggested-action");
            ok_button.clicked.connect(on_next_button_clicked);
            select_fragment.notify["done"].connect(() => { ok_button.sensitive = select_fragment.done; });
            Button cancel_button = new Button.with_label(_("Cancel")) { halign=Align.START };
            cancel_button.clicked.connect(on_cancel);
            box.append(cancel_button);
            box.append(ok_button);
            wrap_box.append(box);

//            ok_button.has_default = true;
        }
    }

    private void setup_conference_details_view() {
        details_fragment = new ConferenceDetailsFragment(stream_interactor) { ok_button=ok_button };
        details_fragment.joined.connect(() => this.close());

        Box wrap_box = new Box(Orientation.VERTICAL, 0);
        wrap_box.append(details_fragment);

        if (!Util.use_csd()) {
            Box box = new Box(Orientation.HORIZONTAL, 5) { halign=Align.END, margin_bottom=15, margin_start=80, margin_end=80 };

            Button ok_button = new Button.with_label(_("Join")) { halign = Align.END, can_focus=true };
            ok_button.add_css_class("suggested-action");
            details_fragment.notify["done"].connect(() => { ok_button.sensitive = select_fragment.done; });
            details_fragment.ok_button = ok_button;

            Button cancel_button = new Button.with_label(_("Back")) { halign=Align.START };
            cancel_button.clicked.connect(show_jid_add_view);
            box.append(cancel_button);
            box.append(ok_button);

            wrap_box.append(box);
        }
        stack.add_named(wrap_box, "details");
    }

    private void set_ok_sensitive_from_select() {
        ok_button.sensitive = select_fragment.done;
    }

    private void set_ok_sensitive_from_details() {
        ok_button.sensitive = details_fragment.done;
    }

    private void on_next_button_clicked() {
        details_fragment.clear();

        ListRow? row = conference_list_box.get_selected_row() != null ? conference_list_box.get_selected_row().get_child() as ListRow : null;
        ConferenceListRow? conference_row = conference_list_box.get_selected_row() != null ? conference_list_box.get_selected_row() as ConferenceListRow : null;
        if (conference_row != null) {
            details_fragment.account = conference_row.account;
            details_fragment.jid = conference_row.bookmark.jid.to_string();
            details_fragment.nick = conference_row.bookmark.nick;
            if (conference_row.bookmark.password != null) details_fragment.password = conference_row.bookmark.password;
            ok_button.grab_focus();
        } else if (row != null) {
            details_fragment.account = row.account;
            details_fragment.jid = row.jid.to_string();
        }
        show_conference_details_view();
    }

    private void on_cancel() {
        close();
    }

    private void animate_window_resize(Widget widget) {
        int curr_height = get_size(Orientation.VERTICAL);
        var natural_size = Requisition();
        widget.get_preferred_size(null, out natural_size);
        int difference = natural_size.height - curr_height;
        Timer timer = new Timer();
        Timeout.add((int) (stack.transition_duration / 30), () => {
            ulong microsec;
            timer.elapsed(out microsec);
            ulong millisec = microsec / 1000;
            double partial = double.min(1, (double) millisec / stack.transition_duration);
            default_height = (int) (curr_height + difference * partial);
            return millisec < stack.transition_duration;
        });
    }
}

}
