using Gee;
using Gtk;
using Markup;
using Pango;

using Dino.Entities;

namespace Dino.Ui.ContactDetails {

[GtkTemplate (ui = "/im/dino/Dino/contact_details_dialog.ui")]
public class Dialog : Gtk.Dialog {

    [GtkChild] public AvatarImage avatar;
    [GtkChild] public Util.EntryLabelHybrid name_hybrid;
    [GtkChild] public Label name_label;
    [GtkChild] public Label jid_label;
    [GtkChild] public Label account_label;
    [GtkChild] public Box main_box;

    private StreamInteractor stream_interactor;
    private Conversation conversation;

    private Plugins.ContactDetails contact_details = new Plugins.ContactDetails();
    private HashMap<string, ListBox> categories = new HashMap<string, ListBox>();
    private Util.LabelHybridGroup hybrid_group = new Util.LabelHybridGroup();

    construct {
        name_hybrid.label.attributes = new AttrList();
        name_hybrid.label.attributes.insert(attr_weight_new(Weight.BOLD));
    }

    public Dialog(StreamInteractor stream_interactor, Conversation conversation) {
        Object(use_header_bar : Util.use_csd() ? 1 : 0);
        this.stream_interactor = stream_interactor;
        this.conversation = conversation;

        title = conversation.type_ == Conversation.Type.GROUPCHAT ? _("Conference Details") : _("Contact Details");
        if (Util.use_csd()) {
            (get_header_bar() as HeaderBar).set_subtitle(Util.get_conversation_display_name(stream_interactor, conversation));
        }
        setup_top();

        contact_details.add.connect(add_entry);

        Application app = GLib.Application.get_default() as Application;
        app.plugin_registry.register_contact_details_entry(new SettingsProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new BlockingProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new MucConfigFormProvider(stream_interactor));
        app.plugin_registry.register_contact_details_entry(new PermissionsProvider(stream_interactor));

        foreach (Plugins.ContactDetailsProvider provider in app.plugin_registry.contact_details_entries) {
            provider.populate(conversation, contact_details, Plugins.WidgetType.GTK);
        }

        destroy.connect(() => {
            contact_details.save();
        });
    }

    private void setup_top() {
        if (conversation.type_ == Conversation.Type.CHAT) {
            name_label.visible = false;
            jid_label.margin_start = new Button().get_style_context().get_padding(StateFlags.NORMAL).left + 1;
            name_hybrid.text = Util.get_conversation_display_name(stream_interactor, conversation);
            destroy.connect(() => {
                if (name_hybrid.text != Util.get_conversation_display_name(stream_interactor, conversation)) {
                    stream_interactor.get_module(RosterManager.IDENTITY).set_jid_handle(conversation.account, conversation.counterpart, name_hybrid.text);
                }
            });
        } else {
            name_hybrid.visible = false;
            name_label.label = Util.get_conversation_display_name(stream_interactor, conversation);
        }
        jid_label.label = conversation.counterpart.to_string();
        account_label.label = "via " + conversation.account.bare_jid.to_string();
        avatar.set_conversation(stream_interactor, conversation);
    }

    private void add_entry(string category, string label, string? description, Object wo) {
        if (!(wo is Widget)) return;
        Widget w = (Widget) wo;
        add_category(category);

        ListBoxRow list_row = new ListBoxRow() { activatable=false, visible=true };
        Box row = new Box(Orientation.HORIZONTAL, 20) { margin_start=15, margin_end=15, margin_top=3, margin_bottom=3, visible=true };
        list_row.add(row);
        Label label_label = new Label(label) { xalign=0, yalign=0.5f, hexpand=true, visible=true };
        if (description != null && description != "") {
            Box box = new Box(Orientation.VERTICAL, 0) { visible=true };
            box.add(label_label);
            Label desc_label = new Label("") { xalign=0, yalign=0.5f, hexpand=true, visible=true };
            desc_label.set_markup("<span size='small'>%s</span>".printf(Markup.escape_text(description)));
            desc_label.get_style_context().add_class("dim-label");
            box.add(desc_label);
            row.add(box);
        } else {
            row.add(label_label);
        }

        Widget widget = w;
        if (widget.get_type().is_a(typeof(Entry))) {
            Util.EntryLabelHybrid hybrid = new Util.EntryLabelHybrid.wrap(widget as Entry) { xalign=1, visible=true };
            hybrid_group.add(hybrid);
            widget = hybrid;
        } else if (widget.get_type().is_a(typeof(ComboBoxText))) {
            Util.ComboBoxTextLabelHybrid hybrid = new Util.ComboBoxTextLabelHybrid.wrap(widget as ComboBoxText) { xalign=1, visible=true };
            hybrid_group.add(hybrid);
            widget = hybrid;
        }
        widget.margin_bottom = 5;
        widget.margin_top = 5;


        row.add(widget);
        categories[category].add(list_row);

        int pref_height, pref_width;
        get_content_area().get_preferred_height(null, out pref_height);
        get_preferred_width(out pref_width, null);
        resize(pref_width, int.min(500, pref_height));
    }

    private void add_category(string category) {
        if (!categories.has_key(category)) {
            ListBox list_box = new ListBox() { selection_mode=SelectionMode.NONE, visible=true };
            categories[category] = list_box;
            list_box.set_header_func((row, before_row) => {
                if (row.get_header() == null && before_row != null) {
                    row.set_header(new Separator(Orientation.HORIZONTAL));
                }
            });
            Box box = new Box(Orientation.VERTICAL, 5) { margin_top=12, margin_bottom=12, visible=true };
            Label category_label = new Label("") { xalign=0, visible=true };
            category_label.set_markup(@"<b>$(Markup.escape_text(category))</b>");
            box.add(category_label);
            Frame frame = new Frame(null) { visible=true };
            frame.add(list_box);
            box.add(frame);
            main_box.add(box);
        }
    }
}

}

