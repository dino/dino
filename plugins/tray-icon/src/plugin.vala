using Dino.Entities;

/*
   Tray Icon / Minimization / Daemonization for Dino

   To debug:

     G_MESSAGES_DEBUG="TrayIcon" ./build/main/dino

   (recall that you [can](https://github.com/dino/dino/wiki/Debugging) add other modules, space-separated, to debug at the same time)
 */

namespace Dino.Plugins.TrayIcon {

  public class Plugin : RootInterface, Object {

    public Dino.Application app;
    private DBusNotifications? dbus_notifications = null;
    private Gtk.Window? main_window = null;

    /* API */
    public /*async*/ bool minimizable() {
      // TODO: we should *wait* here until we're initialized
      //
      if (persistent_notification_active || tray_item != null)return true;
      return false;
    }

    /* Utilities */
    private static bool is_gnome_desktop() {
      // detect if running under GNOME (or Unity, which is Ubuntu's fork)
      string? desktop = Environment.get_variable("XDG_CURRENT_DESKTOP");
      if (desktop == null)return false;
      desktop = desktop.down();
      return desktop.contains("gnome") || desktop.contains("unity");
    }

    private async bool has_dbus_name(string name) {
      try {
        var connection = yield Bus.get(BusType.SESSION);

        Variant result = yield connection.call("org.freedesktop.DBus", // bus name
          "/org/freedesktop/DBus", // object path
          "org.freedesktop.DBus", // interface
          "NameHasOwner", // method
          new Variant ("(s)", name),
          new VariantType ("(b)"), // expected reply
          DBusCallFlags.NONE,
          -1,
          null);

        bool has_owner;
        result.get("(b)", out has_owner);

        return has_owner;
      } catch (Error e) {
        warning("Failed to query D-Bus: %s", e.message);
      }
      return false;
    }

    /* Shared state */
    private void setup_main_window(Gtk.Window window) {
      debug("main window added");
      // note that this is a signal handler, it doens't happen immediately!
      if (main_window == null) {
        main_window = window;
        debug("main window registered");

        if (minimizable()) {
          main_window.hide_on_close = true;
        }

        // When window visibility changes, the SNI tray needs to switch between saying Show/Hide
        main_window.notify["visible"].connect(() => {
          debug("notify[visible] fired: visible=%s", main_window.visible.to_string());
          update_notice(); // XXX this is a bit wasteful because it also runs the persistent_notification stuff
        });
      }
    }

    /* Case 1: Persistent Notification */

    private bool persistent_notification_active = false;
    private uint32 persistent_notification_id = 0;

    private async bool has_persistent_notifications() {
      // detect if we're in a desktop environment with persistent notifications
      // if so, we know we can use them instead of a system tray icon,
      // similar to how Android handles background apps.

      if (dbus_notifications == null) {
        return false;
      }

      // Query capabilities
      // see https://specifications.freedesktop.org/notification/latest-single/#id-1.10.3.2.5
      try {
        string[] caps;
        yield dbus_notifications.get_capabilities(out caps);

        foreach (string cap in caps) {
          if (cap == "persistence") {
            debug("Persistent notifications capability detected");
            return true;
          }
        }
      } catch (Error e) {
        warning("Could not query DBUS notificationn capabilities: %s", e.message);
      }

      debug("Persistent notifications capability NOT detected");
      return false;
    }

    private void setup_persistent_notification() {
      persistent_notification_active = true;

      // Connect to notification action
      dbus_notifications.action_invoked.connect((notification_id, action) => {
        debug(@"persistent notification $notification_id clicked");
        if (notification_id == persistent_notification_id && action == "default") {
          toggle_window();
        }
      });
    }

