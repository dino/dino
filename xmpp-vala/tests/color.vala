using Xmpp.Xep;

namespace Xmpp.Test {

class ColorTest : Gee.TestCase {

    public ColorTest() {
        base("color");

        add_test("xep-vectors-angle", () => { text_xep_vectors_angle(); });
        add_test("xep-vectors-rgbf", () => { test_xep_vectors_rgbf(); });
        add_test("rgb-to-angle", () => { test_rgb_to_angle(); });
    }

    public void text_xep_vectors_angle() {
        fail_if_not_eq_double(ConsistentColor.string_to_angle("Romeo"), 327.255249);
        fail_if_not_eq_double(ConsistentColor.string_to_angle("juliet@capulet.lit"), 209.410400);
        fail_if_not_eq_double(ConsistentColor.string_to_angle("😺"), 331.199341);
        fail_if_not_eq_double(ConsistentColor.string_to_angle("council"), 359.994507);
        fail_if_not_eq_double(ConsistentColor.string_to_angle("Board"), 171.430664);
    }

    private bool fail_if_not_eq_rgbf(float[] left, float[] right) {
        bool failed = false;
        for (int i = 0; i < 3; i++) {
            failed = fail_if_not_eq_float(left[i], right[i]) || failed;
        }
        return failed;
    }

    public void test_xep_vectors_rgbf() {
        fail_if_not_eq_rgbf(ConsistentColor.string_to_rgbf("Romeo"), {0.865f,0.000f,0.686f});
        fail_if_not_eq_rgbf(ConsistentColor.string_to_rgbf("juliet@capulet.lit"), {0.000f,0.515f,0.573f});
        fail_if_not_eq_rgbf(ConsistentColor.string_to_rgbf("😺"), {0.872f,0.000f,0.659f});
        fail_if_not_eq_rgbf(ConsistentColor.string_to_rgbf("council"), {0.918f,0.000f,0.394f});
        fail_if_not_eq_rgbf(ConsistentColor.string_to_rgbf("Board"), {0.000f,0.527f,0.457f});
    }

    public void test_rgb_to_angle() {
        string[] colors = {"e57373", "f06292", "ba68c8", "9575cd", "7986cb", "64b5f6", "4fc3f7", "4dd0e1", "4db6ac", "81c784", "aed581", "dce775", "fff176", "ffd54f", "ffb74d", "ff8a65"};
        foreach(string hex_color in colors) {
            uint8 r = (uint8) ((double) hex_color.substring(0, 2).to_long(null, 16));
            uint8 g = (uint8) ((double) hex_color.substring(2, 2).to_long(null, 16));
            uint8 b = (uint8) ((double) hex_color.substring(4, 2).to_long(null, 16));
            //print(@"$hex_color, $r, $g, $b, $(ConsistentColor.rgb_to_angle(r, g, b))\n");
        }
    }
}

}