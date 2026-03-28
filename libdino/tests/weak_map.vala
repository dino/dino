using Dino.Entities;

namespace Dino.Test {

    class WeakMapTest : Gee.TestCase {

        public WeakMapTest() {
            base("WeakMapTest");
            add_test("set", test_set);
            add_test("set2", test_set2);
            add_test("set3", test_set3);
            add_test("set4", test_unset);
            add_test("remove_when_out_of_scope", test_remove_when_out_of_scope);
//            add_test("non_object_construction", test_non_object_construction);
        }

        private void test_set() {
            WeakMap<int, Object> map = new WeakMap<int, Object>();
            var o = new Object();
            map[1] = o;

            assert(map.size == 1);
            assert(map.has_key(1));
            assert(map[1] == o);
        }

        private void test_set2() {
            WeakMap<int, Object> map = new WeakMap<int, Object>();
            var o = new Object();
            var o2 = new Object();
            map[1] = o;
            map[1] = o2;

            assert(map.size == 1);
            assert(map.has_key(1));
            assert(map[1] == o2);
        }

        private void test_set3() {
            WeakMap<int, Object> map = new WeakMap<int, Object>();

            var o1 = new Object();
            var o2 = new Object();

            map[0] = o1;
            map[3] = o2;

            {
                var o3 = new Object();
                var o4 = new Object();
                map[7] = o3;
                map[50] = o4;
            }

            var o5 = new Object();
            map[5] = o5;

            assert(map.size == 3);

            assert(map.has_key(0));
            assert(map.has_key(3));
            assert(map.has_key(5));

            assert(map[0] == o1);
            assert(map[3] == o2);
            assert(map[5] == o5);
        }

        private void test_unset() {
            WeakMap<int, Object> map = new WeakMap<int, Object>();
            var o1 = new Object();
            map[7] = o1;
            map.unset(7);

            assert_true(map.size == 0);
            assert_true(map.is_empty);
            assert_false(map.has_key(7));

        }

        private void test_remove_when_out_of_scope() {
            WeakMap<int, Object> map = new WeakMap<int, Object>();

            {
                map[0] = new Object();
            }

            assert_false(map.has_key(0));
        }

        private void test_non_object_construction() {
            WeakMap<int, int> map = new WeakMap<int, int>();
            assert_not_reached();
        }
    }

}
