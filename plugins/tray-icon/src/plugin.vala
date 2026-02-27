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
    private Gtk.Window? main_window = null;
    private StatusNotifierItem? tray_item;
    // state caching for safety and avoidance of redundancy
    private bool app_held = false;
    private int last_unread = -1;
    private bool last_visible = false;


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
        debug("toggle_window: main_window not yet defined");
        ((GLib.Application) app).activate();
        return;
      }

      if (main_window.visible) {
        debug("toggle_window: hiding");
        main_window.set_visible(false);
      } else {
        debug("toggle_window: showing");
        // using present() also foregrounds the window, in most environments
        main_window.present();
      }
    }

    /* SNI */

    private async bool has_tray() {
      // KDE invented StatusNotifierItem (SNI)-based system trays; and for
      // compatibility, other DEs *pretend to be KDE* if they have a tray.
      // For example, here's sway:
      // https://github.com/Alexays/Waybar/blob/e4e47cad5c9efec3462e0c239ea1015931864984/src/modules/sni/watcher.cpp#L9-L15
      var has_sni = yield dbus_service_available("org.kde.StatusNotifierWatcher");
      if (has_sni) {
        debug("StatusNotifierItem system tray detected");
      } else {
        debug("StatusNotifierItem system tray NOT detected");
      }
      return has_sni;
    }

    private void setup_tray() {

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
      last_visible = main_window != null && main_window.visible;
      menu.append(last_visible ? "Hide" : "Show", "app.tray-toggle");
      menu.append("Quit", "app.quit");

      // Hook it up to the OS
      tray_item.register();
    }


    private void update_tray() {
      if (tray_item == null)return;

      bool visible = main_window != null && main_window.visible;
      int unread = get_unread_count();
      debug("update_tray: window visible = %s, unread = %d", visible.to_string(), unread);

      if(unread != last_unread) {
        if (unread == 0) {
          tray_item.status = "Active";
        } else {
          tray_item.status = "NeedsAttention";
        }

        // write a status message to the tray icon (usually shown on hover)
        string body;
        if (unread == 0) {
          body = "No unread messages";
        } else if (unread == 1) {
          body = "1 unread message";
        } else {
          body = @"$unread unread messages";
        }

        debug("setting tray message: %s", body); // beware: is this a privacy leak?
        tray_item.tool_tip = DBusStatusNotifierItemToolTip() {
          icon_name = "im.dino.Dino",
          icon = {},
          title = "Dino",
          body = body
        };

        last_unread = unread;
      }

      if(visible != last_visible) {
        // Toggle the label on the menu item
        debug("toggling menu item to %s", visible ? "Hide" : "Show");

        var menu = tray_item.menu_model as GLib.Menu;
        menu.remove(0);
        menu.prepend(visible ? "Hide" : "Show", "app.tray-toggle");

        tray_item.notify_menu_updated();

        last_visible = visible;
      }
    }

    private void shutdown_tray() {
      if (tray_item != null) {
        tray_item.unregister();
      }
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

      // Decide if we're can make a tray icon
      if (yield has_tray()) {
        setup_tray();

        // Keep app when window closed
        ((GLib.Application) app).hold();
        app_held = true;
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
      // It's important this happens last because it assumes setup_tray has run.
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
      shutdown_tray();

      if(app_held) {
        ((GLib.Application) app).release(); // XXX is this safe to call outside the if?regardless
      }
    }

  }
}
