namespace Omemo.Test {

class Curve25519 : Gee.TestCase {

    public Curve25519() {
        base("Curve25519");
        add_test("agreement", test_curve25519_agreement);
        add_test("generate_public", test_curve25519_generate_public);
        add_test("random_agreements", test_curve25519_random_agreements);
        add_test("signature", test_curve25519_signature);
    }

    private Context global_context;

    public override void set_up() {
        try {
            global_context = new Context();
        } catch (Error e) {
            fail_if_reached();
        }
    }

    public override void tear_down() {
        global_context = null;
    }

    void test_curve25519_agreement() {
        try {
            uint8[] alicePublic = {
                0x05, 0x1b, 0xb7, 0x59, 0x66,
                0xf2, 0xe9, 0x3a, 0x36, 0x91,
                0xdf, 0xff, 0x94, 0x2b, 0xb2,
                0xa4, 0x66, 0xa1, 0xc0, 0x8b,
                0x8d, 0x78, 0xca, 0x3f, 0x4d,
                0x6d, 0xf8, 0xb8, 0xbf, 0xa2,
                0xe4, 0xee, 0x28};

            uint8[] alicePrivate = {
                0xc8, 0x06, 0x43, 0x9d, 0xc9,
                0xd2, 0xc4, 0x76, 0xff, 0xed,
                0x8f, 0x25, 0x80, 0xc0, 0x88,
                0x8d, 0x58, 0xab, 0x40, 0x6b,
                0xf7, 0xae, 0x36, 0x98, 0x87,
                0x90, 0x21, 0xb9, 0x6b, 0xb4,
                0xbf, 0x59};

            uint8[] bobPublic = {
                0x05, 0x65, 0x36, 0x14, 0x99,
                0x3d, 0x2b, 0x15, 0xee, 0x9e,
                0x5f, 0xd3, 0xd8, 0x6c, 0xe7,
                0x19, 0xef, 0x4e, 0xc1, 0xda,
                0xae, 0x18, 0x86, 0xa8, 0x7b,
                0x3f, 0x5f, 0xa9, 0x56, 0x5a,
                0x27, 0xa2, 0x2f};

            uint8[] bobPrivate = {
                0xb0, 0x3b, 0x34, 0xc3, 0x3a,
                0x1c, 0x44, 0xf2, 0x25, 0xb6,
                0x62, 0xd2, 0xbf, 0x48, 0x59,
                0xb8, 0x13, 0x54, 0x11, 0xfa,
                0x7b, 0x03, 0x86, 0xd4, 0x5f,
                0xb7, 0x5d, 0xc5, 0xb9, 0x1b,
                0x44, 0x66};

            uint8[] shared = {
                0x32, 0x5f, 0x23, 0x93, 0x28,
                0x94, 0x1c, 0xed, 0x6e, 0x67,
                0x3b, 0x86, 0xba, 0x41, 0x01,
                0x74, 0x48, 0xe9, 0x9b, 0x64,
                0x9a, 0x9c, 0x38, 0x06, 0xc1,
                0xdd, 0x7c, 0xa4, 0xc4, 0x77,
                0xe6, 0x29};

            ECPublicKey alice_public_key = global_context.decode_public_key(alicePublic);
            ECPrivateKey alice_private_key = global_context.decode_private_key(alicePrivate);
            ECPublicKey bob_public_key = global_context.decode_public_key(bobPublic);
            ECPrivateKey bob_private_key = global_context.decode_private_key(bobPrivate);

            uint8[] shared_one = calculate_agreement(alice_public_key, bob_private_key);
            uint8[] shared_two = calculate_agreement(bob_public_key, alice_private_key);

            fail_if_not_eq_int(shared_one.length, 32);
            fail_if_not_eq_int(shared_two.length, 32);
            fail_if_not_eq_uint8_arr(shared, shared_one);
            fail_if_not_eq_uint8_arr(shared_one, shared_two);
        } catch (Error e) {
            fail_if_reached();
        }
    }

    void test_curve25519_generate_public() {
        try {
            uint8[] alicePublic = {
                0x05, 0x1b, 0xb7, 0x59, 0x66,
                0xf2, 0xe9, 0x3a, 0x36, 0x91,
                0xdf, 0xff, 0x94, 0x2b, 0xb2,
                0xa4, 0x66, 0xa1, 0xc0, 0x8b,
                0x8d, 0x78, 0xca, 0x3f, 0x4d,
                0x6d, 0xf8, 0xb8, 0xbf, 0xa2,
                0xe4, 0xee, 0x28};

            uint8[] alicePrivate = {
                0xc8, 0x06, 0x43, 0x9d, 0xc9,
                0xd2, 0xc4, 0x76, 0xff, 0xed,
                0x8f, 0x25, 0x80, 0xc0, 0x88,
                0x8d, 0x58, 0xab, 0x40, 0x6b,
                0xf7, 0xae, 0x36, 0x98, 0x87,
                0x90, 0x21, 0xb9, 0x6b, 0xb4,
                0xbf, 0x59};

            ECPrivateKey alice_private_key = global_context.decode_private_key(alicePrivate);
            ECPublicKey alice_expected_public_key = global_context.decode_public_key(alicePublic);
            ECPublicKey alice_public_key = generate_public_key(alice_private_key);

            fail_if_not_zero_int(alice_expected_public_key.compare(alice_public_key));
        } catch (Error e) {
            fail_if_reached();
        }
    }

