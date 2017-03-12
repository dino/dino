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
        uint32 b1 = Random.next_int();
        uint16 b2 = (uint16)Random.next_int();
        uint16 b3 = (uint16)(Random.next_int() | 0x4000u) & ~0xb000u;
        uint16 b4 = (uint16)(Random.next_int() | 0x8000u) & ~0x4000u;
        uint16 b5_1 = (uint16)Random.next_int();
        uint32 b5_2 = Random.next_int();
        return "%08x-%04x-%04x-%04x-%04x%08x".printf(b1, b2, b3, b4, b5_1, b5_2);
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