using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/add_account_dialog.ui")]
public class AddAccountDialog : Gtk.Dialog {

    public signal void added(Account account);

    [GtkChild] private Stack stack;

    [GtkChild] private Revealer notification_revealer;
    [GtkChild] private Label notification_label;

    // Sign in
    [GtkChild] private Box sign_in_box;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Entry alias_entry;
    [GtkChild] private Entry password_entry;
    [GtkChild] private Button sign_in_continue;
    [GtkChild] private Button serverlist_button;

    // Select Server
    [GtkChild] private Box create_account_box;
    [GtkChild] private Button login_button;
    [GtkChild] private Stack select_server_continue_stack;
    [GtkChild] private Button select_server_continue;
    [GtkChild] private Label register_form_continue_label;
    [GtkChild] private ListBox server_list_box;
    [GtkChild] private Entry server_entry;

    // Register Form
    [GtkChild] private Box register_box;
    [GtkChild] private Label register_title;
    [GtkChild] private Box form_box;
    [GtkChild] private Button register_form_back;
    [GtkChild] private Stack register_form_continue_stack;
    [GtkChild] private Button register_form_continue;

    private static string[] server_list = new string[]{
        "5222.de",
        "jabber.fr",
        "movim.eu",
        "yax.im"
    };
    private HashMap<ListBoxRow, string> list_box_jids = new HashMap<ListBoxRow, string>();
    private Jid? server_jid = null;
    private Xep.InBandRegistration.Form? form = null;

    public AddAccountDialog(StreamInteractor stream_interactor) {
        this.title = _("Add Account");

        // Sign in
        jid_entry.changed.connect(on_jid_entry_changed);
        jid_entry.focus_out_event.connect(on_jid_entry_focus_out_event);
        sign_in_continue.clicked.connect(on_sign_in_continue_clicked);
        serverlist_button.clicked.connect(show_select_server);

        // Select Server
        server_entry.changed.connect(() => {
            Jid? jid = Jid.parse(server_entry.text);
            select_server_continue.sensitive = jid != null && jid.localpart == null && jid.resourcepart == null;
        });
        select_server_continue.clicked.connect(on_select_server_continue);
        login_button.clicked.connect(show_sign_in);

        foreach (string server in server_list) {
            ListBoxRow list_box_row = new ListBoxRow() { visible=true };
            list_box_row.add(new Label(server) { xalign=0, margin=3, margin_start=7, margin_end=7, visible=true });
            list_box_jids[list_box_row] = server;
            server_list_box.add(list_box_row);
        }

        // Register Form
        register_form_continue.clicked.connect(on_register_form_continue_clicked);
        register_form_back.clicked.connect(show_select_server);

        show_sign_in();
    }

    private void show_sign_in() {
        sign_in_box.visible = true;
        stack.visible_child_name = "login";
        create_account_box.visible = false;
        register_box.visible = false;
        set_default(sign_in_continue);
        animate_window_resize(sign_in_box);
    }

    private void show_select_server() {
        server_entry.text = "";
        server_entry.grab_focus();
        set_default(select_server_continue);

        server_list_box.row_selected.disconnect(on_server_list_row_selected);
        server_list_box.unselect_all();
        server_list_box.row_selected.connect(on_server_list_row_selected);

        create_account_box.visible = true;
        stack.visible_child_name = "server";
        sign_in_box.visible = false;
        register_box.visible = false;

        animate_window_resize(create_account_box);
    }

    private void show_register_form() {
        register_box.visible = true;
        stack.visible_child_name = "form";
        sign_in_box.visible = false;
        create_account_box.visible = false;

        set_default(register_form_continue);
        animate_window_resize(register_box);
    }

    private void on_jid_entry_changed() {
        Jid? jid = Jid.parse(jid_entry.text);
        if (jid != null && jid.localpart != null && jid.resourcepart == null) {
            sign_in_continue.set_sensitive(true);
            jid_entry.secondary_icon_name = null;
        } else {
            sign_in_continue.set_sensitive(false);
        }
    }

