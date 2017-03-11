namespace Dino.Plugins {

public errordomain Error {
	NOT_SUPPORTED,
	UNEXPECTED_TYPE,
	NO_REGISTRATION_FUNCTION,
	FAILED
}

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
            throw new Error.NOT_SUPPORTED ("Plugins are not supported");
        }

        Module module = Module.open ("plugins/" + name, ModuleFlags.BIND_LAZY);
        if (module == null) {
            throw new Error.FAILED (Module.error ());
        }

        void* function;
        module.symbol ("register_plugin", out function);
        if (function == null) {
            throw new Error.NO_REGISTRATION_FUNCTION ("register_plugin () not found");
        }

        RegisterPluginFunction register_plugin = (RegisterPluginFunction) function;
        Type type = register_plugin (module);
        if (type.is_a (typeof (RootInterface)) == false) {
            throw new Error.UNEXPECTED_TYPE ("Unexpected type");
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