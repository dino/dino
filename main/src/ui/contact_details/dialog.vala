using Gee;
using Gtk;
using Markup;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

[GtkTemplate (ui = "/im/dino/Dino/contact_details_dialog.ui")]
public class Dialog : Gtk.Window {

    [GtkChild] public unowned AvatarPicture avatar;
    [GtkChild] public unowned Util.EntryLabelHybrid name_hybrid;
    [GtkChild] public unowned Label name_label;
    [GtkChild] public unowned Label jid_label;
    [GtkChild] public unowned Label account_label;
    [GtkChild] public unowned Box main_box;

    private StreamInteractor stream_interactor;
    private Conversation conversation;

    private Plugins.ContactDetails contact_details = new Plugins.ContactDetails();
    private HashMap<string, Adw.PreferencesGroup> categories = new HashMap<string, Adw.PreferencesGroup>();
    private Util.LabelHybridGroup hybrid_group = new Util.LabelHybridGroup();

    construct {
        name_hybrid.label.add_css_class("title-1");
        name_hybrid.label.wrap = true;
        name_hybrid.label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_hybrid.label.ellipsize = Pango.EllipsizeMode.NONE;
        name_hybrid.label.justify = Gtk.Justification.CENTER;
    }

    public Dialog(StreamInteractor stream_interactor, Conversation conversation) {
        Object();

        this.stream_interactor = stream_interactor;
        this.conversation = conversation;

        title = conversation.type_ == Conversation.Type.GROUPCHAT ? _("Conference Details") : _("Contact Details");
        Box titles_box = new Box(Orientation.VERTICAL, 0) { valign=Align.CENTER };
        var title_label = new Label(title);
        title_label.add_css_class("title");
        titles_box.append(title_label);
        var subtitle_label = new Label(Util.get_conversation_display_name(stream_interactor, conversation));
        subtitle_label.add_css_class("subtitle");
        titles_box.append(subtitle_label);

        ((Gtk.HeaderBar) titlebar).set_title_widget(titles_box);
        setup_top();

        contact_details.add.connect(add_entry);

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_contact_details_entry(new SettingsProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new BlockingProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new MucConfigFormProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new PermissionsProvider(stream_interactor));

        foreach (Plugins.ContactDetailsProvider provider in app.plugin_registry.contact_details_entries) {
            provider.populate(conversation, contact_details, Plugins.WidgetType.GTK4);
        }

        close_request.connect(() => {
            contact_details.save();
            return false;
        });
    }

    private void setup_top() {
        if (conversation.type_ == Conversation.Type.CHAT) {
            name_label.visible = false;
            name_hybrid.text = Util.get_conversation_display_name(stream_interactor, conversation);
            close_request.connect(() => {
                if (name_hybrid.text != Util.get_conversation_display_name(stream_interactor, conversation)) {
                    stream_interactor.get_module(RosterManager.IDENTITY).set_jid_handle(conversation.account, conversation.counterpart, name_hybrid.text);
                }
                return false;
            });
        } else {
            name_hybrid.visible = false;
            name_label.label = Util.get_conversation_display_name(stream_interactor, conversation);
        }
        jid_label.label = conversation.counterpart.to_string();
        account_label.label = "via " + conversation.account.bare_jid.to_string();
        avatar.model = new ViewModel.CompatAvatarPictureModel(stream_interactor).set_conversation(conversation);
    }

    private void add_entry(string category, string label, string? description, Object wo) {
        if (!(wo is Widget)) return;
        Widget w = (Widget) wo;
        add_category(category);

        var row = new Adw.ActionRow() { title=label, subtitle=description };

        Widget widget = w;
        if (widget.get_type().is_a(typeof(Entry))) {
            Util.EntryLabelHybrid hybrid = new Util.EntryLabelHybrid.wrap(widget as Entry) { xalign=1 };
            hybrid_group.add(hybrid);
            widget = hybrid;
        } else if (widget.get_type().is_a(typeof(ComboBoxText))) {
            Util.ComboBoxTextLabelHybrid hybrid = new Util.ComboBoxTextLabelHybrid.wrap(widget as ComboBoxText) { xalign=1 };
            hybrid_group.add(hybrid);
            widget = hybrid;
        }
        widget.valign = Align.CENTER;

        row.add_suffix(widget);
        row.activatable_widget = widget;

        categories[category].add(row);
    }

    private void add_category(string category) {
        if (!categories.has_key(category)) {
            var prefs_group = new Adw.PreferencesGroup() { title=category };
            categories[category] = prefs_group;
            main_box.append(prefs_group);
        }
    }
}

}

