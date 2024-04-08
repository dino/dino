using Dino.Entities;
using Xmpp;

namespace Dino.Test {

class JidTest : Gee.TestCase {

    public JidTest() {
        base("Jid");
        add_test("parse", test_parse);
        add_test("components", test_components);
        add_test("with_res", test_with_res);
    }

    private void test_parse() {
        try {
            Jid jid = new Jid("user@example.com/res");
            fail_if(jid.localpart != "user");
            fail_if(jid.domainpart != "example.com");
            fail_if(jid.resourcepart != "res");
            fail_if(jid.to_string() != "user@example.com/res");
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }

    private void test_components() {
        try {
            Jid jid = new Jid.components("user", "example.com", "res");
            fail_if(jid.localpart != "user");
            fail_if(jid.domainpart != "example.com");
            fail_if(jid.resourcepart != "res");
            fail_if(jid.to_string() != "user@example.com/res");
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }

    private void test_with_res() {
        try {
            Jid jid = new Jid("user@example.com").with_resource("res");
            fail_if(jid.localpart != "user");
            fail_if(jid.domainpart != "example.com");
            fail_if(jid.resourcepart != "res");
            fail_if(jid.to_string() != "user@example.com/res");
        } catch (Error e) {
            fail_if_reached(@"Throws $(e.message)");
        }
    }
}

}
