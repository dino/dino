using Dino.Entities;

/*
   Tray Icon / Minimization / Daemonization for Dino

   To debug:

     G_MESSAGES_DEBUG="TrayIcon" ./build/main/dino

   (recall that you [can](https://github.com/dino/dino/wiki/Debugging) add other modules, space-separated, to debug at the same time)
  p


 */

namespace Dino.Plugins.TrayIcon {

  public class Plugin : RootInterface, Object {

    public Dino.Application app;
    private Gtk.Window? main_window = null;
    private StatusNotifierItem? tray_item;
    // state caching for safety and avoidance of redundancy
    private bool tray_active = false;
    private bool hide_desired = false; // what state the user wants; only matters if the tray restarts under us.
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

      if (main_window.visible && main_window.hide_on_close) {
        debug("toggle_window: hiding");
        main_window.set_visible(false);
        hide_desired = true;
      } else {
        debug("toggle_window: showing");
        // using present() also foregrounds the window, in most environments
        main_window.present();
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
      tray_item.activate.connect((_x, _y) => {
        toggle_window();
      });

      // Setup attached menu
      var menu = new GLib.Menu();
      tray_item.menu_model = menu;
      // a click on the 'Show/Hide' menu item
      var toggle_action = new GLib.SimpleAction("tray-toggle", null);
      toggle_action.activate.connect(() => {
        toggle_window();
      });
      ((GLib.Application) app).add_action(toggle_action);
      last_visible = main_window != null && main_window.visible;
      menu.append(last_visible ? "Hide" : "Show", "app.tray-toggle");
      menu.append("Quit", "app.quit");

      // Hook it up to the OS
      tray_item.exists.connect(() => {
        // Tray exists.
        debug("StatusNotifierItem system tray detected");
        if (!tray_active) {
          ((GLib.Application) app).hold();
          tray_active = true;
        }
        if (main_window != null) {
          main_window.hide_on_close = true;
          if(hide_desired) {
            main_window.set_visible(false);
          }
        }
        update_tray();
      });

      tray_item.absent.connect(() => {
        // Tray crash/restart, or just not there
        if (tray_active) {
          ((GLib.Application) app).release();
          tray_active = false;
          debug("StatusNotifierItem system tray lost");
        }

        // ensure that the window doesn't get lost if we lose the tray
        if (main_window != null) {
          main_window.hide_on_close = false;
          if(!main_window.visible) {
            main_window.set_visible(true);
          }
        }
      });

      tray_item.register();
    }


    private void update_tray() {
      if (tray_item == null)return;

      bool visible = main_window != null && main_window.visible;
      int unread = get_unread_count();
      // debug("update_tray: window visible = %s, unread = %d", visible.to_string(), unread);

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

        debug("setting tray message: '%s'", body); // beware: is this a privacy leak?
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
        debug("toggling menu item to '%s'", visible ? "Hide" : "Show");

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
        tray_item = null;
        if(tray_active) {
          ((GLib.Application) app).release();
          // TODO can this be merged with the tray_item.absent handler?
          tray_active = false;
        }
      }
    }

    /* Plugin interface (i.e. Hooking into the rest of the app) */

    private void setup_main_window(Gtk.Window window) {
      // note that this is a signal handler, it doens't happen immediately!
      if (main_window == null) {
        main_window = window;
        debug("tray plugin connected to main_window");

        // Do we have somewhere to minimize to?
        if (tray_active) {
          main_window.hide_on_close = true;
        }

        // When window visibility changes, the SNI tray needs to switch between saying Show/Hide
        main_window.notify["visible"].connect(update_tray);

        if (!main_window.hide_on_close) {
          main_window.present();
        }
      }
    }

    public void registered(Dino.Application app) {
      this.app = app;

      setup_tray();

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
    }

    public void shutdown() {
      shutdown_tray();
    }

  }
}
