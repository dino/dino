using Dino.Entities;

/*
   Tray Icon

   To debug:

     G_MESSAGES_DEBUG="dino" ./build/main/dino

  Recall that you can [^1] filter for multiple modules by space-separating them.

  [^1]: https://github.com/dino/dino/wiki/Debugging
 */

namespace Dino.Ui {

  public class FreedesktopTrayIcon : Object {

    public Dino.Ui.Application app;
    private StatusNotifierItem? tray_item;
    // state caching for safety and avoidance of redundancy
    private bool tray_active = false;
    private bool hide_desired = false; // what state the user wants; only matters if the tray restarts under us.
    public bool attention { get; private set; default = false; } // as a public property so it can be notify["attention"]'d

    /* Utilities */

    private void toggle_window() {
      if (this.app.window == null) {
        debug("toggle_window: app.window not yet defined");
        app.activate();
        return;
      }

      if (app.window.visible && app.window.hide_on_close) {
        debug("toggle_window: hiding");
        app.window.set_visible(false);
        hide_desired = true;
      } else {
        debug("toggle_window: showing");
        // using present() also foregrounds the window, in most environments
        app.window.present();
        hide_desired = false;
      }
    }

    /* SNI */

    private void setup_tray() {

      tray_item = new StatusNotifierItem() {
        id = "im.dino.Dino",
        category = "Communications",
        title = "Dino",
        status = "Active",
        icon_name = "im.dino.Dino",
        attention_icon_name = "im.dino.Dino-attention",
        text_direction = Gtk.Widget.get_default_direction() == Gtk.TextDirection.RTL ? "rtl" : "ltr"
      };

      // a click on the icon
      tray_item.activate.connect(() => {
        if(attention) {
          // hiding tricks most window managers
          // into focusing the presented window
          // but also generally loses the workspace it was on
          app.window.hide();
          app.window.present();
          hide_desired = false;
        } else {
          toggle_window();
        }
      });

      // Setup attached menu
      var menu = new GLib.Menu();
      tray_item.menu_model = menu;
      // a click on the 'Show/Hide' menu item
      var toggle_action = new GLib.SimpleAction("tray-toggle", null);
      toggle_action.activate.connect(() => {
        toggle_window();
      });
      app.add_action(toggle_action);
      bool visible = app.window != null && app.window.visible;
      menu.append(visible ? "Hide" : "Show", "app.tray-toggle");
      menu.append("Quit", "app.quit");

      // Hook it up to the OS
      tray_item.exists.connect(() => {
        // Tray exists.
        debug("StatusNotifierItem system tray detected");
        if (!tray_active) {
          app.hold();
          tray_active = true;
        }
        if (app.window != null) {
          app.window.hide_on_close = true;
          if(hide_desired) {
            app.window.set_visible(false);
          }
        }
      });

      tray_item.absent.connect(() => {
        // Tray crash/restart, or just not there
        if (tray_active) {
          app.release();
          tray_active = false;
          debug("StatusNotifierItem system tray lost");
        }

        // ensure that the window doesn't get lost if we lose the tray
        if (app.window != null) {
          app.window.hide_on_close = false;
          if(!app.window.visible) {
            app.window.set_visible(true);
          }
        }
      });

      if (tray_active) {
        assert_not_reached(); // Tray activated before it was done being configured.
        // window.hide_on_close = true;
      }

      // XXX: should these handlers have their handler_ids saved and be properly disconnect()ed in shutdown_tray() ?

      // Sync the attention icon with notifications, and clear it as soon as dino is focused.
      // This is not great UX; it would be more conventional to sync with
      // unread messages, but Dino is lacking infrastructure to make that
      // efficient. This will be improved: https://github.com/dino/dino/pull/1828#issuecomment-4010944395
      app.stream_interactor.get_module(NotificationEvents.IDENTITY).notify_content_item.connect(() => {
        attention = true;
      });

      app.stream_interactor.get_module(ChatInteraction.IDENTITY).focused_in.connect(() => {
        attention = false;
      });

      notify["attention"].connect(update_attention);
      app.window.notify["visible"].connect(update_visible);

      // initialize tray icon
      update_attention();
      update_visible();

      tray_item.register();

      app.shutdown.connect(shutdown_tray);
    }

    // set the tray's tooltip/icon state
    private void update_attention() {
      assert(app.window != null);
      assert(tray_item != null);

      string tooltip;
      if (!attention) {
        tray_item.status = "Active";
        tray_item.icon_name = "im.dino.Dino";

        tooltip = "";
      } else {
        tray_item.status = "NeedsAttention";
        // snixembed and waybar ignore attention_icon_name, so set primary icon too
        tray_item.icon_name = "im.dino.Dino-attention";

        tooltip = "Messages waiting";
      }

      // write a status message to the tray icon (usually shown on hover)
      debug("setting tray message: '%s'", tooltip); // beware: is this log a privacy leak?
      tray_item.tool_tip = DBusStatusNotifierItemToolTip() {
        icon_name = "im.dino.Dino",
        icon = {},
        title = "Dino",
        body = tooltip
      };
    }

    // set the tray's menu options
    private void update_visible() {
      assert(app.window != null);
      assert(tray_item != null);

      // Toggle the label on the menu item
      debug("toggling menu item to '%s'", app.window.visible ? "Hide" : "Show");

      var menu = tray_item.menu_model as GLib.Menu;
      menu.remove(0);
      menu.prepend(app.window.visible ? "Hide" : "Show", "app.tray-toggle");

      tray_item.notify_menu_updated();
    }

    private void shutdown_tray() {
      if (tray_item != null) {
        tray_item.unregister();
        tray_item = null;
        if(tray_active) {
          app.release();
          // TODO can this be merged with the tray_item.absent handler?
          tray_active = false;
        }
      }
    }

    public FreedesktopTrayIcon(Dino.Ui.Application app) {
      this.app = app;

      ulong window_handler = 0;
      window_handler = app.window_added.connect((window) => {
        if (!(window is Dino.Ui.MainWindow))return;

        Idle.add(() => {
          // window_added fires too early; delaying until the idle loop
          // allows time for app.window = window;
          setup_tray();
          return GLib.Source.REMOVE;
        });

        // ensure this handler only happens once
        app.disconnect(window_handler);
      });

    }

  }
}
