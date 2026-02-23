using Gee;

namespace Dino.Plugins {

private class Info : Object {
    public Module module;
    public Type gtype;

    public Info(Type type, owned Module module) {
        this.module = (owned) module;
        this.gtype = type;
    }
}

public class Loader : Object {
    [CCode (has_target = false)]
    private delegate Type RegisterPluginFunction(Module module);

    private Application app;
    private string[] search_paths;
    private RootInterface[] plugins = new RootInterface[0];
    private Info[] infos = new Info[0];

    public Loader(Application app) {
        this.app = app;
        this.search_paths = app.search_path_generator.get_plugin_paths();
    }

    public void load_all() throws Error {
        if (Module.supported() == false) {
            throw new Error(-1, 0, "Plugins are not supported");
        }

        HashSet<string> plugin_names = new HashSet<string>();

        foreach (string path in search_paths) {
            try {
                Dir dir = Dir.open(path, 0);
                string? file = null;
                while ((file = dir.read_name()) != null) {
                    if (file.has_suffix(Module.SUFFIX)) plugin_names.add(file);
                }
            } catch (Error e) {
                // Ignore this folder
            }
        }

        foreach (string plugin in plugin_names) {
            load(plugin);
        }
    }

    public RootInterface load(string name) throws Error {
        if (Module.supported() == false) {
            throw new Error(-1, 0, "Plugins are not supported");
        }

        Module module = null;
        string path = "";
        foreach (string prefix in search_paths) {
            path = Path.build_filename(prefix, name);
            module = Module.open(path, ModuleFlags.BIND_LAZY);
            if (module != null) break;
        }
        if (module == null) {
            throw new Error(-1, 1, "%s", Module.error().replace(path, name));
        }

        void* function;
        module.symbol("register_plugin", out function);
        if (function == null) {
            throw new Error(-1, 2, "register_plugin () not found");
        }

        RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
        Type type = register_plugin(module);
        if (type.is_a(typeof(RootInterface)) == false) {
            throw new Error(-1, 3, "Unexpected type");
        }

        Info info = new Plugins.Info(type, (owned) module);
        infos += info;

        RootInterface plugin = (RootInterface) Object.new (type);
        plugins += plugin;
        plugin.registered(app);

        return plugin;
    }

    public void shutdown() {
        foreach (RootInterface p in plugins) {
            p.shutdown();
        }
    }
}

}
