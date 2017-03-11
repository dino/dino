namespace Xmpp {
    public string? get_bare_jid(string jid) {
        return jid.split("/")[0];
    }

    public bool is_bare_jid(string jid) {
        return !jid.contains("/");
    }

    public string? get_resource_part(string jid) {
        return jid.split("/")[1];
    }

    public string random_uuid() {
        uint8[] rand = new uint8[16];
        char[] str = new char[37];
        UUID.generate_random(rand);
        UUID.unparse_upper(rand, str);
        return (string) str;
    }

    public class Tuple<A,B> : Object {
        public A a { get; private set; }
        public B b { get; private set; }

        public Tuple(A a, B b) {
            this.a = a;
            this.b = b;
        }

        public static Tuple<A,B> create<A,B>(A a, B b) {
            return new Tuple<A,B>(a,b);
        }
    }

    public class Triple<A,B,C> : Tuple<A,B> {
        public C c { get; private set; }

        public Triple(A a, B b, C c) {
            base(a, b);
            this.c = c;
        }

        public static new Triple<A,B,C> create<A,B,C>(A a, B b, C c) {
            return new Triple<A,B,C>(a, b, c);
        }
    }

    public class Quadruple<A,B,C,D> : Triple<A,B,C> {
        public D d { get; private set; }

        public Quadruple(A a, B b, C c, D d) {
            base (a, b, c);
            this.d = d;
        }

        public static new Quadruple<A,B,C,D> create<A,B,C,D>(A a, B b, C c, D d) {
            return new Quadruple<A,B,C,D>(a, b, c, d);
        }
    }
}