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

    public Adw.PreferencesRow? row_to_preference_row(ViewModel.PreferencesRow.Any preferences_row) {
        var entry_view_model = preferences_row as ViewModel.PreferencesRow.Entry;
        if (entry_view_model != null) {
            Adw.EntryRow view = new Adw.EntryRow() { title = entry_view_model.title, show_apply_button=true };
            if (preferences_row.media_uri != null) {
                var bytes = Xmpp.get_data_for_uri(preferences_row.media_uri);
                Picture picture = new Picture.for_paintable(Texture.from_bytes(bytes));
                view.add_suffix(picture);
            }
            entry_view_model.bind_property("text", view, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, (_, from, ref to) => {
                var str = (string) from;
                to = str ?? "";
                return true;
            });
            view.apply.connect(() => {
                entry_view_model.changed();
            });
            return view;
        }

        var password_view_model = preferences_row as ViewModel.PreferencesRow.PrivateText;
        if (password_view_model != null) {
            Adw.PasswordEntryRow view = new Adw.PasswordEntryRow() { title = password_view_model.title, show_apply_button=true };
            password_view_model.bind_property("text", view, "text", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL, (_, from, ref to) => {
                var str = (string) from;
                to = str ?? "";
                return true;
            });
            view.apply.connect(() => {
                password_view_model.changed();
            });

            return view;
        }

        var row_text = preferences_row as ViewModel.PreferencesRow.Text;
        if (row_text != null) {
            var view = new Adw.ActionRow() {
                title = row_text.title,
                subtitle = row_text.text,
                subtitle_selectable = true
            };
            view.add_css_class("property");

            Util.force_css(view, "row.property > box.header > box.title > .title { font-weight: 400; font-size: 9pt; opacity: 0.55; }");
            Util.force_css(view, "row.property > box.header > box.title > .subtitle { font-size: inherit; opacity: 1; }");
            return view;
        }

        var toggle_view_model = preferences_row as ViewModel.PreferencesRow.Toggle;
        if (toggle_view_model != null) {
            var view = new Adw.ActionRow() { title = toggle_view_model.title, subtitle = toggle_view_model.subtitle };
            var toggle = new Switch() { valign = Align.CENTER };
            view.activatable_widget = toggle;
            view.add_suffix(toggle);
            toggle_view_model.bind_property("state", toggle, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            return view;
        }

        var combobox_view_model = preferences_row as ViewModel.PreferencesRow.ComboBox;
        if (combobox_view_model != null) {
            var string_list = new StringList(null);
            foreach (string text in combobox_view_model.items) {
                string_list.append(text);
            }
            var view = new Adw.ComboRow() { title = combobox_view_model.title };
            view.model = string_list;
            combobox_view_model.bind_property("active-item", view, "selected", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            return view;
        }

        var button_view_model = preferences_row as ViewModel.PreferencesRow.Button;
        if (button_view_model != null) {
            var view = new Adw.ActionRow() { title = button_view_model.title };
            var button = new Button.with_label(button_view_model.button_text) { valign = Align.CENTER };
            view.add_suffix(button);
            button.clicked.connect(() => button_view_model.clicked());
            return view;
        }

        return null;
    }
}