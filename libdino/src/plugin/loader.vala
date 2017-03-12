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
    private delegate Type RegisterPluginFunction (Module module);

    private string[] search_paths = new string[0];
    private RootInterface[] plugins = new RootInterface[0];
    private Info[] infos = new Info[0];

    public Loader(string? exec_str = null) {
        search_paths += Application.get_storage_dir();
        if (exec_str != null) {
            string exec_path = exec_str;
            if (!exec_path.contains(Path.DIR_SEPARATOR_S)) {
                exec_path = Environment.find_program_in_path(exec_str);
            }
            if (exec_path[0:5] != "/usr") {
                search_paths += Path.get_dirname(exec_path);
            }
        }
        foreach (string dir in Environment.get_system_data_dirs()) {
            search_paths += Path.build_filename(dir, "dino");
        }
    }

    public RootInterface load(string name, Dino.Application app) throws Error {
        if (Module.supported () == false) {
            throw new Error (-1, 0, "Plugins are not supported");
        }

        Module module = null;
        string path = "";
        foreach (string prefix in search_paths) {
            path = Path.build_filename(prefix, "plugins", name);
            module = Module.open (path, ModuleFlags.BIND_LAZY);
            if (module != null) break;
        }
        if (module == null) {
            throw new Error (-1, 1, Module.error ().replace(path, name));
        }

        void* function;
        module.symbol ("register_plugin", out function);
        if (function == null) {
            throw new Error (-1, 2, "register_plugin () not found");
        }

        RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
        Type type = register_plugin (module);
        if (type.is_a (typeof (RootInterface)) == false) {
            throw new Error (-1, 3, "Unexpected type");
        }

        Info info = new Plugins.Info (type, (owned) module);
        infos += info;

        RootInterface plugin = (RootInterface) Object.new (type);
        plugins += plugin;
        plugin.registered (app);

        return plugin;
    }

    public void shutdown() {
        foreach (RootInterface p in plugins) {
            p.shutdown();
        }
    }
}

}