using Dino.Entities;
using Gtk;

namespace Dino.Plugins.OpenPgp {

public class AccountSettingsEntry : Plugins.AccountSettingsEntry {

    private Label label;
    private Button button;
    private ComboBox combobox;
    private Stack stack;

    private Plugin plugin;
    private Account current_account;
    private Gee.List<GPG.Key> keys = null;
    private Gtk.ListStore list_store = new Gtk.ListStore(2, typeof(string), typeof(string?));

    public override string id { get { return "pgp_key_picker"; }}

    public override string name { get { return "OpenPGP"; }}

    public AccountSettingsEntry(Plugin plugin) {
        this.plugin = plugin;

        Builder builder = new Builder.from_resource("/im/dino/Dino/openpgp/account_settings_item.ui");
        stack = (Stack) builder.get_object("stack");
        label = (Label) builder.get_object("label");
        button = (Button) builder.get_object("button");
        combobox = (ComboBox) builder.get_object("combobox");

        CellRendererText renderer = new CellRendererText();
        renderer.set_padding(0, 0);
        combobox.pack_start(renderer, true);
        combobox.add_attribute(renderer, "markup", 0);
        combobox.set_model(list_store);

        button.clicked.connect(on_button_clicked);
        combobox.changed.connect(key_changed);
    }

    public override void deactivate() {
        stack.set_visible_child_name("label");
    }

    public override void set_account(Account account) {
        set_account_.begin(account);
    }

    private async void set_account_(Account account) {
        this.current_account = account;
        if (keys == null) {
            yield fetch_keys();
            populate_list_store();
        }
        activate_current_account();
    }

    private void on_button_clicked() {
        activated();
        stack.set_visible_child_name("entry");
        combobox.grab_focus();
        combobox.popup();
    }

    private void activate_current_account() {
        combobox.changed.disconnect(key_changed);
        if (keys == null) {
            label.set_markup(build_markup_string(_("Key publishing disabled"), _("Error in GnuPG")));
            return;
        }
        if (keys.size == 0) {
            label.set_markup(build_markup_string(_("Key publishing disabled"), _("No keys available. Generate one!")));
            return;
        }

        string? account_key = plugin.db.get_account_key(current_account);
        int activate_index = 0;
        for (int i = 0; i < keys.size; i++) {
            GPG.Key key = keys[i];
            if (key.fpr == account_key) {
                activate_index = i + 1;
            }
        }
        combobox.active = activate_index;

        TreeIter selected;
        combobox.get_active_iter(out selected);
        set_label_active(selected);

        combobox.changed.connect(key_changed);
    }

    private void populate_list_store() {
        if (keys == null || keys.size == 0) {
            return;
        }

        list_store.clear();
        TreeIter iter;
        list_store.append(out iter);
        list_store.set(iter, 0, build_markup_string(_("Key publishing disabled"), _("Select key") + "<span font_family='monospace' font='8'> \n </span>"), 1, "");
        for (int i = 0; i < keys.size; i++) {
            list_store.append(out iter);
            list_store.set(iter, 0, @"$(Markup.escape_text(keys[i].uids[0].uid))\n<span font_family='monospace' font='8'>$(markup_colorize_id(keys[i].fpr, true))</span><span font='8'> </span>");
            list_store.set(iter, 1, keys[i].fpr);
            if (keys[i].fpr == plugin.db.get_account_key(current_account)) {
                set_label_active(iter, i + 1);
            }
        }
        button.sensitive = true;
    }

    private async void fetch_keys() {
        label.set_markup(build_markup_string(_("Loading…"), _("Querying GnuPG")));

        SourceFunc callback = fetch_keys.callback;
        new Thread<void*> (null, () => { // Querying GnuPG might take some time
            try {
            keys = GPGHelper.get_keylist(null, true);
        } catch (Error e) { }
            Idle.add((owned)callback);
            return null;
        });
        yield;
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

    private string build_markup_string(string primary, string secondary) {
        return @"$(Markup.escape_text(primary))\n<span font='8'>$secondary</span>";
    }

    public override Object? get_widget(WidgetType type) {
        if (type != WidgetType.GTK4) return null;
        return stack;
    }
}
}