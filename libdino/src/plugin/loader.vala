namespace Dino.Plugins {

private extern const string SYSTEM_LIBDIR_NAME;
private extern const string SYSTEM_PLUGIN_DIR;

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
        if (Environment.get_variable("DINO_PLUGIN_DIR") != null) {
            search_paths += Environment.get_variable("DINO_PLUGIN_DIR");
        }
        search_paths += Path.build_filename(Environment.get_home_dir(), ".local", "lib", "dino", "plugins");
        string? exec_path = exec_str;
        if (exec_path != null) {
            if (!exec_path.contains(Path.DIR_SEPARATOR_S)) {
                exec_path = Environment.find_program_in_path(exec_str);
            }
            if (Path.get_dirname(exec_path).contains("dino") || Path.get_dirname(exec_path) == "." || Path.get_dirname(exec_path).contains("build")) {
                search_paths += Path.build_filename(Path.get_dirname(exec_path), "plugins");
            }
            if (Path.get_basename(Path.get_dirname(exec_path)) == "bin") {
                search_paths += Path.build_filename(Path.get_dirname(Path.get_dirname(exec_path)), SYSTEM_LIBDIR_NAME, "dino", "plugins");
            }
        }
        search_paths += SYSTEM_PLUGIN_DIR;
    }

    public void print_search_paths() {
        foreach (string prefix in search_paths) {
            print(@"$prefix\n");
        }
    }

    public RootInterface load(string name, Dino.Application app) throws Error {
        if (Module.supported () == false) {
            throw new Error (-1, 0, "Plugins are not supported");
        }

        Module module = null;
        string path = "";
        foreach (string prefix in search_paths) {
            path = Path.build_filename(prefix, name);
            module = Module.open (path, ModuleFlags.BIND_LAZY);
            if (module != null) break;
        }
        if (module == null) {
            throw new Error (-1, 1, "%s", Module.error ().replace(path, name));
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