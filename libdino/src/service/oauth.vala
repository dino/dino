using Gee;
using Soup;
using Xmpp;

namespace Dino {

public class OAuth : Object {
    public const string SCOPE = "xmpp:client:normal";
    private const string REDIRECT_PATH = "/oauth";
    private const string CLIENT_NAME = "Dino";
    private const string CLIENT_URI = "https://dino.im/";
    private const string LOGO_URI = "https://dino.im/img/logo.svg";

    public class Token {
        public string access_token;
        public string? refresh_token;
        public string? token_type;
        public int64 expires_in;
        public string? issuer;
        public string? token_endpoint;
        public string? client_id;
        public string? client_secret;
    }

    private class Metadata {
        public string issuer;
        public string authorization_endpoint;
        public string token_endpoint;
        public string? registration_endpoint;
    }

    private class ClientRegistration {
        public string client_id;
        public string? client_secret;
        public string redirect_uri;
        public string auth_method;
    }

    public string? last_error;

    private Database db;
    private Session session;

    public OAuth(Database db) {
        this.db = db;
        session = new Session();
        session.timeout = 20;
    }

    public async Token? authorize(Jid jid, Register.OAuthDiscovery discovery) {
        last_error = null;

        Metadata? metadata = yield fetch_metadata(discovery.url);
        if (metadata == null) return null;

        string scope = discovery.scope != null && discovery.scope.length > 0 ? discovery.scope : SCOPE;
        string setting_key = client_setting_key(metadata.issuer);
        string? stored_client = get_setting(setting_key);
        ClientRegistration? client = stored_client != null ? parse_client(stored_client) : null;

        Soup.Server server = new Soup.Server((string) null);
        bool listening = false;

        if (client != null) {
            int listen_port = 0;
            try {
                Uri redirect_uri = Uri.parse(client.redirect_uri, UriFlags.NONE);
                string? host = redirect_uri.get_host();
                if (redirect_uri.get_scheme() == "http" && host != null &&
                        (host == "127.0.0.1" || host == "::1" || host == "localhost")) {
                    listen_port = redirect_uri.get_port();
                }
            } catch (Error e) {
                listen_port = 0;
            }
            if (listen_port > 0) {
                try {
                    listening = server.listen_local((uint) listen_port, 0);
                } catch (Error e) {
                    listening = false;
                }
            }
            if (!listening) client = null; // Invalid or unavailable: register a fresh client below.
        }

        if (!listening) {
            try {
                listening = server.listen_local(0, 0);
            } catch (Error e) {
                last_error = _("Could not start the local OAuth redirect server: %s").printf(e.message);
                return null;
            }
            if (!listening) {
                last_error = _("Could not start the local OAuth redirect server");
                return null;
            }
        }

        if (client == null) {
            string? redirect_uri = server_redirect_uri(server);
            if (redirect_uri == null) {
                server.disconnect();
                return null;
            }
            if (metadata.registration_endpoint == null) {
                last_error = _("OAuth provider does not support dynamic client registration");
                server.disconnect();
                return null;
            }
            client = yield register_client(metadata.registration_endpoint, redirect_uri);
            if (client == null) {
                server.disconnect();
                return null;
            }
            set_setting(setting_key, serialize_client(client));
        }

        string verifier = "%s%s".printf(Xmpp.random_uuid().replace("-", ""), Xmpp.random_uuid().replace("-", ""));
        string state = Xmpp.random_uuid();
        string code_challenge = base64url(Checksum.compute_for_data(ChecksumType.SHA256, verifier.data));
        string? code = null;
        string? redirect_error = null;
        bool responded = false;
        SourceFunc callback = authorize.callback;

        server.add_handler(REDIRECT_PATH, (srv, msg, path, query) => {
            if (responded) {
                msg.set_status((uint) Soup.Status.BAD_REQUEST, null);
                return;
            }
            responded = true;
            string? received_state = query != null ? query.lookup("state") : null;
            if (received_state == null || received_state != state) {
                redirect_error = _("Invalid OAuth state");
            } else {
                code = query != null ? query.lookup("code") : null;
                redirect_error = query != null ? query.lookup("error") : null;
                string? error_description = query != null ? query.lookup("error_description") : null;
                if (redirect_error != null && error_description != null) {
                    redirect_error = error_description;
                }
                if (code == null && redirect_error == null) {
                    redirect_error = _("OAuth provider did not return an authorization code");
                }
            }

            string html = redirect_error == null
                ? "<html><body><h1>Sign-in complete</h1><p>You can close this window and return to Dino.</p></body></html>"
                : "<html><body><h1>Sign-in failed</h1><p>You can close this window and return to Dino.</p></body></html>";
            msg.set_status(redirect_error == null ? (uint) Soup.Status.OK : (uint) Soup.Status.BAD_REQUEST, null);
            msg.set_response("text/html", Soup.MemoryUse.COPY, html.data);
            if (callback != null) Idle.add((owned)callback);
        });

        uint timeout_id = Timeout.add_seconds(300, () => {
            if (!responded) {
                redirect_error = _("OAuth authorization timed out");
                responded = true;
                if (callback != null) Idle.add((owned)callback);
            }
            return false;
        });

        var parameters = new GLib.HashTable<string, string>(str_hash, str_equal);
        parameters.set("response_type", "code");
        parameters.set("client_id", client.client_id);
        parameters.set("redirect_uri", client.redirect_uri);
        parameters.set("scope", scope);
        parameters.set("state", state);
        parameters.set("code_challenge", code_challenge);
        parameters.set("code_challenge_method", "S256");
        parameters.set("prompt", "login");
        parameters.set("login_hint", jid.localpart);
        string authorization_url = metadata.authorization_endpoint +
            (metadata.authorization_endpoint.contains("?") ? "&" : "?") + Soup.Form.encode_hash(parameters);

        try {
            AppInfo.launch_default_for_uri(authorization_url, null);
        } catch (Error e) {
            Source.remove(timeout_id);
            server.disconnect();
            last_error = _("Could not open the OAuth authorization page: %s").printf(e.message);
            return null;
        }

        yield;

        Source.remove(timeout_id);
        server.disconnect();

        if (code == null) {
            last_error = redirect_error != null ? redirect_error : _("OAuth authorization failed");
            return null;
        }

        var form = new GLib.HashTable<string, string>(str_hash, str_equal);
        form.set("grant_type", "authorization_code");
        form.set("code", code);
        form.set("redirect_uri", client.redirect_uri);
        form.set("code_verifier", verifier);

        string? authorization = null;
        if (client.auth_method == "client_secret_basic") {
            string credentials = "%s:%s".printf(client.client_id, client.client_secret ?? "");
            authorization = "Basic " + Base64.encode(credentials.data);
        } else {
            form.set("client_id", client.client_id);
            if (client.auth_method == "client_secret_post" && client.client_secret != null) {
                form.set("client_secret", client.client_secret);
            }
        }

        var message = new Soup.Message.from_encoded_form("POST", metadata.token_endpoint, Soup.Form.encode_hash(form));
        message.request_headers.append("Accept", "application/json");
        if (authorization != null) message.request_headers.append("Authorization", authorization);

        string? token_response = yield send_message(message);
        if (token_response == null) return null;
        Token? token = parse_token(token_response);
        if (token == null) {
            last_error = _("OAuth provider returned an invalid token response");
            return null;
        }
        token.issuer = metadata.issuer;
        token.token_endpoint = metadata.token_endpoint;
        token.client_id = client.client_id;
        token.client_secret = client.client_secret;
        return token;
    }

