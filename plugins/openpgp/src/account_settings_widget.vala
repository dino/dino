using Gtk;

using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

[GtkTemplate (ui = "/org/dino-im/account_settings_item.ui")]

private class AccountSettingsWidget : Stack, Plugins.AccountSettingsWidget {
    [GtkChild] private Label label;
    [GtkChild] private Button button;
    [GtkChild] private ComboBox combobox;

    private Plugin plugin;
    private Account current_account;
    private Gtk.ListStore list_store = new Gtk.ListStore(2, typeof(string), typeof(string?));

    public AccountSettingsWidget(Plugin plugin) {
        this.plugin = plugin;

        CellRendererText renderer = new CellRendererText();
        renderer.set_padding(0, 0);
        combobox.pack_start(renderer, true);
        combobox.add_attribute(renderer, "markup", 0);

        button.clicked.connect(on_button_clicked);
        combobox.changed.connect(key_changed);
    }

    public void deactivate() {
        this.set_visible_child_name("label");
    }

    public void set_account(Account account) {
        this.current_account = account;
        populate(account);
    }

    private void on_button_clicked() {
        activated();
        this.set_visible_child_name("entry");
        combobox.popup();
    }

    private void populate(Account account) {
        TreeIter iter;
        combobox.set_model(list_store);

        list_store.clear();
        try {
            Gee.List<GPG.Key> keys = GPGHelper.get_keylist(null, true);

            list_store.append(out iter);
            list_store.set(iter, 0, "Disabled\n<span font='9'>Select key</span>", 1, null);
            set_label_active(iter, 0);
            for (int i = 0; i < keys.size; i++) {
                list_store.append(out iter);
                string text = @"<span font='11'>$(Markup.escape_text(keys[i].uids[0].uid))</span>\n<span font='9'>0x$(Markup.escape_text(keys[i].fpr[0:16]))</span>";
                list_store.set(iter, 0, text);
                list_store.set(iter, 1, keys[i].fpr);
                if (keys[i].fpr == plugin.db.get_account_key(account)) {
                    set_label_active(iter, i + 1);
                }
            }
        } catch (Error e){
            list_store.append(out iter);
            list_store.set(iter, 0, @"Disabled\n<span font='9'>Error: $(Markup.escape_text(e.message))</span>", 1, null);
        }
    }

    private void set_label_active(TreeIter iter, int i = -1) {
        Value text;
        list_store.get_value(iter, 0, out text);
        label.set_markup((string) text);
        if (i != -1) combobox.active = i;
    }

    private void key_changed() {
        TreeIter selected;
        bool iter_valid = combobox.get_active_iter(out selected);
        if (iter_valid) {
            Value key_value;
            list_store.get_value(selected, 1, out key_value);
            string? key_id = key_value as string;
            if (key_id != null) {
                if (plugin.modules.has_key(current_account)) {
                    plugin.modules[current_account].set_private_key_id(key_id);
                }
                plugin.db.set_account_key(current_account, key_id);
            }
            set_label_active(selected);
            deactivate();
        }
    }
}

}