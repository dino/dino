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

    private RootInterface[] plugins = new RootInterface[0];
    private Info[] infos = new Info[0];

    public RootInterface load(string name, Dino.Application app) throws Error {
        if (Module.supported () == false) {
            throw new Error (-1, 0, "Plugins are not supported");
        }

        Module module = Module.open ("plugins/" + name, ModuleFlags.BIND_LAZY);
        if (module == null) {
            throw new Error (-1, 1, Module.error ());
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