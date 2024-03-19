using Gee;
using Gtk;
//using Pango;

using Dino.Entities;
using Xmpp;

namespace Dino.Ui{

[GtkTemplate (ui = "/im/dino/Dino/manage_accounts/change_password_dialog.ui")]
    public class ChangePasswordDialog : Gtk.Dialog {
    
        [GtkChild] private unowned Button change_password_button;
        [GtkChild] private unowned Stack change_password_stack;
        [GtkChild] private unowned Button cancel_button;
        [GtkChild] private unowned Entry current_passwd_entry;
        [GtkChild] private unowned Entry new_passwd_entry;
        [GtkChild] private unowned Entry confirm_new_passwd_entry;
        [GtkChild] private unowned Label change_password_error_label;

        private bool are_forms_empty;
        private Account account;
        private StreamInteractor stream_interactor;
        
        public ChangePasswordDialog(Account a, StreamInteractor s){
            Object(use_header_bar : 1);
            this.stream_interactor = s;
            this.account = a;
            Util.force_error_color(change_password_error_label);
            cancel_button.clicked.connect(() => { close(); });
            current_passwd_entry.changed.connect(on_current_passwd_entry_changed);
            new_passwd_entry.changed.connect(on_new_passwd_entry_changed);
            confirm_new_passwd_entry.changed.connect(on_confirm_new_passwd_entry_changed);
            change_password_button.clicked.connect(on_change_password_button_clicked);
        }
       
        private void are_psswd_nonempty(){
            EntryBuffer newpsswd = new_passwd_entry.get_buffer();
            EntryBuffer confirm_newpsswd = confirm_new_passwd_entry.get_buffer();

            if (current_passwd_entry.get_text_length() > 0
                && new_passwd_entry.get_text_length() > 0
                && confirm_new_passwd_entry.get_text_length() > 0
                && newpsswd.get_text() == confirm_newpsswd.get_text()){
                are_forms_empty = false;
                change_password_button.sensitive = true;
            } else {
                are_forms_empty = true;
                change_password_button.sensitive = false;
            }
        }

        private void check_new_passwd(){
           EntryBuffer newpsswd = new_passwd_entry.get_buffer();
           EntryBuffer confirm_newpsswd = confirm_new_passwd_entry.get_buffer();

           if (newpsswd.get_text() != confirm_newpsswd.get_text()){
                new_passwd_entry.add_css_class("error"); 
                confirm_new_passwd_entry.add_css_class("error");
           } else {
                new_passwd_entry.remove_css_class("error"); 
                confirm_new_passwd_entry.remove_css_class("error");
           }
       }

        private void on_current_passwd_entry_changed(){
           are_psswd_nonempty();
        }
       
        private void on_new_passwd_entry_changed(){
           are_psswd_nonempty();
           check_new_passwd();
        }
        
        private void on_confirm_new_passwd_entry_changed(){
           are_psswd_nonempty();
           check_new_passwd();
        }

        private async void on_change_password_button_clicked(){
            string? pw_input = current_passwd_entry.get_buffer().get_text();
            string? new_pw_input = new_passwd_entry.get_buffer().get_text();

            if (pw_input != null && account.password == pw_input){
                change_password_button.sensitive = false;
                change_password_stack.visible_child_name = "spinner";
                string ret = yield stream_interactor.get_module(Register.IDENTITY).change_password(account, new_pw_input);
                change_password_button.sensitive = true;
                change_password_stack.visible_child_name = "label";
                if (ret == null)
                    close();

                change_password_error_label.label = ret;

            } else {
                change_password_error_label.label = _("Wrong password");
            }
        }
    }
}