    void test_curve25519_random_agreements() {
        try {
            ECKeyPair alice_key_pair = null;
            ECPublicKey alice_public_key = null;
            ECPrivateKey alice_private_key = null;
            ECKeyPair bob_key_pair = null;
            ECPublicKey bob_public_key = null;
            ECPrivateKey bob_private_key = null;
            uint8[] shared_alice = null;
            uint8[] shared_bob = null;

            for (int i = 0; i < 50; i++) {
                fail_if_null(alice_key_pair = global_context.generate_key_pair());
                fail_if_null(alice_public_key = alice_key_pair.public);
                fail_if_null(alice_private_key = alice_key_pair.private);

                fail_if_null(bob_key_pair = global_context.generate_key_pair());
                fail_if_null(bob_public_key = bob_key_pair.public);
                fail_if_null(bob_private_key = bob_key_pair.private);

                shared_alice = calculate_agreement(bob_public_key, alice_private_key);
                fail_if_not_eq_int(shared_alice.length, 32);

                shared_bob = calculate_agreement(alice_public_key, bob_private_key);
                fail_if_not_eq_int(shared_bob.length, 32);

                fail_if_not_eq_uint8_arr(shared_alice, shared_bob);
            }
        } catch (Error e) {
            fail_if_reached();
        }
    }

    void test_curve25519_signature() {
        try {
            uint8[] aliceIdentityPrivate = {
                0xc0, 0x97, 0x24, 0x84, 0x12, 0xe5, 0x8b, 0xf0,
                0x5d, 0xf4, 0x87, 0x96, 0x82, 0x05, 0x13, 0x27,
                0x94, 0x17, 0x8e, 0x36, 0x76, 0x37, 0xf5, 0x81,
                0x8f, 0x81, 0xe0, 0xe6, 0xce, 0x73, 0xe8, 0x65};

            uint8[] aliceIdentityPublic = {
                0x05, 0xab, 0x7e, 0x71, 0x7d, 0x4a, 0x16, 0x3b,
                0x7d, 0x9a, 0x1d, 0x80, 0x71, 0xdf, 0xe9, 0xdc,
                0xf8, 0xcd, 0xcd, 0x1c, 0xea, 0x33, 0x39, 0xb6,
                0x35, 0x6b, 0xe8, 0x4d, 0x88, 0x7e, 0x32, 0x2c,
                0x64};

            uint8[] aliceEphemeralPublic = {
                0x05, 0xed, 0xce, 0x9d, 0x9c, 0x41, 0x5c, 0xa7,
                0x8c, 0xb7, 0x25, 0x2e, 0x72, 0xc2, 0xc4, 0xa5,
                0x54, 0xd3, 0xeb, 0x29, 0x48, 0x5a, 0x0e, 0x1d,
                0x50, 0x31, 0x18, 0xd1, 0xa8, 0x2d, 0x99, 0xfb,
                0x4a};

            uint8[] aliceSignature = {
                0x5d, 0xe8, 0x8c, 0xa9, 0xa8, 0x9b, 0x4a, 0x11,
                0x5d, 0xa7, 0x91, 0x09, 0xc6, 0x7c, 0x9c, 0x74,
                0x64, 0xa3, 0xe4, 0x18, 0x02, 0x74, 0xf1, 0xcb,
                0x8c, 0x63, 0xc2, 0x98, 0x4e, 0x28, 0x6d, 0xfb,
                0xed, 0xe8, 0x2d, 0xeb, 0x9d, 0xcd, 0x9f, 0xae,
                0x0b, 0xfb, 0xb8, 0x21, 0x56, 0x9b, 0x3d, 0x90,
                0x01, 0xbd, 0x81, 0x30, 0xcd, 0x11, 0xd4, 0x86,
                0xce, 0xf0, 0x47, 0xbd, 0x60, 0xb8, 0x6e, 0x88};

            global_context.decode_private_key(aliceIdentityPrivate);
            global_context.decode_public_key(aliceEphemeralPublic);
            ECPublicKey alice_public_key = global_context.decode_public_key(aliceIdentityPublic);

            fail_if(!verify_signature(alice_public_key, aliceEphemeralPublic, aliceSignature), "signature verification failed");

            uint8[] modifiedSignature = new uint8[aliceSignature.length];

            for (int i = 0; i < aliceSignature.length; i++) {
                Memory.copy(modifiedSignature, aliceSignature, aliceSignature.length);
                modifiedSignature[i] ^= 0x01;

                fail_if(verify_signature(alice_public_key, aliceEphemeralPublic, modifiedSignature), "invalid signature verification succeeded");
            }
        } catch (Error e) {
            fail_if_reached();
        }
    }

}

}