namespace Xmpp {

    public class FlagIdentity<T> : Object {
        public string ns { get; private set; }
        public string id { get; private set; }

        public FlagIdentity(string ns, string id) {
            this.ns = ns;
            this.id = id;
        }

        public T? cast(XmppStreamFlag flag) {
            return flag.get_type().is_a(typeof(T)) ? (T?) flag : null;
        }

        public bool matches(XmppStreamFlag module) {
            return module.get_ns() == ns && module.get_id() == id;
        }
    }

    public abstract class XmppStreamFlag : Object {
        public abstract string get_ns();

        public abstract string get_id();
    }

    public class ModuleIdentity<T> : Object {
        public string ns { get; private set; }
        public string id { get; private set; }

        public ModuleIdentity(string ns, string id) {
            this.ns = ns;
            this.id = id;
        }

        public T? cast(XmppStreamModule module) {
            return module.get_type().is_a(typeof(T)) ? (T?) module : null;
        }

        public bool matches(XmppStreamModule module) {
            return module.get_ns() == ns && module.get_id() == id;
        }
    }

    public abstract class XmppStreamModule : Object {
        public abstract void attach(XmppStream stream);

        public abstract void detach(XmppStream stream);

        public abstract string get_ns();

        public abstract string get_id();
    }

    public abstract class XmppStreamNegotiationModule : XmppStreamModule {
        public abstract bool mandatory_outstanding(XmppStream stream);

        public abstract bool negotiation_active(XmppStream stream);
    }

}