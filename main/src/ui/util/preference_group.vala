using Gee;
using Gdk;
using Gtk;

using Dino.Entities;
using Xmpp.Xep;

namespace Dino.Ui.Util {
    public Gee.List<Adw.PreferencesGroup> rows_to_preference_window_split_at_text(GLib.ListStore row_view_models) {
        var preference_groups = new ArrayList<Adw.PreferencesGroup>();
        Adw.PreferencesGroup? preference_group = null;

        for (int preference_group_i = 0; preference_group_i < row_view_models.get_n_items(); preference_group_i++) {
            var preferences_row = (ViewModel.PreferencesRow.Any) row_view_models.get_item(preference_group_i);

            // If it's a text, start a new PreferencesGroup with the text as title. Else, add an item to the current group.
            var preferences_row_text = preferences_row as ViewModel.PreferencesRow.Text;
            if (preferences_row_text != null) {
                if (preference_group != null) preference_groups.add(preference_group);
                preference_group = new Adw.PreferencesGroup() { title=preferences_row_text.text };
            } else {
                if (preference_group == null) {
                    preference_group = new Adw.PreferencesGroup();
                }
                Widget? w = row_to_preference_row(preferences_row);
                if (w == null) continue;
                preference_group.add(w);
            }

        }

        return preference_groups;
    }

    public Adw.PreferencesGroup rows_to_preference_group(GLib.ListStore row_view_models, string title) {
        var preference_group = new Adw.PreferencesGroup() { title=title };

        for (int preference_group_i = 0; preference_group_i < row_view_models.get_n_items(); preference_group_i++) {
            var preferences_row = (ViewModel.PreferencesRow.Any) row_view_models.get_item(preference_group_i);

            Widget? w = row_to_preference_row(preferences_row);
            if (w == null) continue;

            preference_group.add(w);
        }

        return preference_group;
    }

    private static bool null_string_to_empty(GLib.Binding binding, GLib.Value from_value, ref GLib.Value to_value) {
        var str = (string) from_value;
        to_value = str ?? "";
        return true;
    }

    public Adw.PreferencesRow? row_to_preference_row(ViewModel.PreferencesRow.Any preferences_row) {
        Adw.PreferencesRow? view = null;

        var entry_view_model = preferences_row as ViewModel.PreferencesRow.Entry;
        if (entry_view_model != null) {
            view = new Adw.EntryRow() { show_apply_button=true };
            if (preferences_row.media_uri != null) {
                var bytes = Xmpp.get_data_for_uri(preferences_row.media_uri);
                Picture picture = new Picture.for_paintable(Texture.from_bytes(bytes));
                ((Adw.EntryRow) view).add_suffix(picture);
            }
            entry_view_model.bind_property("text", view, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, null_string_to_empty);
            ((Adw.EntryRow) view).apply.connect(() => {
                entry_view_model.changed();
            });
        }

        var password_view_model = preferences_row as ViewModel.PreferencesRow.PrivateText;
        if (password_view_model != null) {
            view = new Adw.PasswordEntryRow() { show_apply_button=true };
            password_view_model.bind_property("text", view, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, null_string_to_empty);
            ((Adw.EntryRow) view).apply.connect(() => {
                password_view_model.changed();
            });
        }

        var row_text = preferences_row as ViewModel.PreferencesRow.Text;
        if (row_text != null) {
            view = new Adw.ActionRow() {
                subtitle_selectable = true
            };
            row_text.bind_property("text", view, "subtitle", BindingFlags.SYNC_CREATE, null_string_to_empty);
            view.add_css_class("property");

            Util.force_css(view, "row.property > box.header > box.title > .title { font-weight: 400; font-size: 9pt; opacity: 0.55; }");
            Util.force_css(view, "row.property > box.header > box.title > .subtitle { font-size: inherit; opacity: 1; }");
        }

        var toggle_view_model = preferences_row as ViewModel.PreferencesRow.Toggle;
        if (toggle_view_model != null) {
            view = new Adw.SwitchRow();
            toggle_view_model.bind_property("subtitle", view, "subtitle", BindingFlags.SYNC_CREATE, null_string_to_empty);
            toggle_view_model.bind_property("state", view, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }

        var combobox_view_model = preferences_row as ViewModel.PreferencesRow.ComboBox;
        if (combobox_view_model != null) {
            var string_list = new StringList(null);
            foreach (string text in combobox_view_model.items) {
                string_list.append(text);
            }
            view = new Adw.ComboRow();
            combobox_view_model.bind_property("subtitle", view, "subtitle", BindingFlags.SYNC_CREATE, null_string_to_empty);
            ((Adw.ComboRow)view).model = string_list;
            combobox_view_model.bind_property("active-item", view, "selected", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }

        var button_view_model = preferences_row as ViewModel.PreferencesRow.Button;
        if (button_view_model != null) {
            view = new Adw.ActionRow();
            button_view_model.bind_property("subtitle", view, "subtitle", BindingFlags.SYNC_CREATE, null_string_to_empty);
            var button = new Button.with_label(button_view_model.button_text) { valign = Align.CENTER };
            ((Adw.ActionRow)view).add_suffix(button);
            button.clicked.connect(() => button_view_model.clicked());
        }

        preferences_row.bind_property("title", view, "title", BindingFlags.SYNC_CREATE);
        preferences_row.bind_property("visible", view, "visible", BindingFlags.SYNC_CREATE);

        return view;
    }
}