    private async Metadata? fetch_metadata(string url) {
        string? body = yield read_url(url);
        if (body == null) return null;
        Json.Object? object = parse_object(body);
        if (object == null) {
            last_error = _("OAuth discovery document is not valid JSON");
            return null;
        }

        string? issuer = json_string(object, "issuer");
        string? authorization_endpoint = json_string(object, "authorization_endpoint");
        string? token_endpoint = json_string(object, "token_endpoint");
        if (issuer == null || authorization_endpoint == null || token_endpoint == null) {
            last_error = _("OAuth discovery document is missing required fields");
            return null;
        }
        if (!is_https_url(authorization_endpoint) || !is_https_url(token_endpoint)) {
            last_error = _("OAuth endpoints must use HTTPS");
            return null;
        }

        var metadata = new Metadata() {
            issuer=issuer, authorization_endpoint=authorization_endpoint, token_endpoint=token_endpoint
        };
        metadata.registration_endpoint = json_string(object, "registration_endpoint");
        if (metadata.registration_endpoint != null && !is_https_url(metadata.registration_endpoint)) {
            metadata.registration_endpoint = null;
        }
        return metadata;
    }

    private async ClientRegistration? register_client(string endpoint, string redirect_uri) {
        string body = "{\"redirect_uris\":[%s],".printf(json_quote(redirect_uri)) +
            "\"client_name\":%s,".printf(json_quote(CLIENT_NAME)) +
            "\"client_uri\":%s,".printf(json_quote(CLIENT_URI)) +
            "\"logo_uri\":%s,".printf(json_quote(LOGO_URI)) +
            "\"application_type\":\"native\"," +
            "\"grant_types\":[\"authorization_code\"]," +
            "\"response_types\":[\"code\"]," +
            "\"software_version\":%s}".printf(json_quote(get_version()));

        var message = new Soup.Message("POST", endpoint);
        message.request_headers.append("Accept", "application/json");
        message.set_request_body_from_bytes("application/json", new Bytes(body.data));
        string? response = yield send_message(message);
        if (response == null) return null;

        Json.Object? object = parse_object(response);
        if (object == null) {
            last_error = _("OAuth client registration response is not valid JSON");
            return null;
        }
        string? client_id = json_string(object, "client_id");
        if (client_id == null) {
            last_error = _("OAuth provider did not return a client id");
            return null;
        }
        string? client_secret = json_string(object, "client_secret");
        string effective_auth_method = json_string(object, "token_endpoint_auth_method") ??
                (client_secret != null ? "client_secret_basic" : "none");
        return new ClientRegistration() {
            client_id=client_id, client_secret=client_secret, redirect_uri=redirect_uri, auth_method=effective_auth_method
        };
    }

