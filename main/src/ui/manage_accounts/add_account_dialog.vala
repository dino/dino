using Gee;
using Gtk;
using Pango;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui.ManageAccounts {

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/add_account_dialog.ui")]
public class AddAccountDialog : Gtk.Dialog {

    public signal void added(Account account);

    [GtkChild] private Stack stack;

    [GtkChild] private Revealer notification_revealer;
    [GtkChild] private Label notification_label;

    // Sign in - JID
    [GtkChild] private Box sign_in_jid_box;
    [GtkChild] private Label sign_in_jid_error_label;
    [GtkChild] private Entry jid_entry;
    [GtkChild] private Stack sign_in_jid_continue_stack;
    [GtkChild] private Button sign_in_jid_continue_button;
    [GtkChild] private Button sign_in_jid_serverlist_button;

    // Sign in - TLS error
    [GtkChild] private Box sign_in_tls_box;
    [GtkChild] private Label sign_in_tls_label;
    [GtkChild] private Stack sign_in_password_continue_stack;
    [GtkChild] private Button sign_in_tls_back_button;

    // Sign in - Password
    [GtkChild] private Box sign_in_password_box;
    [GtkChild] private Label sign_in_password_title;
    [GtkChild] private Label sign_in_password_error_label;

    [GtkChild] private Entry password_entry;
    [GtkChild] private Button sign_in_password_continue_button;
    [GtkChild] private Button sign_in_password_back_button;

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

    // Success
    [GtkChild] private Box success_box;
    [GtkChild] private Label success_description;
    [GtkChild] private Button success_continue_button;

    private static string[] server_list = new string[]{
        "5222.de",
        "jabber.fr",
        "movim.eu",
        "yax.im"
    };

    private StreamInteractor stream_interactor;
    private Database db;
    private HashMap<ListBoxRow, string> list_box_jids = new HashMap<ListBoxRow, string>();
    private Jid? server_jid = null;
    private Jid? login_jid = null;
    private Xep.InBandRegistration.Form? form = null;

    public AddAccountDialog(StreamInteractor stream_interactor, Database db) {
        this.stream_interactor = stream_interactor;
        this.db = db;
        this.title = _("Add Account");

        // Sign in - Jid
        Util.force_error_color(sign_in_jid_error_label);
        jid_entry.changed.connect(on_jid_entry_changed);
        sign_in_jid_continue_button.clicked.connect(on_sign_in_jid_continue_button_clicked);
        sign_in_jid_serverlist_button.clicked.connect(show_select_server);

        // Sign in - TLS error
        sign_in_tls_back_button.clicked.connect(show_sign_in_jid);

        // Sign in - Password
        Util.force_error_color(sign_in_password_error_label);
        password_entry.changed.connect(() => { sign_in_password_continue_button.set_sensitive(password_entry.text.length > 0); });
        sign_in_password_continue_button.clicked.connect(on_sign_in_password_continue_button_clicked);
        sign_in_password_back_button.clicked.connect(show_sign_in_jid);

        // Select Server
        server_entry.changed.connect(() => {
            try {
                Jid jid = new Jid(server_entry.text);
                select_server_continue.sensitive = jid != null && jid.localpart == null && jid.resourcepart == null;
            } catch (InvalidJidError e) {
                select_server_continue.sensitive = false;
            }
        });
        select_server_continue.clicked.connect(on_select_server_continue);
        login_button.clicked.connect(show_sign_in_jid);

        foreach (string server in server_list) {
            ListBoxRow list_box_row = new ListBoxRow() { visible=true };
            list_box_row.add(new Label(server) { xalign=0, margin=3, margin_start=7, margin_end=7, visible=true });
            list_box_jids[list_box_row] = server;
            server_list_box.add(list_box_row);
        }

        // Register Form
        register_form_continue.clicked.connect(on_register_form_continue_clicked);
        register_form_back.clicked.connect(show_select_server);

        // Success
        success_continue_button.clicked.connect(() => close());

        show_sign_in_jid();
    }

    private void show_sign_in_jid() {
        sign_in_jid_box.visible = true;
        jid_entry.grab_focus();
        stack.visible_child_name = "login_jid";
        sign_in_tls_box.visible = false;
        sign_in_password_box.visible = false;
        create_account_box.visible = false;
        register_box.visible = false;
        success_box.visible = false;
        set_default(sign_in_jid_continue_button);

        sign_in_jid_error_label.label = "";
        jid_entry.sensitive = true;
        animate_window_resize(sign_in_jid_box);
    }

    private void show_tls_error(string domain, TlsCertificateFlags error_flags) {
        sign_in_tls_box.visible = true;
        stack.visible_child_name = "tls_error";
        sign_in_jid_box.visible = false;
        sign_in_password_box.visible = false;
        create_account_box.visible = false;
        register_box.visible = false;
        success_box.visible = false;

        string error_desc = _("The server could not prove that it is %s.").printf("<b>" + domain + "</b>");
        if (TlsCertificateFlags.UNKNOWN_CA in error_flags) {
            error_desc += " " + _("Its security certificate is not trusted by your operating system.");
        } else if (TlsCertificateFlags.BAD_IDENTITY in error_flags) {
            error_desc += " " + _("Its security certificate is issued to another domain.");
        } else if (TlsCertificateFlags.NOT_ACTIVATED in error_flags) {
            error_desc += " " + _("Its security certificate will only become valid in the future.");
        } else if (TlsCertificateFlags.EXPIRED in error_flags) {
            error_desc += " " + _("Its security certificate is expired.");
        }
        sign_in_tls_label.label = error_desc;

        animate_window_resize(sign_in_tls_box);
    }

    private void show_sign_in_password() {
        sign_in_password_box.visible = true;
        password_entry.grab_focus();
        stack.visible_child_name = "login_password";
        sign_in_jid_box.visible = false;
        sign_in_tls_box.visible = false;
        create_account_box.visible = false;
        register_box.visible = false;
        success_box.visible = false;
        set_default(sign_in_password_continue_button);

        sign_in_password_error_label.label = "";
        sign_in_password_title.label = _("Sign in to %s").printf(login_jid.to_string());
        animate_window_resize(sign_in_password_box);
    }

    private void show_select_server() {
        server_entry.text = "";
        server_entry.grab_focus();
        set_default(select_server_continue);

        server_list_box.row_activated.disconnect(on_server_list_row_activated);
        server_list_box.unselect_all();
        server_list_box.row_activated.connect(on_server_list_row_activated);

        create_account_box.visible = true;
        stack.visible_child_name = "server";
        sign_in_jid_box.visible = false;
        sign_in_tls_box.visible = false;
        register_box.visible = false;
        success_box.visible = false;

        animate_window_resize(create_account_box);
    }

    private void show_register_form() {
        register_box.visible = true;
        stack.visible_child_name = "form";
        sign_in_jid_box.visible = false;
        sign_in_tls_box.visible = false;
        sign_in_password_box.visible = false;
        create_account_box.visible = false;
        success_box.visible = false;

        set_default(register_form_continue);
        animate_window_resize(register_box);
    }

    private void show_success(Account account) {
        success_box.visible = true;
        stack.visible_child_name = "success";
        sign_in_jid_box.visible = false;
        sign_in_tls_box.visible = false;
        sign_in_password_box.visible = false;
        create_account_box.visible = false;
        register_box.visible = false;
        success_description.label = _("You can now use the account %s.").printf("<b>" + Markup.escape_text(account.bare_jid.to_string()) + "</b>");

        set_default(success_continue_button);
    }

    private void on_jid_entry_changed() {
        try {
            login_jid = new Jid(jid_entry.text);
            if (login_jid.localpart != null && login_jid.resourcepart == null) {
                sign_in_jid_continue_button.sensitive = true;
                jid_entry.secondary_icon_name = null;
            } else {
                sign_in_jid_continue_button.sensitive = false;
            }
        } catch (InvalidJidError e) {
            sign_in_jid_continue_button.sensitive = false;
        }
    }

    private async void on_sign_in_jid_continue_button_clicked() {
        try {
            login_jid = new Jid(jid_entry.text);
            jid_entry.sensitive = false;
            sign_in_tls_label.label = "";
            sign_in_jid_error_label.label = "";
            sign_in_jid_continue_button.sensitive = false;
            sign_in_jid_continue_stack.visible_child_name = "spinner";
            Register.ServerAvailabilityReturn server_status = yield Register.check_server_availability(login_jid);
            sign_in_jid_continue_stack.visible_child_name = "label";
            sign_in_jid_continue_button.sensitive = true;
            if (server_status.available) {
                show_sign_in_password();
            } else {
                jid_entry.sensitive = true;
                if (server_status.error_flags != null) {
                    show_tls_error(login_jid.domainpart, server_status.error_flags);
                } else {
                    sign_in_jid_error_label.label = _("Could not connect to %s").printf(login_jid.domainpart);
                }
            }
        } catch (InvalidJidError e) {
            warning("Invalid address from interface allowed login: %s", e.message);
            sign_in_jid_error_label.label = _("Invalid address");
        }
    }

    private async void on_sign_in_password_continue_button_clicked() {
        string password = password_entry.text;
        Account account = new Account(login_jid, null, password, null);

        sign_in_password_continue_stack.visible_child_name = "spinner";
        ConnectionManager.ConnectionError.Source? error = yield stream_interactor.get_module(Register.IDENTITY).add_check_account(account);
        sign_in_password_continue_stack.visible_child_name = "label";

        if (error != null) {
            switch (error) {
                case ConnectionManager.ConnectionError.Source.SASL:
                    sign_in_password_error_label.label = _("Wrong username or password");
                    break;
                default:
                    sign_in_password_error_label.label = _("Something went wrong");
                    break;
            }
        } else {
            add_activate_account(account);
            show_success(account);
        }
    }

    private void on_select_server_continue() {
        try {
            server_jid = new Jid(server_entry.text);
            request_show_register_form.begin(server_jid);
        } catch (InvalidJidError e) {
            warning("Invalid address from interface allowed server: %s", e.message);
            display_notification(_("Invalid address"));
        }
    }

    private void on_server_list_row_activated(ListBox box, ListBoxRow row) {
        try {
            server_jid = new Jid(list_box_jids[row]);
            request_show_register_form.begin(server_jid);
        } catch (InvalidJidError e) {
            warning("Invalid address from selected server: %s", e.message);
            display_notification(_("Invalid address"));
        }
    }

    private async void request_show_register_form(Jid server_jid) {
        select_server_continue_stack.visible_child_name = "spinner";
        Register.RegistrationFormReturn form_return = yield Register.get_registration_form(server_jid);
        if (select_server_continue_stack == null) {
            return;
        }
        select_server_continue_stack.visible_child_name = "label";
        if (form_return.form != null) {
            form = form_return.form;
            set_register_form(server_jid, form);
            show_register_form();
        } else if (form_return.error_flags != null) {
            show_tls_error(server_jid.domainpart, form_return.error_flags);
        } else {
            display_notification(_("No response from server"));
        }
    }

    private void set_register_form(Jid server, Xep.InBandRegistration.Form form) {
        form_box.foreach((widget) => { form_box.remove(widget); });
        register_title.label = _("Register on %s").printf(server.to_string());

        if (form.oob != null) {
            form_box.add(new Label(_("The server requires to sign up through a website")){ visible=true } );
            form_box.add(new Label(@"<a href=\"$(form.oob)\">$(form.oob)</a>") { use_markup=true, visible=true });
            register_form_continue_label.label = _("Open website");
            register_form_continue.visible = true;
            register_form_continue.grab_focus();
        } else if (form.fields.size > 0) {
            foreach (Xep.DataForms.DataForm.Field field in form.fields) {
                Widget? field_widget = Util.get_data_form_field_widget(field);
                if (field.label != null && field.label != "" && field_widget != null) {
                    form_box.add(new Label(field.label) { xalign=0, margin_top=7, visible=true });
                    form_box.add(field_widget);
                }
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
            show_sign_in_jid();
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
            try {
                Account account = new Account(new Jid.components(username, server_jid.domainpart, null), null, password, null);
                add_activate_account(account);
                show_success(account);
            } catch (InvalidJidError e) {
                warning("Invalid address from components of registration: %s", e.message);
                display_notification(_("Invalid address"));
            }
        } else {
            display_notification(error);
        }
    }

    private void display_notification(string text) {
        notification_label.label = text;
        notification_revealer.set_reveal_child(true);
        Timeout.add_seconds(5, () => {
            notification_revealer.set_reveal_child(false);
            return false;
        });
    }

    private void add_activate_account(Account account) {
        account.enabled = true;
        account.persist(db);
        stream_interactor.connect_account(account);
        added(account);
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
