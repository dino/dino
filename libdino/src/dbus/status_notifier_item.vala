namespace Dino {

[DBus (name = "org.kde.StatusNotifierWatcher")]
private interface DBusStatusNotifierWatcher : Object {
    [DBus (name = "RegisterStatusNotifierItem")]
    public abstract async void register_item(string service);

    [DBus (name = "RegisteredStatusNotifierItems")]
    public abstract string[] registered_items { owned get; }
    [DBus (name = "IsStatusNotifierHostRegistered")]
    public abstract bool is_host_registered {  get; }
    [DBus (name = "ProtocolVersion")]
    public abstract int version {  get; }

    [DBus (name = "StatusNotifierItemRegistered")]
    public signal void item_registered(string service);
    [DBus (name = "StatusNotifierItemUnregistered")]
    public signal void item_unregistered(string service);
    [DBus (name = "StatusNotifierHostRegistered")]
    public signal void host_registered();
    [DBus (name = "StatusNotifierHostUnregistered")]
    public signal void host_unregistered();
}

[DBus (name = "org.kde.StatusNotifierItem")]
private class DBusStatusNotifierItem : Object {
    private StatusNotifierItem item;
    private ObjectPath menu_path;

    public DBusStatusNotifierItem(StatusNotifierItem item, ObjectPath? menu_path) {
        this.item = item;
        this.menu_path = menu_path ?? new ObjectPath("/NO_DBUSMENU");
    }

    [DBus (name = "Category")]
    public string category { owned get { return item.category; } }
    [DBus (name = "Id")]
    public string id { owned get { return item.id; } }
    [DBus (name = "Title")]
    public string title { owned get { return item.title; } }
    [DBus (name = "Status")]
    public string status { owned get { return item.status; } }
    [DBus (name = "WindowId")]
    public int32 window_id { get { return item.window_id; } }
    [DBus (name = "IconName")]
    public string icon_name { owned get { return item.icon_name; } }
    [DBus (name = "OverlayIconName")]
    public string overlay_icon_name { owned get { return item.overlay_icon_name ?? ""; } }
    [DBus (name = "AttentionIconName")]
    public string attention_icon_name { owned get { return item.attention_icon_name ?? icon_name; } }
    [DBus (name = "ToolTip")]
    public DBusStatusNotifierItemToolTip tool_tip { owned get { return item.tool_tip ?? DBusStatusNotifierItemToolTip.empty(); } }
    [DBus (name = "ItemIsMenu")]
    public bool is_menu { get { return item.is_menu; } }
    [DBus (name = "Menu")]
    public ObjectPath menu { get { return menu_path; } }

    [DBus (name = "ContextMenu")]
    public void context_menu(int x, int y) { item.context_menu(x, y); }
    [DBus (name = "Activate")]
    public void activate(int x, int y) { item.activate(x, y); }
    [DBus (name = "SecondaryActivate")]
    public void secondary_activate(int x, int y) { item.secondary_activate(x, y); }
    [DBus (name = "Scroll")]
    public void scroll(int delta, string orientation) { item.scroll(delta, orientation); }

    [DBus (name = "NewTitle")]
    public signal void on_new_title();
    [DBus (name = "NewIcon")]
    public signal void on_new_icon();
    [DBus (name = "NewMenu")]
    public signal void on_new_menu();
    [DBus (name = "NewToolTip")]
    public signal void on_new_tool_tip();
    [DBus (name = "NewStatus")]
    public signal void on_new_status(string status);
}

[DBus (name = "com.canonical.dbusmenu")]
private class DBusMenu : Object {
    private StatusNotifierItem item;
    private string _text_direction;

    public DBusMenu(StatusNotifierItem item, string text_direction) {
        this.item = item;
        _text_direction = text_direction;
    }

    [DBus (name = "TextDirection")]
    public string text_direction { get { return _text_direction; } }
    [DBus (name = "Version")]
    public uint32 version { get { return 3; } }
    [DBus (name = "Status")]
    public string status { get { return "normal"; } }

    private static int32[] get_children_ids(int32 parent_id, MenuModel model) {
        MenuModel local_model = model;
        int32 local_id = parent_id;
        if (local_id != 0) {
            var sub_id = local_id % 0xff - 1;
            HashTable<string,MenuModel> links;
            if (local_model.get_n_items() <= sub_id) return {};
            local_model.get_item_links(sub_id, out links);
            if (links == null || links.size() == 0) return {};
            local_model = links.get_values().first().data;
            local_id = local_id >> 8;
        }
        int n = local_model.get_n_items();
        int32[] arr = new int32[n];
        for(int i = 0; i < n; i++) {
            arr[i] = (parent_id << 8) + i + 1;
        }
        return arr;
    }

    private static Gee.Map<string, Variant>? get_properties(int32 id, MenuModel model) {
        if (id == 0) {
            Gee.Map<string, Variant> result = new Gee.HashMap<string, Variant>();
            result["children-display"] = "submenu";
            return result;
        }
        MenuModel local_model = model;
        int32 local_id = id;
        if (local_id > 0xff) {
            var sub_id = local_id % 0xff - 1;
            HashTable<string,MenuModel> links;
            if (local_model.get_n_items() <= sub_id) return null;
            local_model.get_item_links(sub_id, out links);
            if (links == null || links.size() == 0) return null;
            local_model = links.get_values().first().data;
            local_id = local_id >> 8;
        }
        var sub_id = local_id - 1;
        if (local_model.get_n_items() <= sub_id) return null;
        HashTable<string,Variant> attributes;
        local_model.get_item_attributes(sub_id, out attributes);
        if (attributes == null) return null;
        Gee.Map<string, Variant> result = new Gee.HashMap<string, Variant>();
        attributes.for_each((key, val) => {
            switch(key) {
                case "submenu": result["children-display"] = "submenu"; break;
                case "section": result["children-display"] = "section"; break;
                default: result[key] = val; break;
            }
        });
        return result;
    }

    private static VariantDict? get_properties_dict(int32 id, MenuModel model, string[] property_names) {
        var properties = get_properties(id, model);
        if (properties == null) return null;
        var dict = new VariantDict();
        foreach(var entry in properties) {
            if (entry.key in property_names || property_names.length == 0) {
                dict.insert_value(entry.key, entry.value);
            }
        }
        return dict;
    }

    [DBus (name = "GetLayout")]
    public void get_layout(int32 parent_id, int32 recursion_depth, string[] property_names, out uint revision, [DBus (signature = "(ia{sv}av)")] out Variant layout) {
        var builder = new VariantBuilder(new VariantType("(ia{sv}av)"));
        builder.add("i", parent_id);
        var properties = get_properties_dict(parent_id, item.menu_model, property_names) ?? new VariantDict();
        builder.add_value(properties.end());
        Variant[] children = {};
        if (recursion_depth != 0) {
            int32[] ids = get_children_ids(parent_id, item.menu_model);
            foreach(int32 id in ids) {
                Variant child;
                get_layout(id, recursion_depth - 1, property_names, null, out child);
                children += new Variant.variant(child);
            }
        }
        builder.add_value(new Variant.array(VariantType.VARIANT, children));
        revision = item.menu_model_revision;
        layout = builder.end();
    }

    [DBus (name = "GetGroupProperties")]
    public void get_group_properties(int32[] ids, string[] property_names, [DBus (signature = "a(ia{sv})")] out Variant properties) {
        Variant[] items = {};
        foreach(int32 id in ids) {
            var properties_dict = get_properties_dict(id, item.menu_model, property_names);
            if (properties_dict != null) {
                var builder = new VariantBuilder(new VariantType("(ia{sv})"));
                builder.add("i", id);
                builder.add_value(properties_dict.end());
                items += builder.end();
            }
        }
        properties = new Variant.array(new VariantType("(ia{sv})"), items);
    }

    [DBus (name = "GetProperty")]
    public void get_property(int32 id, string name, out Variant value) {
        var properties = get_properties(id, item.menu_model);
        if (properties != null && properties.has_key(name)) {
            value = properties[name];
        } else {
            value = null;
        }
    }

    private bool resolve_event(int32 id, string event_id, Variant data, uint32 timestamp) {
        if (event_id == "clicked") {
            if (id == 0) return false;
            MenuModel local_model = item.menu_model;
            int32 local_id = id;
            if (local_id > 0xff) {
                var sub_id = local_id % 0xff - 1;
                HashTable<string,MenuModel> links;
                if (local_model.get_n_items() <= sub_id) return false;
                local_model.get_item_links(sub_id, out links);
                if (links == null || links.size() == 0) return false;
                local_model = links.get_values().first().data;
                local_id = local_id >> 8;
            }
            var sub_id = local_id - 1;
            if (local_model.get_n_items() <= sub_id) return false;
            Variant? action_variant = local_model.get_item_attribute_value(sub_id, "action", VariantType.STRING);
            if (action_variant == null) return false;
            size_t action_length;
            unowned string actionu = action_variant.get_string(out action_length);
            string detailed_action = actionu.substring(0, (long) action_length);
            string action;
            Variant parameter;
            Action.parse_detailed_name(detailed_action, out action, out parameter);
            if (action.has_prefix("app.")) {
                GLib.Application.get_default().activate_action(action.substring(4), parameter);
            } else {
                warning("Unknown action: %s", action);
                return false;
            }
        } else {
            return false;
        }
        return true;
    }

    [DBus (name = "Event")]
    public void event(int32 id, string event_id, Variant data, uint32 timestamp) {
        resolve_event(id, event_id, data, timestamp);
    }

    [DBus (name = "EventGroup")]
    public int[] event_group(DBusMenuEventStruct[] events) throws DBusError
    {
        var ret = new Gee.ArrayList<int>();
        foreach(var ev in events) {
            if (!resolve_event(ev.id, ev.event_id, ev.data, ev.timestamp)) {
                ret.add(ev.id);
            }
        }

        if (ret.size == events.length) {
            throw new DBusError.INVALID_ARGS("None of the events were valid.");
        }

        return ret.to_array();
    }

    public struct DBusMenuEventStruct {
        public int id;
        public string event_id;
        public GLib.Variant data;
        public uint timestamp;
    }

    [DBus (name = "AboutToShow")]
    public bool about_to_show(int32 id) {
        return false;
    }

    [DBus (name = "ItemsPropertiesUpdated")]
    public signal void item_properties_updated([DBus (signature = "a(ia{sv})")] Variant updated_properties, [DBus (signature = "a(ias)")] Variant removed_properties);
    [DBus (name = "LayoutUpdated")]
    public signal void layout_updated(uint32 revision, int32 parent);
    [DBus (name = "ItemActivationRequested")]
    public signal void item_activation_requested(int32 id, uint32 timestamp);
}

public struct DBusStatusNotifierIconData {
    public int width;
    public int height;
    public uint8[] data;
}

public struct DBusStatusNotifierItemToolTip {
    public string icon_name;
    public DBusStatusNotifierIconData[] icon;
    public string title;
    public string body;

    public static DBusStatusNotifierItemToolTip empty() {
        return { "", {}, "", "" };
    }
}

public class StatusNotifierItem : Object {
    public string id { get; set; }
    public string title { get; set; }
    public string category { get; set; }
    public string status { get; set; }
    public int32 window_id { get; set; }
    public bool is_menu = false;
    public string icon_name { get; set; }
    public string? overlay_icon_name { get; set; }
    public string? attention_icon_name { get; set; }
    public DBusStatusNotifierItemToolTip? tool_tip { get; set; }
    public MenuModel? menu_model { get; set; }
    public uint32 menu_model_revision = 1;
    public string text_direction { get; set; }

    public signal void context_menu(int x, int y);
    public signal void activate(int x, int y);
    public signal void secondary_activate(int x, int y);
    public signal void scroll(int delta, string orientation);

    private DBusStatusNotifierItem dbus_item;
    private DBusMenu dbus_menu;
    private static int last_registration_id = 0;
    private int registration_id = last_registration_id++;
    private string name { owned get { return @"$id-$((int)Posix.getpid())-$registration_id"; } }
    private bool registered;
    private uint name_owner_id;
    private DBusConnection dbus_connection;
    private uint dbus_item_registration_id;
    private uint dbus_menu_registration_id;

    private void on_bus_aquired(DBusConnection dbus_connection) {
        this.dbus_connection = dbus_connection;
        if (menu_model == null) dbus_menu = null;
        if (menu_model != null && dbus_menu == null) dbus_menu = new DBusMenu(this, text_direction);
        if (dbus_menu != null) dbus_menu_registration_id = dbus_connection.register_object("/StatusNotifierMenu", dbus_menu);
        if (dbus_item == null) dbus_item = new DBusStatusNotifierItem(this, dbus_menu != null ? new ObjectPath("/StatusNotifierMenu") : null);
        dbus_item_registration_id = dbus_connection.register_object("/StatusNotifierItem", dbus_item);
        notify["title"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_title());
        notify["icon-name"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_icon());
        notify["menu"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_menu());
        notify["tool-tip"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_tool_tip());
        notify["status"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_status(((StatusNotifierItem)o).status));
        notify["menu-model"].connect((o, _) => ((StatusNotifierItem)o).dbus_menu.layout_updated(++((StatusNotifierItem)o).menu_model_revision, 0));
    }

    private void on_name_acquired (DBusConnection dbus_connection) {
        DBusStatusNotifierWatcher watcher = Bus.get_proxy_sync(BusType.SESSION, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher");

        watcher.host_registered.connect(() => {
            if (!(name in watcher.registered_items)) {
                watcher.register_item(name);
            }
        });

        watcher.register_item(name);
    }

    public void register() {
        if (registered) return;
        if (id == null) critical("StatusNotifierItem.id not set before registering");
        name_owner_id = Bus.own_name(BusType.SESSION, name, BusNameOwnerFlags.NONE, on_bus_aquired, on_name_acquired, () => warning("Could not acquire name: %s", name));
        registered = true;
    }

    public void unregister() {
        if (!registered) return;
        if (name_owner_id != 0) Bus.unown_name(name_owner_id);
        name_owner_id = 0;
        if (dbus_item_registration_id != 0 && dbus_connection != null) dbus_connection.unregister_object(dbus_item_registration_id);
        if (dbus_menu_registration_id != 0 && dbus_connection != null) dbus_connection.unregister_object(dbus_menu_registration_id);
        dbus_item_registration_id = 0;
        dbus_menu_registration_id = 0;
        dbus_connection = null;
        registered = false;
    }
}

}