    private async string? read_url(string url) {
        var message = new Soup.Message("GET", url);
        message.request_headers.append("Accept", "application/json");
        return yield send_message(message);
    }

    private async string? send_message(Soup.Message message) {
        try {
            Bytes bytes = yield session.send_and_read_async(message, GLib.Priority.DEFAULT, null);
            if (message.status_code < 200 || message.status_code >= 300) {
                last_error = _("OAuth request failed with status %u").printf(message.status_code);
                return null;
            }
            return (string) bytes.get_data();
        } catch (Error e) {
            last_error = e.message;
            return null;
        }
    }

    private static Token? parse_token(string body) {
        Json.Object? object = parse_object(body);
        if (object == null) return null;
        string? access_token = json_string(object, "access_token");
        if (access_token == null) return null;

        int64 expires_in = 0;
        Json.Node? expires_node = object.get_member("expires_in");
        if (expires_node != null && expires_node.get_node_type() == Json.NodeType.VALUE) {
            if (expires_node.get_value_type() == typeof(string)) {
                string? expires_string = expires_node.get_string();
                if (expires_string != null) expires_in = int64.parse(expires_string);
            } else {
                expires_in = expires_node.get_int();
            }
        }

        return new Token() {
            access_token=access_token,
            refresh_token=json_string(object, "refresh_token"),
            token_type=json_string(object, "token_type"),
            expires_in=expires_in
        };
    }

    private static Json.Object? parse_object(string body) {
        try {
            var parser = new Json.Parser();
            parser.load_from_data(body);
            Json.Node? root = parser.get_root();
            return root != null ? root.get_object() : null;
        } catch (Error e) {
            warning("Failed to parse OAuth JSON: %s", e.message);
            return null;
        }
    }

    private static string? json_string(Json.Object object, string member) {
        if (!object.has_member(member)) return null;
        Json.Node? node = object.get_member(member);
        if (node == null || node.get_node_type() != Json.NodeType.VALUE) return null;
        if (node.get_value_type() != typeof(string)) return null;
        return node.get_string();
    }

    private static string json_quote(string value) {
        return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    private static bool is_https_url(string value) {
        try {
            Uri uri = Uri.parse(value, UriFlags.NONE);
            return uri.get_scheme() == "https" && uri.get_host() != null;
        } catch (Error e) {
            return false;
        }
    }

    private static string base64url(string data) {
        string encoded = Base64.encode(data.data);
        return encoded.replace("+", "-").replace("/", "_").replace("=", "");
    }

    private string? server_redirect_uri(Soup.Server server) {
        SList<Uri> uris = server.get_uris();
        if (uris.length() == 0) {
            last_error = _("Could not determine the local OAuth redirect URI");
            return null;
        }
        Uri uri = uris.data;
        string uri_string = uri.to_string();
        if (uri_string.has_suffix("/")) uri_string = uri_string.substring(0, uri_string.length - 1);
        return uri_string + REDIRECT_PATH;
    }

    private static string client_setting_key(string issuer) {
        return "oauth-client-" + Checksum.compute_for_data(ChecksumType.SHA256, issuer.data);
    }

    private string? get_setting(string key) {
        var row = db.settings.select({db.settings.value})
                .with(db.settings.key, "=", key)
                .single()
                .row();
        if (row.is_present()) return row[db.settings.value];
        return null;
    }

    private void set_setting(string key, string value) {
        db.settings.upsert()
                .value(db.settings.key, key, true)
                .value(db.settings.value, value)
                .perform();
    }

    private static ClientRegistration? parse_client(string body) {
        Json.Object? object = parse_object(body);
        if (object == null) return null;
        string? client_id = json_string(object, "client_id");
        string? redirect_uri = json_string(object, "redirect_uri");
        if (client_id == null || redirect_uri == null) return null;
        string? client_secret = json_string(object, "client_secret");
        string effective_auth_method = json_string(object, "auth_method") ??
                (client_secret != null ? "client_secret_basic" : "none");
        return new ClientRegistration() {
            client_id=client_id, client_secret=client_secret, redirect_uri=redirect_uri, auth_method=effective_auth_method
        };
    }

    private static string serialize_client(ClientRegistration client) {
        string body = "{\"client_id\":%s,".printf(json_quote(client.client_id)) +
            "\"redirect_uri\":%s,".printf(json_quote(client.redirect_uri)) +
            "\"auth_method\":%s".printf(json_quote(client.auth_method));
        if (client.client_secret != null) {
            body += ",\"client_secret\":" + json_quote(client.client_secret);
        }
        return body + "}";
    }
}

}
