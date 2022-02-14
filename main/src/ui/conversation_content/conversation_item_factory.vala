using Gtk;

namespace Dino.Ui {

    public static ListItemFactory get_item_factory() {
        SignalListItemFactory item_factory = new SignalListItemFactory();
        item_factory.setup.connect((list_item) => { on_setup(list_item); });
        item_factory.bind.connect((list_item) => { on_bind(list_item); });
        return item_factory;
    }

    public static void on_setup(ListItem listitem) {
        listitem.child = new ConversationItemWidget();
    }

    public static void on_bind(ListItem listitem) {
        MessageViewModel view_model = (MessageViewModel) listitem.get_item();
        ConversationItemWidget view = (ConversationItemWidget) listitem.get_child();

        view_model.bind_property("name", view.name_label, "label", BindingFlags.SYNC_CREATE);
        view_model.bind_property("time", view.time_label, "label", BindingFlags.SYNC_CREATE);

        Label? label = view.content_widget as Label;
        if (label == null) {
            label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, hexpand=true, vexpand=true };
            view.set_content_widget(label);
        }
        view_model.bind_property("message", label, "label", BindingFlags.SYNC_CREATE);

        view_model.bind_property("encryption-icon-name", view.encrypted_image, "icon-name", BindingFlags.SYNC_CREATE);
        view_model.bind_property("encryption-icon-tooltip", view.encrypted_image, "tooltip-text", BindingFlags.SYNC_CREATE);

        view_model.bind_property("marked-icon-name", view.marked_image, "icon-name", BindingFlags.SYNC_CREATE);
        view_model.bind_property("marked-icon-tooltip", view.marked_image, "tooltip-text", BindingFlags.SYNC_CREATE);
    }
}