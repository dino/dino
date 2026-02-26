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
    private StatusNotifierItem? tray_item;

    /* Utilities */

    private int get_unread_count() {
      int total = 0;
      var conversation_manager = app.stream_interactor.get_module(ConversationManager.IDENTITY);
      var chat_interaction = app.stream_interactor.get_module(ChatInteraction.IDENTITY);
      foreach (Conversation conversation in conversation_manager.get_active_conversations()) {
        total += chat_interaction.get_num_unread(conversation);
      }
      return total;
    }

    private void toggle_window() {
      if (this.main_window == null) {
        debug("toggle_window(): main_window not yet defined");
        ((GLib.Application) app).activate();
        return;
      }

      debug("toggle_window(): main_window currently visible = %s", main_window.visible.to_string());
      if (main_window.visible) {
        main_window.set_visible(false);
      } else {
        // using present() also foregrounds the window, in most environments
        main_window.present();
      }
    }

    /* SNI */

    private async bool has_sni_tray() {
      // KDE invented StatusNotifierItem (SNI)-based system trays; and for
      // compatibility, other DEs *pretend to be KDE* if they have a tray.
      // For example, here's sway:
      // https://github.com/Alexays/Waybar/blob/e4e47cad5c9efec3462e0c239ea1015931864984/src/modules/sni/watcher.cpp#L9-L15
      var has_sni = yield dbus_service_available("org.kde.StatusNotifierWatcher");
      if (has_sni) {
        debug("SNI tray detected");
      } else {
        debug("SNI tray NOT detected");
      }
      return has_sni;
    }

    private void setup_sni_tray() {

      tray_item = new StatusNotifierItem() {
        id = "im.dino.Dino",
        category = "Communications",
        title = "Dino",
        status = "Active",
        icon_name = "im.dino.Dino",
        text_direction = Gtk.Widget.get_default_direction() == Gtk.TextDirection.RTL ? "rtl" : "ltr"
      };

      // a click on the icon
      tray_item.activate.connect((_x, _y) => {
        debug("tray icon click toggling");
        toggle_window();
      });

      // Setup attached menu
      var menu = new GLib.Menu();
      tray_item.menu_model = menu;
      // a click on the 'Show/Hide' menu item
      var toggle_action = new GLib.SimpleAction("tray-toggle", null);
      toggle_action.activate.connect(() => {
        debug("tray icon menu toggling");
        toggle_window();
      });
      ((GLib.Application) app).add_action(toggle_action);
      menu.append("Show", "app.tray-toggle");
      menu.append("Quit", "app.quit");

      // Hook it up to the OS
      tray_item.register();
    }

    private void update_sni_tray(string body) {
      // write a status message to the tray icon (usually shown on hover)
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

    /* Main */

    private void update_tray() {
      debug("update_tray(): visible=%s", main_window.visible.to_string());

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

      update_sni_tray(body);
    }

    /* Plugin interface (i.e. Hooking into the rest of the app) */

    private void setup_main_window(Gtk.Window window) {
      // note that this is a signal handler, it doens't happen immediately!
      if (main_window == null) {
        main_window = window;
        debug("Connected to main_window");

        // Do we have somewhere to minimize to?
        if (tray_item != null) {
          main_window.hide_on_close = true;
        }

        // When window visibility changes, the SNI tray needs to switch between saying Show/Hide
        main_window.notify["visible"].connect(update_tray);

        if (!main_window.hide_on_close) {
          // override settings.minimized
          //
          // it's rare but possible, say by switching DEs while minimized,
          // to end up without the window showing.
          main_window.present();
        }
      }
    }

    private async void _registered(Dino.Application app) {
      this.app = app;

      if(yield dbus_service_available("org.freedesktop.Notifications")) {
        dbus_notifications = yield get_notifications_dbus();
      }

      // Decide if we're can make a tray icon
      if (yield has_sni_tray()) {
        setup_sni_tray();

        // Keep app when window closed
        ((GLib.Application) app).hold();
        debug("Backgrounding to StatusNotifier tray icon.");
      } else {
        debug("Backgrounding disabled because no tray detected.");
        // ensure app is shown in case some other part of the code tried to hide it
        ((GLib.Application) app).activate();
      }

      app.stream_interactor.get_module(ContentItemStore.IDENTITY).new_item.connect((_x, _y) => {
        // on new message
        update_tray();
      });
      app.stream_interactor.get_module(ChatInteraction.IDENTITY).focused_in.connect((_) => {
        // on user clicking to a conversation (and hence 'reading' its unread messages).
        // The update is deferred the Idle loop to ensure the decrement has actually happened.
        GLib.Idle.add(() => {
          update_tray();
          return GLib.Source.REMOVE;
        });
      });

      // this.main_window = app.window, and configure it.
      // It's important this happens last because it assumes setup_sni_tray has run.
      //
      // Notice the window might already exist OR we might need to wait for it async
      // depending on the order dino chose to initialize.
      unowned var windows = ((Gtk.Application) app).get_windows();
      if (windows.length() > 0 && main_window == null) {
        setup_main_window(windows.data);
      } else {
        ((Gtk.Application) app).window_added.connect((window) => {
          setup_main_window(window);
        });
      }

      // Initialize tray content
      update_tray();
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

    public void shutdown() {
      shutdown_sni_tray();

      ((GLib.Application) app).release(); // XXX is this safe to call outside the if?regardless
    }

  }
}
