namespace Xmpp.Test {

int main(string[] args) {
    GLib.Test.init(ref args);
    GLib.Test.set_nonfatal_assertions();
    TestSuite.get_root().add_suite(new Xmpp.Test.StanzaTest().get_suite());
    return GLib.Test.run();
}

bool fail_if(bool exp, string? reason = null) {
    if (exp) {
        if (reason != null) GLib.Test.message(reason);
        GLib.Test.fail();
        return true;
    }
    return false;
}

void fail_if_reached(string? reason = null) {
    fail_if(true, reason);
}

delegate void ErrorFunc() throws Error;

void fail_if_not_error_code(ErrorFunc func, int expectedCode, string? reason = null) {
    try {
        func();
        fail_if_reached(@"$(reason + ": " ?? "")no error thrown");
    } catch (Error e) {
        fail_if_not_eq_int(e.code, expectedCode, @"$(reason + ": " ?? "")caught unexpected error");
    }
}

bool fail_if_not(bool exp, string? reason = null) {
    return fail_if(!exp, reason);
}

bool fail_if_eq_int(int left, int right, string? reason = null) {
    return fail_if(left == right, @"$(reason + ": " ?? "")$left == $right");
}

bool fail_if_not_eq_node(StanzaNode left, StanzaNode right, string? reason = null) {
    if (fail_if_not_eq_str(left.name, right.name, @"$(reason + ": " ?? "")name mismatch")) return true;
    if (fail_if_not_eq_str(left.val, right.val, @"$(reason + ": " ?? "")val mismatch")) return true;
    if (left.name == "#text") return false;
    if (fail_if_not_eq_str(left.ns_uri, right.ns_uri, @"$(reason + ": " ?? "")ns_uri mismatch")) return true;
    if (fail_if_not_eq_int(left.sub_nodes.size, right.sub_nodes.size, @"$(reason + ": " ?? "")sub node count mismatch")) return true;
    if (fail_if_not_eq_int(left.attributes.size, right.attributes.size, @"$(reason + ": " ?? "")attributes count mismatch")) return true;
    for (var i = 0; i < left.sub_nodes.size; i++) {
        if (fail_if_not_eq_node(left.sub_nodes[i], right.sub_nodes[i], @"$(reason + ": " ?? "")$(i+1)th subnode mismatch")) return true;
    }
    for (var i = 0; i < left.attributes.size; i++) {
        if (fail_if_not_eq_attr(left.attributes[i], right.attributes[i], @"$(reason + ": " ?? "")$(i+1)th attribute mismatch")) return true;
    }
    return false;
}

bool fail_if_not_eq_attr(StanzaAttribute left, StanzaAttribute right, string? reason = null) {
    if (fail_if_not_eq_str(left.name, right.name, @"$(reason + ": " ?? "")name mismatch")) return true;
    if (fail_if_not_eq_str(left.val, right.val, @"$(reason + ": " ?? "")val mismatch")) return true;
    if (fail_if_not_eq_str(left.ns_uri, right.ns_uri, @"$(reason + ": " ?? "")ns_uri mismatch")) return true;
    return false;
}

bool fail_if_not_eq_int(int left, int right, string? reason = null) {
    return fail_if_not(left == right, @"$(reason + ": " ?? "")$left != $right");
}

bool fail_if_not_eq_str(string? left, string? right, string? reason = null) {
    bool nullcheck = (left == null || right == null) && (left != null && right != null);
    if (left == null) left = "(null)";
    if (right == null) right = "(null)";
    return fail_if_not(!nullcheck && left == right, @"$(reason + ": " ?? "")$left != $right");
}

bool fail_if_not_eq_uint8_arr(uint8[] left, uint8[] right, string? reason = null) {
    if (fail_if_not_eq_int(left.length, right.length, @"$(reason + ": " ?? "")array length not equal")) return true;
    return fail_if_not_eq_str(Base64.encode(left), Base64.encode(right), reason);
}

bool fail_if_not_zero_int(int zero, string? reason = null) {
    return fail_if_not_eq_int(zero, 0, reason);
}

bool fail_if_zero_int(int zero, string? reason = null) {
    return fail_if_eq_int(zero, 0, reason);
}

bool fail_if_null(void* what, string? reason = null) {
    return fail_if(what == null || (size_t)what == 0, reason);
}

}