    private async void update_persistent_notification(string body) {
      if (dbus_notifications == null)return;
      if (!persistent_notification_active)return;

      string title = "Dino";

      HashTable<string, Variant> hints = new HashTable<string, Variant> (null, null);
      hints["desktop-entry"] = new Variant.string("im.dino.Dino");
      hints["category"] = new Variant.string("presence");
      hints["resident"] = new Variant.boolean(true); // Keep notification after click
      hints["urgency"] = new Variant.byte(0); // don't popup, just appear in tray
      hints["suppress-sound"] = new Variant.boolean(true);

      string[] actions = new string[] { "default", "Toggle Dino" };

      try {
        // replaces_id updatesi the existing notification
        persistent_notification_id = yield dbus_notifications.notify("Dino",
          persistent_notification_id, // Replace existing notification; on *init*, this is 0 which is ..special? I guess? Means "create a new one"?
          "im.dino.Dino",
          title,
          body,
          actions,
          hints,
          0 // No timeout
        );
      } catch (Error e) {
        warning("Persistent notification: Failed to send notification: %s", e.message);
      }
    }

    private void shutdown_persistent_notification() {
      if (dbus_notifications != null && persistent_notification_id != 0) {
        dbus_notifications.close_notification.begin(persistent_notification_id, (_, res) => { dbus_notifications.close_notification.end(res); });
      }
    }

    /* Case 2: StatusNotifierItem system tray */
    private StatusNotifierItem? tray_item;

    private async bool has_sni_tray() {
      // KDE invented StatusNotifierItem (SNI)-based system trays; and for
      // compatibility, other DEs *pretend to be KDE* if they have a tray.
      // For example, here's sway:
      // https://github.com/Alexays/Waybar/blob/e4e47cad5c9efec3462e0c239ea1015931864984/src/modules/sni/watcher.cpp#L9-L15
      var has_owner = yield has_dbus_name("org.kde.StatusNotifierWatcher");
      if (has_owner) {
        debug("SNI tray detected");
      } else {
        debug("SNI tray NOT detected");
      }
      return has_owner;
    }

    private void setup_sni_tray() {
      // setup SNI-based tray icon

      tray_item = new StatusNotifierItem() {
        id = "im.dino.Dino",
        category = "Communications",
        title = "Dino",
        status = "Active",
        icon_name = "im.dino.Dino",
        text_direction = Gtk.Widget.get_default_direction() == Gtk.TextDirection.RTL ? "rtl" : "ltr"
      };

      tray_item.activate.connect((_x, _y) => {
        debug("tray icon click toggling");
        toggle_window();
      });

      // Setup attached menu
      var toggle_action = new GLib.SimpleAction("tray-toggle", null);
      toggle_action.activate.connect(() => {
        debug("tray icon menu toggling");
        toggle_window();
      });
      ((GLib.Application) app).add_action(toggle_action);
      var menu = new GLib.Menu();
      tray_item.menu_model = menu;
      menu.append("Show", "app.tray-toggle");
      menu.append("Quit", "app.quit");

      // Hook it up to the OS
      tray_item.register();
    }

    private void update_sni_tray(string body) {
      if (tray_item != null) {
        string title = "Dino";
        tray_item.tool_tip = DBusStatusNotifierItemToolTip() {
          icon_name = "im.dino.Dino",
          icon = {},
          title = title,
          body = body
        };

        if (body != "No unread messages") { // XXX janky, we translate get_unread_count() to a bool to a string and back to a bool
          tray_item.status = "NeedsAttention";
        } else {
          tray_item.status = "Active";
        }

        bool is_visible = main_window != null && main_window.visible;
        debug("Tray icon: window visible=%s", is_visible.to_string());
        // Modify menu in-place: remove first item and re-add with correct label
        // XXX this is ignored under GNOME's https://extensions.gnome.org/extension/615/appindicator-support/ (a problem we sidestep by not using SNI on GNOME, but still, it would be good to fix)
        // TODO: before removing, maybe verify what the previous state was?
        var menu = tray_item.menu_model as GLib.Menu;
        menu.remove(0);
        if (is_visible) {
          menu.prepend("Hide", "app.tray-toggle");
        } else {
          menu.prepend("Show", "app.tray-toggle");
        }
        tray_item.notify_menu_updated();
      }
    }

    private void shutdown_sni_tray() {
      if (tray_item != null) {
        tray_item.unregister();
      }
    }

