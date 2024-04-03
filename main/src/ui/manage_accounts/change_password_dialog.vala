using Gee;
using Gtk;
//using Pango;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui{

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/change_password_dialog.ui")]
    public class ChangePasswordDialog : Gtk.Dialog {
    
        [GtkChild] private unowned Button change_password_button;
        /*[GtkChild] private unowned Stack change_password_stack; */
        [GtkChild] private unowned Button cancel_button;
        [GtkChild] private unowned Adw.PasswordEntryRow current_password_entry;
        [GtkChild] private unowned Adw.PasswordEntryRow new_password_entry;
        [GtkChild] private unowned Adw.PasswordEntryRow confirm_new_password_entry;
        [GtkChild] private unowned Label change_password_error_label;

        private Account account;
        private StreamInteractor stream_interactor;
        
        public ChangePasswordDialog(Account a, StreamInteractor s){
            Object(use_header_bar : 1);
            this.stream_interactor = s;
            this.account = a;
            Util.force_error_color(change_password_error_label);
            cancel_button.clicked.connect(() => { close(); });
            current_password_entry.changed.connect(on_current_password_entry_changed);
            new_password_entry.changed.connect(on_new_password_entry_changed);
            confirm_new_password_entry.changed.connect(on_confirm_new_password_entry_changed);
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

        private void check_new_password(){
           if (new_password_entry.get_text() != confirm_new_password_entry.get_text()){
                new_password_entry.add_css_class("error");
                confirm_new_password_entry.add_css_class("error");
           } else {
                new_password_entry.remove_css_class("error");
                confirm_new_password_entry.remove_css_class("error");
           }
       }

        private void on_current_password_entry_changed(){
           is_form_filled();
        }
       
        private void on_new_password_entry_changed(){
           is_form_filled();
           check_new_password();
        }
        
        private void on_confirm_new_password_entry_changed(){
           is_form_filled();
           check_new_password();
        }

        private async void on_change_password_button_clicked(){
            string? pw_input = current_password_entry.get_text();
            string? new_pw_input = new_password_entry.get_text();

            if (pw_input != null && account.password == pw_input){
                change_password_button.sensitive = false;
            //    change_password_stack.visible_child_name = "spinner";
                string ret = yield stream_interactor.get_module(Register.IDENTITY).change_password(account, new_pw_input);
                change_password_button.sensitive = true;
            //   change_password_stack.visible_child_name = "label";
                if (ret == null) {
                    account.password = new_pw_input;
                    close();
                }

                change_password_error_label.label = ret;

            } else {
                change_password_error_label.label = _("Wrong password");
            }
        }
    }
}
