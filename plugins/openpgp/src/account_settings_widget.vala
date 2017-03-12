using Dino.Entities;

namespace Dino.Plugins.OpenPgp {

[GtkTemplate (ui = "/org/dino-im/account_settings_item.ui")]

private class AccountSettingsWidget : Gtk.Stack, Plugins.AccountSettingsWidget {
    [GtkChild] private Gtk.Label pgp_label;
    [GtkChild] private Gtk.Button pgp_button;
    [GtkChild] private Gtk.ComboBox pgp_combobox;

    private Gtk.ListStore list_store = new Gtk.ListStore(2, typeof(string), typeof(string?));

    public AccountSettingsWidget() {
        Gtk.CellRendererText renderer = new Gtk.CellRendererText();
        renderer.set_padding(0, 0);
        pgp_combobox.pack_start(renderer, true);
        pgp_combobox.add_attribute(renderer, "markup", 0);
        pgp_button.clicked.connect(() => { activated(); this.set_visible_child_name("entry"); pgp_combobox.popup(); });
    }

    public void deactivate() {
        this.set_visible_child_name("label");
    }

    private void key_changed() {
        Gtk.TreeIter selected;
        pgp_combobox.get_active_iter(out selected);
        Value text;
        list_store.get_value(selected, 0, out text);
        pgp_label.set_markup((string) text);
        deactivate();
    }

    public void set_account(Account account) {
        populate_pgp_combobox(account);
    }

    private void populate_pgp_combobox(Account account) {
        pgp_combobox.changed.disconnect(key_changed);

        Gtk.TreeIter iter;
        pgp_combobox.set_model(list_store);

        list_store.clear();
        list_store.append(out iter);
        pgp_label.set_markup("Disabled\n<span font='9'>Select key</span>");
        list_store.set(iter, 0, "Disabled\n<span font='9'>Select key</span>", 1, null);
        Gee.List<GPG.Key> list = GPGHelper.get_keylist(null, true);
        foreach (GPG.Key key in list) {
            list_store.append(out iter);
            list_store.set(iter, 0, @"<span font='11'>$(Markup.escape_text(key.uids[0].uid))</span>\n<span font='9'>0x$(Markup.escape_text(key.fpr[0:16]))</span>");
            list_store.set(iter, 1, key.fpr);
        }

        pgp_combobox.set_active(0);
        pgp_combobox.changed.connect(key_changed);
    }
}

}