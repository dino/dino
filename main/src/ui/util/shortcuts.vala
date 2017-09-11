using Gee;
using Gtk;

using Dino.Ui;

public class Dino.Ui.Util.Shortcuts {
    private Dino.Ui.Application application;
    private HashMap<string, ArrayList<string>> action_shortcuts_map;

    private static Shortcuts _singleton;
    public static Shortcuts singleton {
        get {
            if (_singleton == null)
                _singleton = new Shortcuts();
            return _singleton;
        }
    }

    private Shortcuts() {
    }

    public void initialize(Dino.Ui.Application application, ShortcutsWindow shortcuts_window) {
        this.application = application;

        action_shortcuts_map = new HashMap<string, ArrayList<string>>();
        foreach (Widget section in shortcuts_window.get_children()) {
            foreach (Widget group in ((ShortcutsSection) section).get_children()) {
                foreach (Widget shortcut in ((ShortcutsGroup) group).get_children()) {
                    ShortcutsShortcut sc = (ShortcutsShortcut) shortcut;
                    ArrayList<string> accelerators = action_shortcuts_map.get(sc.action_name);
                    if (accelerators != null)
                        accelerators.add(sc.accelerator);
                    else
                        action_shortcuts_map.set(sc.action_name, new ArrayList<string>.wrap({ sc.accelerator }));
                }
            }
        }
    }

    public SimpleAction enable_action(string action_name) {
        SimpleAction action = new SimpleAction(action_name, null);
        // Passing delegates to signal.connect() doesn't work for now (2017-09-10):
        // https://bugzilla.gnome.org/show_bug.cgi?id=787521
        // The caller of enable_action will have to do this:
        //action.activate.connect(method);
        application.add_action(action);
        application.set_accels_for_action("app." + action_name, action_shortcuts_map.get("app." + action_name).to_array());
        return action;
    }
}

