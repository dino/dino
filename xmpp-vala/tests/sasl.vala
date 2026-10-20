using Xmpp.Sasl;

namespace Xmpp.Test {

class SaslTest : Gee.TestCase {
    public SaslTest() {
        base("sasl");
        add_test("reject-mandatory-extension", () => {
            expect_invalid("m=unknown,r=clientserver,s=c2FsdA==,i=1");
        });
        add_test("reject-invalid-challenge", () => { expect_invalid("invalid"); });
        add_test("reject-duplicate-attribute", () => {
            expect_invalid("r=clientserver,s=c2FsdA==,i=1,i=2");
        });
        add_test("reject-unextended-nonce", () => { expect_invalid("r=client,s=c2FsdA==,i=1"); });
        add_test("reject-iteration-suffix", () => { expect_invalid("r=clientserver,s=c2FsdA==,i=1junk"); });
        add_test("reject-unsupported-binding", () => {
            var stream = new SaslTestStream();
            stream.features.put_node(new StanzaNode.build("sasl-channel-binding", "urn:xmpp:sasl-cb:0")
                .put_node(new StanzaNode.build("channel-binding", "urn:xmpp:sasl-cb:0").put_attribute("type", "unknown")));
            try {
                string first;
                start_scram(stream, { "SCRAM-SHA-256-PLUS", "SCRAM-SHA-256", "PLAIN" }, "user", "password", out first);
                fail_if_reached("Unsupported binding must stop authentication");
            } catch (Error e) {}
        });
        foreach (string iterations in new string[] { "-1", "0", "01", "1000001", "4294967296", "18446744073709551616" }) {
            string value = iterations;
            add_test("reject-iterations-" + value, () => { expect_invalid("r=clientserver,s=c2FsdA==,i=" + value); });
        }
        add_test("reject-invalid-salt", () => { expect_invalid("r=clientserver,s=!!!,i=1"); });
        add_test("reject-stripped-binding-types", () => {
            try {
                string first;
                start_scram(new SaslTestStream(), { "SCRAM-SHA-256-PLUS", "SCRAM-SHA-256" }, "user", "password", out first);
                fail_if_reached("Missing binding types accepted");
            } catch (Error e) {}
        });
        add_test("reject-stripped-plus", () => {
            var stream = new SaslTestStream();
            stream.features.put_node(new StanzaNode.build("sasl-channel-binding", "urn:xmpp:sasl-cb:0")
                .put_node(new StanzaNode.build("channel-binding", "urn:xmpp:sasl-cb:0").put_attribute("type", "tls-exporter")));
            try {
                string first;
                start_scram(stream, { "SCRAM-SHA-256", "PLAIN" }, "user", "password", out first);
                fail_if_reached("Stripped PLUS accepted");
            } catch (Error e) {}
        });
        add_test("escape-username", () => {
            try {
                string first;
                var flag = start_scram(new SaslTestStream(), { "SCRAM-SHA-256" }, "a=b,c", "password", out first);
                fail_if_not(first.has_prefix("n,,n=a=3Db=2Cc,r="));
                fail_if_not_eq_str(flag.name, "a=3Db=2Cc");
            } catch (Error e) { fail_if_reached(e.message); }
        });
        add_test("sha1-plain-proof", () => {
            try {
                var response = compute_challenge_response("cj1jbGllbnRzZXJ2ZXIscz1jMkZzZEE9PSxpPTQwOTY=", "pencil", "client", "user", ChecksumType.SHA1, Base64.decode("biws"));
                fail_if_not_eq_str(response.response, "c=biws,r=clientserver,p=4+FHWqvtQ3w06HqnWGqSJgzxmjk=");
                fail_if_not_eq_str(Base64.encode(response.expected_server_signature), "9HKf506Wy7dimDIpbS1Us9voiaw=");
                verify_server_signature(Base64.encode("v=9HKf506Wy7dimDIpbS1Us9voiaw=".data), response.expected_server_signature);
            } catch (Error e) { fail_if_reached(e.message); }
        });
        add_test("sha1-exporter-proof", () => {
            try {
                var response = compute_challenge_response("cj1jbGllbnRzZXJ2ZXIscz1jMkZzZEE9PSxpPTQwOTY=", "pencil", "client", "user", ChecksumType.SHA1, Base64.decode("cD10bHMtZXhwb3J0ZXIsLAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f"));
                fail_if_not_eq_str(response.response, "c=cD10bHMtZXhwb3J0ZXIsLAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f,r=clientserver,p=NnLkvdabwI9LET05dsLtXrrxInQ=");
                fail_if_not_eq_str(Base64.encode(response.expected_server_signature), "e84TigsFGyLo3YtyIMdzmOe0q28=");
                verify_server_signature(Base64.encode("v=e84TigsFGyLo3YtyIMdzmOe0q28=".data), response.expected_server_signature);
            } catch (Error e) { fail_if_reached(e.message); }
        });
        add_test("sha256-plain-proof", () => {
            try {
                var response = compute_challenge_response("cj1jbGllbnRzZXJ2ZXIscz1jMkZzZEE9PSxpPTQwOTY=", "pencil", "client", "user", ChecksumType.SHA256, Base64.decode("biws"));
                fail_if_not_eq_str(response.response, "c=biws,r=clientserver,p=CFQgWvxVZUYSi1mqsHDXP722uJHKDtyvcbmFOCc757A=");
                fail_if_not_eq_str(Base64.encode(response.expected_server_signature), "U796hJH+W+NKXETWiomkC9FpsLHJPykLpJJtSzkgu/I=");
                verify_server_signature(Base64.encode("v=U796hJH+W+NKXETWiomkC9FpsLHJPykLpJJtSzkgu/I=".data), response.expected_server_signature);
            } catch (Error e) { fail_if_reached(e.message); }
        });
        add_test("sha256-exporter-proof", () => {
            try {
                var response = compute_challenge_response("cj1jbGllbnRzZXJ2ZXIscz1jMkZzZEE9PSxpPTQwOTY=", "pencil", "client", "user", ChecksumType.SHA256, Base64.decode("cD10bHMtZXhwb3J0ZXIsLAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f"));
                fail_if_not_eq_str(response.response, "c=cD10bHMtZXhwb3J0ZXIsLAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f,r=clientserver,p=eIYgJXF3jMR7eyITb4fuWEwgrOggxWH1ddTDPcJko8o=");
                fail_if_not_eq_str(Base64.encode(response.expected_server_signature), "YZ5Ck5fqPdDQqOX7JRZ+1ldIqxbTPU5PDh98PMb4EP8=");
                verify_server_signature(Base64.encode("v=YZ5Ck5fqPdDQqOX7JRZ+1ldIqxbTPU5PDh98PMb4EP8=".data), response.expected_server_signature);
            } catch (Error e) { fail_if_reached(e.message); }
        });
        add_test("sha512-plain-proof", () => {
            try {
                var response = compute_challenge_response("cj1jbGllbnRzZXJ2ZXIscz1jMkZzZEE9PSxpPTQwOTY=", "pencil", "client", "user", ChecksumType.SHA512, Base64.decode("biws"));
                fail_if_not_eq_str(response.response, "c=biws,r=clientserver,p=sBr56Sn9FJQBipY6vDhajWOmQ/7IarAj/UjwqQOBdImPjFEJzDxN7LVVHcD1i5dzIH5WMwv8HHJbWifbUsHavw==");
                fail_if_not_eq_str(Base64.encode(response.expected_server_signature), "rMgtReTMOe52Vs9dd1uMvIiU1gQ9f5sQwdaWm3cnZIfh3YA+eJ/cZezty6iYDM/jhRH61RFkqT/j9h90TnPrkg==");
                verify_server_signature(Base64.encode("v=rMgtReTMOe52Vs9dd1uMvIiU1gQ9f5sQwdaWm3cnZIfh3YA+eJ/cZezty6iYDM/jhRH61RFkqT/j9h90TnPrkg==".data), response.expected_server_signature);
            } catch (Error e) { fail_if_reached(e.message); }
        });
        add_test("sha512-exporter-proof", () => {
            try {
                var response = compute_challenge_response("cj1jbGllbnRzZXJ2ZXIscz1jMkZzZEE9PSxpPTQwOTY=", "pencil", "client", "user", ChecksumType.SHA512, Base64.decode("cD10bHMtZXhwb3J0ZXIsLAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f"));
                fail_if_not_eq_str(response.response, "c=cD10bHMtZXhwb3J0ZXIsLAABAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhscHR4f,r=clientserver,p=bifK5rJvNOXV0v/gj9kJPtnP354Ia76yASiNkmptsPxb0BiGh9dqo40VuBW6tuSoiCnV3iTYopSoN5oCRFQvjA==");
                fail_if_not_eq_str(Base64.encode(response.expected_server_signature), "W654O28SMvjsZfNTuFWgzuZvu3svjqIPhxVvUJDjZ2Kid7Q3bTrL2BnlvV8RJNotMkS2DkqvcJesJ/wffGXL5g==");
                verify_server_signature(Base64.encode("v=W654O28SMvjsZfNTuFWgzuZvu3svjqIPhxVvUJDjZ2Kid7Q3bTrL2BnlvV8RJNotMkS2DkqvcJesJ/wffGXL5g==".data), response.expected_server_signature);
            } catch (Error e) { fail_if_reached(e.message); }
        });
        foreach (string final_message in new string[] { "v=YmFk", "e=invalid-proof", "v=c2ln,v=c2ln", "v=c2ln,e=invalid-proof" }) {
            string message = final_message;
            add_test("reject-server-final-" + message, () => {
                try {
                    verify_server_signature(Base64.encode(message.data), "sig".data);
                    fail_if_reached("Invalid server signature accepted");
                } catch (Error e) {}
            });
        }
        add_test("sasl1-no-plain-fallback", () => { no_plain_fallback(false); });
        add_test("sasl2-no-plain-fallback", () => { no_plain_fallback(true); });
        add_test("sasl1-valid-success", () => { valid_success(false); });
        add_test("sasl2-valid-success", () => { valid_success(true); });
        add_test("reject-nul-challenge", () => {
            try {
                uint8[] bytes = "r=clientserver,s=c2FsdA==,i=1".data;
                bytes += 0;
                bytes += 'x';
                compute_challenge_response(Base64.encode(bytes), "password", "client", "user", ChecksumType.SHA256, "n,,".data);
                fail_if_reached("NUL in challenge accepted");
            } catch (Error e) {}
        });
        add_test("reject-nul-server-final", () => {
            try {
                uint8[] bytes = { 'v', '=', 'c', '2', 'l', 'n', 0, ',', 'e', '=', 'x' };
                verify_server_signature(Base64.encode(bytes), "sig".data);
                fail_if_reached("NUL in server-final accepted");
            } catch (Error e) {}
        });
        add_test("reject-invalid-outer-base64", () => {
            try {
                compute_challenge_response("!!!", "password", "client", "user", ChecksumType.SHA256, "n,,".data);
                fail_if_reached("Invalid base64 accepted");
            } catch (Error e) {}
        });
        add_test("sasl1-invalid-challenge", () => { invalid_challenge(false); });
        add_test("sasl2-invalid-challenge", () => { invalid_challenge(true); });
        add_test("sasl2-reject-forged-success", () => {
            var stream = new SaslTestStream();
            var flag = scram_flag();
            stream.add_flag(flag);
            var module = new Xep.ExtensibleSaslProfile.Module("user", "password", "test");
            bool failed = false;
            module.received_auth_failure.connect(() => { failed = true; });
            module.received_nonza(stream, new StanzaNode.build("success", "urn:xmpp:sasl:2")
                .put_node(new StanzaNode.build("authorization-identifier", "urn:xmpp:sasl:2").put_node(new StanzaNode.text("user@example.org"))));
            fail_if_not(failed);
            fail_if(flag.finished);
        });
    }

