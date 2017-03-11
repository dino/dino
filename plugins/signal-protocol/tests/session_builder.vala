namespace Signal.Test {

class SessionBuilderTest : Gee.TestCase {
    Address alice_address;
    Address bob_address;

    public SessionBuilderTest() {
        base("SessionBuilder");

        add_test("basic_pre_key_v2", test_basic_pre_key_v2);
        add_test("basic_pre_key_v3", test_basic_pre_key_v3);
        add_test("bad_signed_pre_key_signature", test_bad_signed_pre_key_signature);
        add_test("repeat_bundle_message_v2", test_repeat_bundle_message_v2);
    }

    private Context global_context;

    public override void set_up() {
        try {
            global_context = new Context();
            alice_address = new Address();
            alice_address.name = "+14151111111";
            alice_address.device_id = 1;
            bob_address = new Address();
            bob_address.name = "+14152222222";
            bob_address.device_id = 1;
        } catch (Error e) {
            fail_if_reached(@"Unexpected error: $(e.message)");
        }
    }

    public override void tear_down() {
        global_context = null;
        alice_address = null;
        bob_address = null;
    }

    void test_basic_pre_key_v2() {
        try {
            /* Create Alice's data store and session builder */
            Store alice_store = setup_test_store_context(global_context);
            SessionBuilder alice_session_builder = alice_store.create_session_builder(bob_address);

            /* Create Bob's data store and pre key bundle */
            Store bob_store = setup_test_store_context(global_context);
            uint32 bob_local_registration_id = bob_store.local_registration_id;
            IdentityKeyPair bob_identity_key_pair = bob_store.identity_key_pair;
            ECKeyPair bob_pre_key_pair = global_context.generate_key_pair();

            PreKeyBundle bob_pre_key = create_pre_key_bundle(bob_local_registration_id, 1, 31337, bob_pre_key_pair.public, 0, null, null, bob_identity_key_pair.public);

            /*
             * Have Alice process Bob's pre key bundle, which should fail due to a
             * missing unsigned pre key.
             */
            fail_if_not_error_code(() => alice_session_builder.process_pre_key_bundle(bob_pre_key), ErrorCode.INVALID_KEY);
        } catch(Error e) {
            fail_if_reached(@"Unexpected error: $(e.message)");
        }
    }

    void test_basic_pre_key_v3() {
        try {
            /* Create Alice's data store and session builder */
            Store alice_store = setup_test_store_context(global_context);
            SessionBuilder alice_session_builder = alice_store.create_session_builder(bob_address);

            /* Create Bob's data store and pre key bundle */
            Store bob_store = setup_test_store_context(global_context);
            uint32 bob_local_registration_id = bob_store.local_registration_id;
            ECKeyPair bob_pre_key_pair = global_context.generate_key_pair();
            ECKeyPair bob_signed_pre_key_pair = global_context.generate_key_pair();
            IdentityKeyPair bob_identity_key_pair = bob_store.identity_key_pair;

            uint8[] bob_signed_pre_key_signature = global_context.calculate_signature(bob_identity_key_pair.private, bob_signed_pre_key_pair.public.serialize());

            PreKeyBundle bob_pre_key = create_pre_key_bundle(bob_local_registration_id, 1, 31337, bob_pre_key_pair.public, 22, bob_signed_pre_key_pair.public, bob_signed_pre_key_signature, bob_identity_key_pair.public);

            /* Have Alice process Bob's pre key bundle */
            alice_session_builder.process_pre_key_bundle(bob_pre_key);

            /* Check that we can load the session state and verify its version */
            fail_if_not(alice_store.contains_session(bob_address));

            SessionRecord loaded_record = alice_store.load_session(bob_address);
            fail_if_not_eq_int((int)loaded_record.state.session_version, 3);

            /* Encrypt an outgoing message to send to Bob */
            string original_message = "L'homme est condamné à être libre";
            SessionCipher alice_session_cipher = alice_store.create_session_cipher(bob_address);

            CiphertextMessage outgoing_message = alice_session_cipher.encrypt(original_message.data);
            fail_if_not_eq_int(outgoing_message.type, CiphertextType.PREKEY);

            /* Convert to an incoming message for Bob */
            PreKeySignalMessage incoming_message = global_context.deserialize_pre_key_signal_message(outgoing_message.serialized);

            /* Save the pre key and signed pre key in Bob's data store */
            PreKeyRecord bob_pre_key_record = new PreKeyRecord(bob_pre_key.pre_key_id, bob_pre_key_pair);
            bob_store.store_pre_key(bob_pre_key_record);

            SignedPreKeyRecord bob_signed_pre_key_record = new SignedPreKeyRecord(22, new DateTime.now_local().to_unix(), bob_signed_pre_key_pair, bob_signed_pre_key_signature);
            bob_store.store_signed_pre_key(bob_signed_pre_key_record);

            /* Create Bob's session cipher and decrypt the message from Alice */
            SessionCipher bob_session_cipher = bob_store.create_session_cipher(alice_address);

            /* Prepare the data for the callback test */
            //int callback_context = 1234;
            //bob_session_cipher.user_data =
            //bob_session_cipher.decryption_callback =
            uint8[] plaintext = bob_session_cipher.decrypt_pre_key_signal_message(incoming_message);

            /* Clean up callback data */
            bob_session_cipher.user_data = null;
            bob_session_cipher.decryption_callback = null;

            /* Verify Bob's session state and the decrypted message */
            fail_if_not(bob_store.contains_session(alice_address));

            SessionRecord alice_recipient_session_record = bob_store.load_session(alice_address);

            SessionState alice_recipient_session_state = alice_recipient_session_record.state;
            fail_if_not_eq_int((int)alice_recipient_session_state.session_version, 3);
            fail_if_null(alice_recipient_session_state.alice_base_key);

            fail_if_not_eq_uint8_arr(original_message.data, plaintext);

            /* Have Bob send a reply to Alice */
            CiphertextMessage bob_outgoing_message = bob_session_cipher.encrypt(original_message.data);
            fail_if_not_eq_int(bob_outgoing_message.type, CiphertextType.SIGNAL);

            /* Verify that Alice can decrypt it */
            SignalMessage bob_outgoing_message_copy = global_context.copy_signal_message(bob_outgoing_message);

            uint8[] alice_plaintext = alice_session_cipher.decrypt_signal_message(bob_outgoing_message_copy);

            fail_if_not_eq_uint8_arr(original_message.data, alice_plaintext);

            GLib.Test.message("Pre-interaction tests complete");

            /* Interaction tests */
            run_interaction(alice_store, bob_store);

            /* Cleanup state from previous tests that we need to replace */
            alice_store = null;
            bob_pre_key_pair = null;
            bob_signed_pre_key_pair = null;
            bob_identity_key_pair = null;
            bob_signed_pre_key_signature = null;
            bob_pre_key_record = null;
            bob_signed_pre_key_record = null;

            /* Create Alice's new session data */
            alice_store = setup_test_store_context(global_context);
            alice_session_builder = alice_store.create_session_builder(bob_address);
            alice_session_cipher = alice_store.create_session_cipher(bob_address);

            /* Create Bob's new pre key bundle */
            bob_pre_key_pair = global_context.generate_key_pair();
            bob_signed_pre_key_pair = global_context.generate_key_pair();
            bob_identity_key_pair = bob_store.identity_key_pair;
            bob_signed_pre_key_signature = global_context.calculate_signature(bob_identity_key_pair.private, bob_signed_pre_key_pair.public.serialize());
            bob_pre_key = create_pre_key_bundle(bob_local_registration_id, 1, 31338, bob_pre_key_pair.public, 23, bob_signed_pre_key_pair.public, bob_signed_pre_key_signature, bob_identity_key_pair.public);

            /* Save the new pre key and signed pre key in Bob's data store */
            bob_pre_key_record = new PreKeyRecord(bob_pre_key.pre_key_id, bob_pre_key_pair);
            bob_store.store_pre_key(bob_pre_key_record);

            bob_signed_pre_key_record = new SignedPreKeyRecord(23, new DateTime.now_local().to_unix(), bob_signed_pre_key_pair, bob_signed_pre_key_signature);
            bob_store.store_signed_pre_key(bob_signed_pre_key_record);

            /* Have Alice process Bob's pre key bundle */
            alice_session_builder.process_pre_key_bundle(bob_pre_key);

            /* Have Alice encrypt a message for Bob */
            outgoing_message = alice_session_cipher.encrypt(original_message.data);
            fail_if_not_eq_int(outgoing_message.type, CiphertextType.PREKEY);

            /* Have Bob try to decrypt the message */
            PreKeySignalMessage outgoing_message_copy = global_context.copy_pre_key_signal_message(outgoing_message);

            /* The decrypt should fail with a specific error */
            fail_if_not_error_code(() => bob_session_cipher.decrypt_pre_key_signal_message(outgoing_message_copy), ErrorCode.UNTRUSTED_IDENTITY);

            outgoing_message_copy = global_context.copy_pre_key_signal_message(outgoing_message);

            /* Save the identity key to Bob's store */
            bob_store.save_identity(alice_address, outgoing_message_copy.identity_key);

            /* Try the decrypt again, this time it should succeed */
            outgoing_message_copy = global_context.copy_pre_key_signal_message(outgoing_message);
            plaintext = bob_session_cipher.decrypt_pre_key_signal_message(outgoing_message_copy);

            fail_if_not_eq_uint8_arr(original_message.data, plaintext);

            /* Create a new pre key for Bob */
            ECPublicKey test_public_key = create_test_ec_public_key(global_context);

            IdentityKeyPair alice_identity_key_pair = alice_store.identity_key_pair;

            bob_pre_key = create_pre_key_bundle(bob_local_registration_id, 1, 31337, test_public_key, 23, bob_signed_pre_key_pair.public, bob_signed_pre_key_signature, alice_identity_key_pair.public);

            /* Have Alice process Bob's new pre key bundle, which should fail */
            fail_if_not_error_code(() => alice_session_builder.process_pre_key_bundle(bob_pre_key), ErrorCode.UNTRUSTED_IDENTITY);

            GLib.Test.message("Post-interaction tests complete");
        } catch(Error e) {
            fail_if_reached(@"Unexpected error: $(e.message)");
        }
    }

    void test_bad_signed_pre_key_signature() {
        try {
            /* Create Alice's data store and session builder */
            Store alice_store = setup_test_store_context(global_context);
            SessionBuilder alice_session_builder = alice_store.create_session_builder(bob_address);

            /* Create Bob's data store */
            Store bob_store = setup_test_store_context(global_context);

            /* Create Bob's regular and signed pre key pairs */
            ECKeyPair bob_pre_key_pair = global_context.generate_key_pair();
            ECKeyPair bob_signed_pre_key_pair = global_context.generate_key_pair();

            /* Create Bob's signed pre key signature */
            IdentityKeyPair bob_identity_key_pair = bob_store.identity_key_pair;
            uint8[] bob_signed_pre_key_signature = global_context.calculate_signature(bob_identity_key_pair.private, bob_signed_pre_key_pair.public.serialize());

            for (int i = 0; i < bob_signed_pre_key_signature.length * 8; i++) {
                uint8[] modified_signature = bob_signed_pre_key_signature[0:bob_signed_pre_key_signature.length];

                /* Intentionally corrupt the signature data */
                modified_signature[i/8] ^= (1 << ((uint8)i % 8));

                /* Create a pre key bundle */
                PreKeyBundle bob_pre_key = create_pre_key_bundle(bob_store.local_registration_id,1,31137,bob_pre_key_pair.public,22,bob_signed_pre_key_pair.public,modified_signature,bob_identity_key_pair.public);

                /* Process the bundle and make sure we fail with an invalid key error */
                fail_if_not_error_code(() => alice_session_builder.process_pre_key_bundle(bob_pre_key), ErrorCode.INVALID_KEY);
            }

            /* Create a correct pre key bundle */
            PreKeyBundle bob_pre_key = create_pre_key_bundle(bob_store.local_registration_id,1,31137,bob_pre_key_pair.public,22,bob_signed_pre_key_pair.public,bob_signed_pre_key_signature,bob_identity_key_pair.public);

            /* Process the bundle and make sure we do not fail */
            alice_session_builder.process_pre_key_bundle(bob_pre_key);
        } catch(Error e) {
            fail_if_reached(@"Unexpected error: $(e.message)");
        }
    }

    void test_repeat_bundle_message_v2() {
        try {
            /* Create Alice's data store and session builder */
            Store alice_store = setup_test_store_context(global_context);
            SessionBuilder alice_session_builder = alice_store.create_session_builder(bob_address);

            /* Create Bob's data store and pre key bundle */
            Store bob_store = setup_test_store_context(global_context);
            ECKeyPair bob_pre_key_pair = global_context.generate_key_pair();
            ECKeyPair bob_signed_pre_key_pair = global_context.generate_key_pair();
            uint8[] bob_signed_pre_key_signature = global_context.calculate_signature(bob_store.identity_key_pair.private, bob_signed_pre_key_pair.public.serialize());
            PreKeyBundle bob_pre_key = create_pre_key_bundle(bob_store.local_registration_id,1,31337,bob_pre_key_pair.public,0,null,null,bob_store.identity_key_pair.public);

            /* Add Bob's pre keys to Bob's data store */
            PreKeyRecord bob_pre_key_record = new PreKeyRecord(bob_pre_key.pre_key_id, bob_pre_key_pair);
            bob_store.store_pre_key(bob_pre_key_record);
            SignedPreKeyRecord bob_signed_pre_key_record = new SignedPreKeyRecord(22, new DateTime.now_local().to_unix(), bob_signed_pre_key_pair, bob_signed_pre_key_signature);
            bob_store.store_signed_pre_key(bob_signed_pre_key_record);

            /*
             * Have Alice process Bob's pre key bundle, which should fail due to a
             * missing signed pre key.
             */
            fail_if_not_error_code(() => alice_session_builder.process_pre_key_bundle(bob_pre_key), ErrorCode.INVALID_KEY);
        } catch(Error e) {
            fail_if_reached(@"Unexpected error: $(e.message)");
        }
    }

    class Holder {
        public uint8[] data { get; private set; }

        public Holder(uint8[] data) {
            this.data = data;
        }
    }

    void run_interaction(Store alice_store, Store bob_store) throws Error {

        /* Create the session ciphers */
        SessionCipher alice_session_cipher = alice_store.create_session_cipher(bob_address);
        SessionCipher bob_session_cipher = bob_store.create_session_cipher(alice_address);

        /* Create a test message */
        string original_message = "smert ze smert";

        /* Simulate Alice sending a message to Bob */
        CiphertextMessage alice_message = alice_session_cipher.encrypt(original_message.data);
        fail_if_not_eq_int(alice_message.type, CiphertextType.SIGNAL);

        SignalMessage alice_message_copy = global_context.copy_signal_message(alice_message);
        uint8[] plaintext = bob_session_cipher.decrypt_signal_message(alice_message_copy);
        fail_if_not_eq_uint8_arr(original_message.data, plaintext);

        GLib.Test.message("Interaction complete: Alice -> Bob");

        /* Simulate Bob sending a message to Alice */
        CiphertextMessage bob_message = bob_session_cipher.encrypt(original_message.data);
        fail_if_not_eq_int(alice_message.type, CiphertextType.SIGNAL);

        SignalMessage bob_message_copy = global_context.copy_signal_message(bob_message);
        plaintext = alice_session_cipher.decrypt_signal_message(bob_message_copy);
        fail_if_not_eq_uint8_arr(original_message.data, plaintext);

        GLib.Test.message("Interaction complete: Bob -> Alice");

        /* Looping Alice -> Bob */
        for (int i = 0; i < 10; i++) {
            uint8[] looping_message = create_looping_message(i);
            CiphertextMessage alice_looping_message = alice_session_cipher.encrypt(looping_message);
            SignalMessage alice_looping_message_copy = global_context.copy_signal_message(alice_looping_message);
            uint8[] looping_plaintext = bob_session_cipher.decrypt_signal_message(alice_looping_message_copy);
            fail_if_not_eq_uint8_arr(looping_message, looping_plaintext);
        }
        GLib.Test.message("Interaction complete: Alice -> Bob (looping)");

        /* Looping Bob -> Alice */
        for (int i = 0; i < 10; i++) {
            uint8[] looping_message = create_looping_message(i);
            CiphertextMessage bob_looping_message = bob_session_cipher.encrypt(looping_message);
            SignalMessage bob_looping_message_copy = global_context.copy_signal_message(bob_looping_message);
            uint8[] looping_plaintext = alice_session_cipher.decrypt_signal_message(bob_looping_message_copy);
            fail_if_not_eq_uint8_arr(looping_message, looping_plaintext);
        }
        GLib.Test.message("Interaction complete: Bob -> Alice (looping)");

        /* Generate a shuffled list of encrypted messages for later use */
        Holder[] alice_ooo_plaintext = new Holder[10];
        Holder[] alice_ooo_ciphertext = new Holder[10];
        for (int i = 0; i < 10; i++) {
            alice_ooo_plaintext[i] = new Holder(create_looping_message(i));
            alice_ooo_ciphertext[i] = new Holder(alice_session_cipher.encrypt(alice_ooo_plaintext[i].data).serialized);
        }

        for (int i = 0; i < 10; i++) {
            uint32 s = Random.next_int() % 10;
            Holder tmp = alice_ooo_plaintext[s];
            alice_ooo_plaintext[s] = alice_ooo_plaintext[i];
            alice_ooo_plaintext[i] = tmp;
            tmp = alice_ooo_ciphertext[s];
            alice_ooo_ciphertext[s] = alice_ooo_ciphertext[i];
            alice_ooo_ciphertext[i] = tmp;
        }
        GLib.Test.message("Shuffled Alice->Bob messages created");

        /* Looping Alice -> Bob (repeated) */
        for (int i = 0; i < 10; i++) {
            uint8[] looping_message = create_looping_message(i);
            CiphertextMessage alice_looping_message = alice_session_cipher.encrypt(looping_message);
            SignalMessage alice_looping_message_copy = global_context.copy_signal_message(alice_looping_message);
            uint8[] looping_plaintext = bob_session_cipher.decrypt_signal_message(alice_looping_message_copy);
            fail_if_not_eq_uint8_arr(looping_message, looping_plaintext);
        }
        GLib.Test.message("Interaction complete: Alice -> Bob (looping, repeated)");

        /* Looping Bob -> Alice (repeated) */
        for (int i = 0; i < 10; i++) {
            uint8[] looping_message = create_looping_message(i);
            CiphertextMessage bob_looping_message = bob_session_cipher.encrypt(looping_message);
            SignalMessage bob_looping_message_copy = global_context.copy_signal_message(bob_looping_message);
            uint8[] looping_plaintext = alice_session_cipher.decrypt_signal_message(bob_looping_message_copy);
            fail_if_not_eq_uint8_arr(looping_message, looping_plaintext);
        }
        GLib.Test.message("Interaction complete: Bob -> Alice (looping, repeated)");

        /* Shuffled Alice -> Bob */
        for (int i = 0; i < 10; i++) {
            SignalMessage ooo_message_deserialized = global_context.deserialize_signal_message(alice_ooo_ciphertext[i].data);
            uint8[] ooo_plaintext = bob_session_cipher.decrypt_signal_message(ooo_message_deserialized);
            fail_if_not_eq_uint8_arr(alice_ooo_plaintext[i].data, ooo_plaintext);
        }
        GLib.Test.message("Interaction complete: Alice -> Bob (shuffled)");
    }

    uint8[] create_looping_message(int index) {
        return (@"You can only desire based on what you know: $index").data;
    }

    /*
    uint8[] create_looping_message_short(int index) {
        return ("What do we mean by saying that existence precedes essence? " +
            "We mean that man first of all exists, encounters himself, " +
            @"surges up in the world--and defines himself aftward. $index").data;
    }
    */
}

}