    private bool on_jid_entry_focus_out_event() {
        Jid? jid = Jid.parse(jid_entry.text);
        if (jid == null || jid.localpart == null || jid.resourcepart != null) {
            jid_entry.secondary_icon_name = "dialog-warning-symbolic";
            jid_entry.set_icon_tooltip_text(EntryIconPosition.SECONDARY, _("JID should be of the form “user@example.com”"));
        } else {
            jid_entry.secondary_icon_name = null;
        }
        return false;
    }

    private void on_sign_in_continue_clicked() {
        Jid jid = new Jid(jid_entry.get_text());
        string password = password_entry.get_text();
        string alias = alias_entry.get_text();
        store_account(jid, password, alias);
        close();
    }

    private void on_select_server_continue() {
        server_jid = new Jid(server_entry.text);
        request_show_register_form.begin();
    }

    private void on_server_list_row_selected(ListBox box, ListBoxRow? row) {
        server_jid = new Jid(list_box_jids[row]);
        request_show_register_form.begin();
    }

    private async void request_show_register_form() {
        select_server_continue_stack.visible_child_name = "spinner";
        form = yield Register.get_registration_form(server_jid);
        if (select_server_continue_stack == null) {
            return;
        }
        select_server_continue_stack.visible_child_name = "label";
        if (form != null) {
            set_register_form(server_jid, form);
            show_register_form();
        } else {
            display_notification(_("No response from server"));
        }
    }

    private void set_register_form(Jid server, Xep.InBandRegistration.Form form) {
        form_box.foreach((widget) => { widget.destroy(); });
        register_title.label = _("Register on %s").printf(server.to_string());

        if (form.oob != null) {
            form_box.add(new Label(_("The server requires to sign up through a website")){ use_markup=true, visible=true } );
            form_box.add(new Label(@"<a href=\"$(form.oob)\">$(form.oob)</a>") { use_markup=true, visible=true });
            register_form_continue_label.label = _("Open Registration");
            register_form_continue.visible = true;
            register_form_continue.grab_focus();
        } else if (form.fields.size > 0) {
            int i = 0;
            foreach (Xep.DataForms.DataForm.Field field in form.fields) {
                if (field.label != null && field.label != "") {
                    form_box.add(new Label(field.label) { xalign=0, margin_top=7, visible=true });
                }
                Widget field_widget = Util.get_data_form_fild_widget(field);
                if (field_widget != null) {
                    form_box.add(field_widget);
                }
                i++;
            }
            register_form_continue.visible = true;
            register_form_continue_label.label = _("Register");
        } else {
            form_box.add(new Label(_("Check %s for information on how to sign up").printf(@"<a href=\"http://$(server)\">$(server)</a>")) { use_markup=true, visible=true });
            register_form_continue.visible = false;
        }
    }

    private async void on_register_form_continue_clicked() {
        notification_revealer.set_reveal_child(false);
        // Button is opening a registration website
        if (form.oob != null) {
            try {
                AppInfo.launch_default_for_uri(form.oob, null);
            } catch (Error e) { }
            show_sign_in();
            return;
        }

        register_form_continue_stack.visible_child_name = "spinner";
        string? error = yield Register.submit_form(server_jid, form);
        if (register_form_continue_stack == null) {
            return;
        }
        register_form_continue_stack.visible_child_name = "label";
        if (error == null) {
            string? username = null, password = null;
            foreach (Xep.DataForms.DataForm.Field field in form.fields) {
                switch (field.var) {
                    case "username": username = field.get_value_string(); break;
                    case "password": password = field.get_value_string(); break;
                }
            }
            store_account(new Jid(username + "@" + server_jid.domainpart), password, "");
            close();
        } else {
            display_notification(error);
        }
    }

    private void store_account(Jid jid, string password, string? alias) {
        Account account = new Account(jid, null, password, alias);
        added(account);
    }

    private void display_notification(string text) {
        notification_label.label = text;
        notification_revealer.set_reveal_child(true);
        Timeout.add_seconds(5, () => {
            notification_revealer.set_reveal_child(false);
            return false;
        });
    }

    private void animate_window_resize(Widget widget) { // TODO code duplication
        int def_height, curr_width, curr_height;
        get_size(out curr_width, out curr_height);
        widget.get_preferred_height(null, out def_height);
        def_height += 5;
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