    private void expect_invalid(string challenge) {
        try {
            compute_challenge_response(Base64.encode(challenge.data), "password", "client", "user", ChecksumType.SHA256, "n,,".data);
            fail_if_reached("Invalid challenge accepted");
        } catch (Error e) {}
    }

    private Flag scram_flag() {
        var flag = new Flag();
        flag.mechanism = "SCRAM-SHA-256";
        flag.name = "user";
        flag.password = "password";
        flag.client_nonce = "client";
        flag.channel_binding = "n,,".data;
        return flag;
    }

    private void no_plain_fallback(bool sasl2) {
        var stream = new SaslTestStream();
        string ns = sasl2 ? "urn:xmpp:sasl:2" : "urn:ietf:params:xml:ns:xmpp-sasl";
        var mechanisms = new StanzaNode.build(sasl2 ? "authentication" : "mechanisms", ns);
        foreach (string mechanism in new string[] { "SCRAM-SHA-256-PLUS", "SCRAM-SHA-256", "PLAIN" }) {
            mechanisms.put_node(new StanzaNode.build("mechanism", ns).put_node(new StanzaNode.text(mechanism)));
        }
        stream.features.put_node(mechanisms);
        bool failed = false;
        if (sasl2) {
            var module = new Xep.ExtensibleSaslProfile.Module("user", "password", "test");
            module.received_auth_failure.connect(() => { failed = true; });
            module.received_features_node(stream);
        } else {
            var module = new Sasl.Module("user", "password");
            module.received_auth_failure.connect(() => { failed = true; });
            module.received_features_node(stream);
        }
        fail_if_not(failed);
        fail_if(stream.has_flag(Flag.IDENTITY));
        fail_if(stream.sent != null, "Authentication sent after binding validation failed");
    }

