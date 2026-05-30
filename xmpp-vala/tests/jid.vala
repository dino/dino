namespace Xmpp.Test {

class JidTest : Gee.TestCase {
    public JidTest() {
        base("Jid");

        add_test("jid_valid_domain_only", () => { test_jid_valid("example.com"); });
        add_test("jid_valid_bare", () => { test_jid_valid("test@example.com"); });
        add_test("jid_valid_domain_with_resource", () => { test_jid_valid("example.com/test"); });
        add_test("jid_valid_full", () => { test_jid_valid("test@example.com/test"); });

        // These should not be valid in "strict-mode"
        add_test("jid_valid_emoji_only", () => { test_jid_valid("😅"); });
        add_test("jid_valid_emoji_local", () => { test_jid_valid("😅@example.com"); });
        add_test("jid_valid_emoji_resource", () => { test_jid_valid("test@example.com/😅"); });
        add_test("jid_valid_emoji_domain", () => { test_jid_valid("test@😅.com"); });

        add_test("jid_invalid_bidi_local", () => { test_jid_invalid("te‏st@example.com"); });
        add_test("jid_invalid_bidi_resource", () => { test_jid_invalid("test@example.com/te‏st"); });
        add_test("jid_invalid_bidi_domain", () => { test_jid_invalid("test@exa‏mple.com"); });
        add_test("jid_invalid_overlong_idn", () => { test_jid_invalid("test@ççççççççççççççççççççççççççççççççççççççççççççççççççççççççççççç.com"); });

        add_test("jid_equal_end_domain", () => { test_jids_equal("test@example.com", "test@example.com."); });
        add_test("jid_equal_case_domain", () => { test_jids_equal("test@example.com", "test@eXample.com"); });
        add_test("jid_equal_norm_domain", () => { test_jids_equal("test@garçon.com", "test@garçon.com"); });
        add_test("jid_equal_puny_domain", () => { test_jids_equal("test@garçon.com", "test@xn--garon-0ra.com"); });
        add_test("jid_equal_case_local", () => { test_jids_equal("test@example.com", "tEst@example.com"); });
        add_test("jid_equal_norm_local", () => { test_jids_equal("garçon@example.com", "garçon@example.com"); });
        add_test("jid_equal_norm_resource", () => { test_jids_equal("test@example.com/garçon", "test@example.com/garçon"); });

        add_test("jid_non_equal_case_resource", () => { test_jids_unequal("example.com/test", "example.com/tEst"); });

        add_test("jid_to_string_end_domain", () => { test_jid_to_string("test@example.com.", "test@example.com"); });
        add_test("jid_to_string_case_domain", () => { test_jid_to_string("test@eXample.com", "test@example.com"); });
        add_test("jid_to_string_norm_domain", () => { test_jid_to_string("test@garçon.com", "test@garçon.com"); });
        add_test("jid_to_string_puny_domain", () => { test_jid_to_string("test@xn--garon-0ra.com", "test@garçon.com"); });
        add_test("jid_to_string_case_local", () => { test_jid_to_string("tEst@example.com", "test@example.com"); });
        add_test("jid_to_string_norm_local", () => { test_jid_to_string("garçon@example.com", "garçon@example.com"); });
        add_test("jid_to_string_case_resource", () => { test_jid_to_string("example.com/tEst", "example.com/tEst"); });
        add_test("jid_to_string_norm_resource", () => { test_jid_to_string("test@example.com/garçon", "test@example.com/garçon"); });
    }

    private void test_jid_valid(string jid) {
        try {
            Jid.from_string(jid);
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }

    private void test_jid_invalid(string jid) {
        try {
            Jid.from_string(jid);
            fail_if_reached();
        } catch (Error e) {
//            try {
//                fail_if_not_eq_str(Jid.parse(jid).to_string(), jid);
//            } catch (Error e) {
//                fail_if_reached();
//            }
        }
    }

    private void test_jids_equal(string jid1, string jid2) {
        try {
            var t1 = Jid.from_string(jid1);
            var t2 = Jid.from_string(jid2);
            fail_if_not_eq_str(t1.to_string(), t2.to_string());
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }

    private void test_jid_to_string(string jid1, string jid2) {
        try {
            var t1 = Jid.from_string(jid1);
            fail_if_not_eq_str(t1.to_string(), jid2);
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }

    private void test_jids_unequal(string jid1, string jid2) {
        try {
            var t1 = Jid.from_string(jid1);
            var t2 = Jid.from_string(jid2);
            fail_if_eq_str(t1.to_string(), t2.to_string());
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }
}

}