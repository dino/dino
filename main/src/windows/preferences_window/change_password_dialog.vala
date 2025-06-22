using Gee;
using Gtk;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui{

    [GtkTemplate (ui = "/im/dino/Dino/preferences_window/change_password_dialog.ui")]
    public class ChangePasswordDialog : Gtk.Dialog {

        [GtkChild] private unowned Button change_password_button;
        [GtkChild] private unowned Stack change_password_stack;
        [GtkChild] private unowned Button cancel_button;
        [GtkChild] private unowned Adw.PasswordEntryRow current_password_entry;
        [GtkChild] private unowned Adw.PasswordEntryRow new_password_entry;
        [GtkChild] private unowned Adw.PasswordEntryRow confirm_new_password_entry;
        [GtkChild] private unowned Label change_password_error_label;

        private ViewModel.ChangePasswordDialog model;

        public ChangePasswordDialog(ViewModel.ChangePasswordDialog model) {
            Object(use_header_bar : 1);
            this.model = model;

            Util.force_error_color(change_password_error_label);
            cancel_button.clicked.connect(() => { close(); });
            current_password_entry.changed.connect(is_form_filled);
            new_password_entry.changed.connect(is_form_filled);
            confirm_new_password_entry.changed.connect(is_form_filled);
            change_password_button.clicked.connect(on_change_password_button_clicked);
        }

        private void is_form_filled(){
            if (current_password_entry.get_text().length > 0
                    && new_password_entry.get_text().length > 0
                    && confirm_new_password_entry.get_text().length > 0
                    && new_password_entry.get_text() == confirm_new_password_entry.get_text()){
                change_password_button.sensitive = true;
            } else {
                change_password_button.sensitive = false;
            }
        }

        private async void on_change_password_button_clicked(){
            string? pw_input = current_password_entry.get_text();
            string? new_pw_input = new_password_entry.get_text();

            var password = yield model.account.get_password();

            if (pw_input != null && password == pw_input){
                change_password_button.sensitive = false;
                change_password_stack.visible_child_name = "spinner";
                string? ret = yield model.change_password(new_pw_input);
                change_password_button.sensitive = true;
                change_password_stack.visible_child_name = "label";
                if (ret == null) {
                    close();
                }

                change_password_error_label.label = "Error: %s".printf(ret);

            } else {
                change_password_error_label.label = "Wrong current password";
            }
        }
    }
}
