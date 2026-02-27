namespace Dino.Plugins.TrayIcon {

/* To debug this

dbus-monitor \
  "type='signal',interface='com.canonical.dbusmenu'" \
  "type='method_call',interface='com.canonical.dbusmenu'" \
  "type='signal',interface='org.kde.StatusNotifierItem'" \
  "type='method_call',interface='org.kde.StatusNotifierItem'" \
  "type='method_return'"

You can clean it up a lot by watching it for a moment and reading
off the 'sender' and 'destination'; replace the last line with:
  "type='method_return',sender=:1.8,destination=:1.274" \
  "type='method_return',sender=:1.274,destination=:1.8"

and replace 1.8 and 1.274 with the numbers currently in use on your system.

*/

[DBus (name = "org.kde.StatusNotifierWatcher")]
private interface DBusStatusNotifierWatcher : Object {
    [DBus (name = "RegisterStatusNotifierItem")]
    public abstract async void register_item(string service) throws GLib.Error;

    [DBus (name = "RegisteredStatusNotifierItems")]
    public abstract string[] registered_items { owned get; }
    [DBus (name = "IsStatusNotifierHostRegistered")]
    public abstract bool is_host_registered { get; }
    [DBus (name = "ProtocolVersion")]
    public abstract int version { get; }

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
    public int[] event_group(DBusMenuEventStruct[] events) throws DBusError {
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

    private static void collect_all_ids(int32 parent_id, MenuModel model, Gee.ArrayList<int32> result) {
        int32[] children = get_children_ids(parent_id, model);
        foreach (int32 child_id in children) {
            result.add(child_id);
            collect_all_ids(child_id, model, result);
        }
    }

    public void all_items_properties_updated() {
        var all_ids = new Gee.ArrayList<int32>();
        collect_all_ids(0, item.menu_model, all_ids);

        Variant[] items = {};
        foreach (int32 id in all_ids) {
            var props = get_properties(id, item.menu_model);
            if (props == null || props.size == 0) continue;

            var dict = new VariantDict();
            foreach (var entry in props) {
                dict.insert_value(entry.key, entry.value);
            }

            var item_builder = new VariantBuilder(new VariantType("(ia{sv})"));
            item_builder.add("i", id);
            item_builder.add_value(dict.end());
            items += item_builder.end();
        }

        var updated = new Variant.array(new VariantType("(ia{sv})"), items);
        var removed = new Variant.array(new VariantType("(ias)"), {});

        items_properties_updated(updated, removed);
    }

    [DBus (name = "ItemsPropertiesUpdated")]
    public signal void items_properties_updated([DBus (signature = "a(ia{sv})")] Variant updated_properties, [DBus (signature = "a(ias)")] Variant removed_properties);
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

    public void notify_menu_updated() {
        if (dbus_menu != null) {
            // Sync the current state of the menu to the systray over DBus.
            //
            // - Can't detect what changes have happened since last call
            //   so always resyncs the full menu state. ItemsPropertiesUpdated
            //   is designed to send a diff but computing that is incredibly
            //   error-prone so we don't [^1].
            //
            // - Some (most?) DEs always resync the full menu on LayoutUpdated
            //   anyway; and menu updates happen rarely so it's not a big
            //   problem to add a few stray DBus messages.
            //
            // [^1]: Canonical Ltd designed ItemsPropertiesUpdated; they also,
            //       later, wrote the GNOME 3 systray extension and there they
            //       straight up igore the diff attached to ItemsPropertiesUpdated;
            //       they need to hear it but it always triggers a full resync [^2].
            // [^2]: But other DEs do pay attention to the details in
            //       ItemsPropertiesUpdated; however they all seem to be ones that
            //       treat LayoutUpdated as a trigger for a full resync, so it's
            //       redundant there.
            dbus_menu.layout_updated(++menu_model_revision, 0);
            dbus_menu.all_items_properties_updated();

            // Anoother strategy:
            // - in Electron every menu update has to be a full new menu
            //   (https://github.com/electron/electron/blob/master/docs/api/tray.md)
            //   and it (somewhere, unclear to us where) tracks a global counter
            //   of menu items so it can generate fresh IDs on every GetLayout,
            //   which forces the systray to follow up with GetGroupProperties.
        }
    }

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
        try {
            if (dbus_menu != null) dbus_menu_registration_id = dbus_connection.register_object("/StatusNotifierMenu", dbus_menu);
            if (dbus_item == null) dbus_item = new DBusStatusNotifierItem(this, dbus_menu != null ? new ObjectPath("/StatusNotifierMenu") : null);
            dbus_item_registration_id = dbus_connection.register_object("/StatusNotifierItem", dbus_item);
        } catch (IOError e) {
            warning("Failed to register D-Bus objects: %s", e.message);
            return;
        }
        notify["title"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_title());
        notify["icon-name"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_icon());
        notify["menu"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_menu());
        notify["tool-tip"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_tool_tip());
        notify["status"].connect((o, _) => ((StatusNotifierItem)o).dbus_item.on_new_status(((StatusNotifierItem)o).status));
        notify["menu-model"].connect((o, _) => ((StatusNotifierItem)o).dbus_menu.layout_updated(++((StatusNotifierItem)o).menu_model_revision, 0));
    }

    private void on_name_acquired(DBusConnection dbus_connection) {
        Bus.get_proxy.begin<DBusStatusNotifierWatcher>(BusType.SESSION, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", 0, null, (obj, res) => {
            try {
                DBusStatusNotifierWatcher watcher = Bus.get_proxy.end(res);

                watcher.host_registered.connect(() => {
                    if (!(name in watcher.registered_items)) {
                        watcher.register_item.begin(name, (obj, res) => {
                            try {
                                watcher.register_item.end(res);
                            } catch (Error e) {
                                warning("Failed to register with StatusNotifierWatcher: %s", e.message);
                            }
                        });
                    }
                });

                watcher.register_item.begin(name, (obj, res) => {
                    try {
                        watcher.register_item.end(res);
                    } catch (Error e) {
                        warning("Failed to register with StatusNotifierWatcher: %s", e.message);
                    }
                });
            } catch (Error e) {
                warning("Failed to get StatusNotifierWatcher proxy: %s", e.message);
            }
        });
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
