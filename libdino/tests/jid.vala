using Dino.Entities;

namespace Dino.Test {

class JidTest : Gee.TestCase {

    public JidTest() {
        base("Jid");
        add_test("parse", test_parse);
        add_test("components", test_components);
        add_test("with_res", test_with_res);
    }

    private void test_parse() {
        Jid jid = new Jid("user@example.com/res");
        fail_if(jid.localpart != "user");
        fail_if(jid.domainpart != "example.com");
        fail_if(jid.resourcepart != "res");
        fail_if(jid.to_string() != "user@example.com/res");
    }

    private void test_components() {
        Jid jid = new Jid.components("user", "example.com", "res");
        fail_if(jid.localpart != "user");
        fail_if(jid.domainpart != "example.com");
        fail_if(jid.resourcepart != "res");
        fail_if(jid.to_string() != "user@example.com/res");
    }

    private void test_with_res() {
        Jid jid = new Jid.with_resource("user@example.com", "res");
        fail_if(jid.localpart != "user");
        fail_if(jid.domainpart != "example.com");
        fail_if(jid.resourcepart != "res");
        fail_if(jid.to_string() != "user@example.com/res");
    }
}

}