    private void valid_success(bool sasl2) {
        var stream = new SaslTestStream();
        var flag = scram_flag();
        flag.server_signature = "sig".data;
        stream.add_flag(flag);
        string ns = sasl2 ? "urn:xmpp:sasl:2" : "urn:ietf:params:xml:ns:xmpp-sasl";
        var node = new StanzaNode.build("success", ns);
        string verifier = Base64.encode("v=c2ln".data);
        if (sasl2) {
            node.put_node(new StanzaNode.build("additional-data", ns).put_node(new StanzaNode.text(verifier)));
            node.put_node(new StanzaNode.build("authorization-identifier", ns).put_node(new StanzaNode.text("user@example.org")));
            var module = new Xep.ExtensibleSaslProfile.Module("user", "password", "test");
            module.received_nonza(stream, node);
        } else {
            node.put_node(new StanzaNode.text(verifier));
            var module = new Sasl.Module("user", "password");
            module.received_nonza(stream, node);
        }
        fail_if_not(flag.finished);
        fail_if_not_eq_str(flag.password, null);
    }

    private void invalid_challenge(bool sasl2) {
        var stream = new SaslTestStream();
        var flag = scram_flag();
        stream.add_flag(flag);
        bool failed = false;
        string ns = sasl2 ? "urn:xmpp:sasl:2" : "urn:ietf:params:xml:ns:xmpp-sasl";
        var node = new StanzaNode.build("challenge", ns).put_node(new StanzaNode.text(Base64.encode("invalid".data)));
        if (sasl2) {
            var module = new Xep.ExtensibleSaslProfile.Module("user", "password", "test");
            module.received_auth_failure.connect(() => { failed = true; });
            module.received_nonza(stream, node);
        } else {
            var module = new Sasl.Module("user", "password");
            module.received_auth_failure.connect(() => { failed = true; });
            module.received_nonza(stream, node);
        }
        fail_if_not(failed);
        fail_if(stream.has_flag(Flag.IDENTITY));
        fail_if_not_eq_str(stream.sent.name, "abort");
        fail_if_not_eq_str(flag.password, null);
    }
}

class SaslTestStream : XmppStream {
    public StanzaNode? sent;
    public SaslTestStream() { base(remote_jid()); }
    private static Jid remote_jid() {
        try { return Jid.from_string("example.org"); }
        catch (InvalidJidError e) { assert_not_reached(); }
    }
    public override async void connect() throws IOError {}
    public override async void disconnect() throws IOError {}
    public override async StanzaNode read() throws IOError { throw new IOError.CLOSED("No input"); }
    public override void write(StanzaNode node, int io_priority = Priority.DEFAULT) { sent = node; }
    public override async void write_async(StanzaNode node, int io_priority = Priority.DEFAULT, Cancellable? cancellable = null) throws IOError { sent = node; }
    public override async void setup() throws IOError {}
}

}
