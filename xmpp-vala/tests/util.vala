using Xmpp.Util;

namespace Xmpp.Test {

class UtilTest : Gee.TestCase {
    public UtilTest() {
        base("util");

        add_hex_test(0x0, "");
        add_hex_test(0x123abc, "123abc");
        add_hex_test(0x0, "0x123abc");
        add_hex_test(0xa, "A quick brown fox jumps over the lazy dog.");
        add_hex_test(0xfeed, "   FEED ME   ");
    }

    private void add_hex_test(int expected, string str) {
        string test_name = @"from_hex(\"$(str)\")";
        add_test(test_name, () => {
            fail_if_not_eq_int(expected, (int)from_hex(str));
        });
    }
}

}