    private async void _registered(Dino.Application app) {
      this.app = app;

      // Sniff the number of unread messages
      app.stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect((_x, _y) => {
        // on new message
        update_notice();
      });
      app.stream_interactor.get_module(ChatInteraction.IDENTITY).focused_in.connect((_) => {
        // on user clicking to a conversation (and hence 'reading' its unread messages).
        // The update is deferred the Idle loop to ensure the decrement has actually happened.
        GLib.Idle.add(() => {
          update_notice();
          return GLib.Source.REMOVE;
        });
      });

      if(yield has_dbus_name("org.freedesktop.Notifications")) {
        dbus_notifications = yield get_notifications_dbus();
      }

      // Decide if and how we're going to make a tray icon
      // 1. Prefer GNOME's notification area, since Dino is a Vala app and hence most at home in GNOME
      // - KDE also supports this, but it annoyingly doesn't respect the priority hint and always pops the notification upo.
      // If there were a way to make the notification persistent but only appear for a moment that might be an okay compromise
      // 2. Fall back to KDE'StatusNotifierItem system, which is widely supported
      // 3. Disable tray icons -- and therefore settings.start_minimized -- entirely.
      if (is_gnome_desktop() && (yield has_persistent_notifications())) {
        // Case 1
        setup_persistent_notification();
        // note that the notification isn't actually sent until update_notice()

        // Keep app when window closed
        ((GLib.Application) app).hold();
        debug("Minimizing Dino to Freedesktop persistent Notifications.");
      } else if (yield has_sni_tray()) {
        // Case 2
        setup_sni_tray();

        // Keep app when window closed
        ((GLib.Application) app).hold();
        debug("Minimizing dino to StatusNotifier tray icon.");
      } else {
        // Case 3
        debug("Minimizing disabled because no tray detected.");
      }

      // this.main_window = app.window, indirectly
      // The window might already exist by the time we run OR it might not so we have to catch both cases
      // also: it's important this happens AFTER init'ing the tray
      // because that tells us if it's okay to hide_on_close.
      unowned var windows = ((Gtk.Application) app).get_windows();
      if (windows.length() > 0 && main_window == null) {
        setup_main_window(windows.data);
      } else {
        ((Gtk.Application) app).window_added.connect((window) => {
          setup_main_window(window);
        });
      }

      // Initialize notification/tray content
      update_notice();
    }

    public void registered(Dino.Application app) {
      // we have a bunch of async code we're forced to call
      // so just jump into it immediately and do everything async
      //  (this has to be called in the idle loop because the event loop _is not running yet_ during plugin load
      // so if we try to immediately jump we risk deadlocking.
      Idle.add(() => {
        _registered.begin(app, (_, res) => { _registered.end(res); });
        return GLib.Source.REMOVE;
      });
    }

    private void toggle_window() {
      var has_window = main_window != null;
      debug(@"toggle_window(): has_window = $has_window");
      if (this.main_window == null) {
        ((GLib.Application) app).activate();
        return;
      }

      debug("toggle_window called, current visible=%s", main_window.visible.to_string());
      if (main_window.visible) {
        main_window.set_visible(false);
      } else {
        main_window.present();
      }
    }

    private int get_unread_count() {
      int total = 0;
      var conversation_manager = app.stream_interactor.get_module(ConversationManager.IDENTITY);
      var chat_interaction = app.stream_interactor.get_module(ChatInteraction.IDENTITY);
      foreach (Conversation conversation in conversation_manager.get_active_conversations()) {
        total += chat_interaction.get_num_unread(conversation);
      }
      return total;
    }

    private void update_notice() {
      // Update the summary text displayed on the notification/tray icon
      string body;
      int unread = get_unread_count();
      if (unread == 0) {
        body = "No unread messages";
      } else if (unread == 1) {
        body = "1 unread message";
      } else {
        body = @"$unread unread messages";
      }

      update_persistent_notification.begin(body, (_, res) => { update_persistent_notification.end(res); });
      update_sni_tray(body);
    }

    public void shutdown() {
      shutdown_persistent_notification();
      shutdown_sni_tray();

      ((GLib.Application) app).release(); // XXX is this safe to call outside the if?regardless
    }
  }
}
