/* libgsasl.vapi
 *
 * Copyright (C) 2013  Evan Nemerson
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 * Authors:
 * 	 Evan Nemerson <evan@coeus-group.com>
 */

[CCode (cheader_filename = "gsasl.h")]
namespace Gsasl {
	namespace Version {
		[CCode (cname = "GSASL_VERSION")]
		public const string STRING;
		public const int MAJOR;
		public const int MINOR;
		public const int PATCH;
		public const int NUMBER;

		[CCode (cname = "gsasl_check_version")]
		public static unowned string check (string req_version);
	}

	public const int MIN_MECHANISM_SIZE;
	public const int MAX_MECHANISM_SIZE;
	public const string VALID_MECHANISM_CHARACTERS;

	[CCode (cname = "Gsasl_rc", cprefix = "GSASL_", has_type_id = false)]
	public enum Result {
		OK,
		NEEDS_MORE,
		UNKNOWN_MECHANISM,
		MECHANISM_CALLED_TOO_MANY_TIMES,
		MALLOC_ERROR,
		BASE64_ERROR,
		CRYPTO_ERROR,
		SASLPREP_ERROR,
		MECHANISM_PARSE_ERROR,
		AUTHENTICATION_ERROR,
		INTEGRITY_ERROR,
		NO_CLIENT_CODE,
		NO_SERVER_CODE,
		NO_CALLBACK,
		NO_ANONYMOUS_TOKEN,
		NO_AUTHID,
		NO_AUTHZID,
		NO_PASSWORD,
		NO_PASSCODE,
		NO_PIN,
		NO_SERVICE,
		NO_HOSTNAME,
		NO_CB_TLS_UNIQUE,
		NO_SAML20_IDP_IDENTIFIER,
		NO_SAML20_REDIRECT_URL,
		NO_OPENID20_REDIRECT_URL,
		GSSAPI_RELEASE_BUFFER_ERROR,
		GSSAPI_IMPORT_NAME_ERROR,
		GSSAPI_INIT_SEC_CONTEXT_ERROR,
		GSSAPI_ACCEPT_SEC_CONTEXT_ERROR,
		GSSAPI_UNWRAP_ERROR,
		GSSAPI_WRAP_ERROR,
		GSSAPI_ACQUIRE_CRED_ERROR,
		GSSAPI_DISPLAY_NAME_ERROR,
		GSSAPI_UNSUPPORTED_PROTECTION_ERROR,
		KERBEROS_V5_INIT_ERROR,
		KERBEROS_V5_INTERNAL_ERROR,
		SHISHI_ERROR,
		SECURID_SERVER_NEED_ADDITIONAL_PASSCODE,
		SECURID_SERVER_NEED_NEW_PIN,
		GSSAPI_ENCAPSULATE_TOKEN_ERROR,
		GSSAPI_DECAPSULATE_TOKEN_ERROR,
		GSSAPI_INQUIRE_MECH_FOR_SASLNAME_ERROR,
		GSSAPI_TEST_OID_SET_MEMBER_ERROR,
		GSSAPI_RELEASE_OID_SET_ERROR;

		[CCode (cname = "gsasl_strerror_name")]
		public unowned string to_string ();
		[CCode (cname = "gsasl_strerror")]
		public unowned string description ();
	}

	[CCode (cname = "Gsasl_qop", cprefix = "GSASL_QOP_", has_type_id = false)]
	public enum QualityOfProtection {
		AUTH,
		[CCode (cname = "GSASL_QOP_AUTH")]
		AUTHENTICATION,
		AUTH_INT,
		[CCode (cname = "GSASL_QOP_AUTH_INT")]
		AUTHENTICATION_INTEGRITY,
		AUTH_INT_CONF,
		[CCode (cname = "GSASL_QOP_AUTH_INT_CONF")]
		AUTHENTICATION_INTEGRITY_CONFIDENTIALITY
	}

	[CCode (cname = "Gsasl_cipher", has_type_id = false)]
	public enum Cipher {
		DES,
		3DES,
		RC4,
		RC4_40,
		RC4_56,
		AES
	}

	[Flags, CCode (cname = "Gsasl_saslprep_flags", cprefix = "GSASL_", has_type_id = false)]
	public enum PrepFlags {
		ALLOW_UNASSIGNED
	}

	[Compact, CCode (cname = "Gsasl", lower_case_cprefix = "gsasl_", destroy_function = "gsasl_done")]
	public class Context {
		private Context ();
		public static Gsasl.Result init (out Gsasl.Context ctx);
		[CCode (cname = "gsasl_callback_set")]
		public void set_callback (Gsasl.Callback cb);
		[CCode (cname = "gsasl_callback")]
		public Gsasl.Callback get_callback (Gsasl.Property prop);

		public void* callback_hook {
			[CCode (cname = "gsasl_callback_hook_set")] get;
			[CCode (cname = "gsasl_callback_hook_get")] set;
		}
		[CCode (cname = "gsasl_callback_hook_get")]
		public void* get_callback_hook ();
		[CCode (cname = "gsasl_callback_hook_set")]
		public void set_callback_hook (void* hook);

		public Gsasl.Result client_mechlist (out string mechlist);
		public Gsasl.Result client_support_p (string name);
		public unowned string client_suggest_mechanism (string mechlist);

		public Gsasl.Result server_mechlist (out string mechlist);
		public Gsasl.Result server_support_p (string name);

		public Gsasl.Result client_start (string mech);
		public Gsasl.Result server_start ();
	}

	[CCode (cname = "Gsasl_session", lower_case_cprefix = "gsasl_", destroy_function = "gsasl_finish")]
	public struct Session {
		[CCode (cname = "gsasl_client_start", instance_pos = -1)]
		public Session (Gsasl.Context context, string mech);

		public void* hook {
			[CCode (cname = "gsasl_session_hook_set")] get;
			[CCode (cname = "gsasl_session_hook_get")] set;
		}
		[CCode (cname = "gsasl_session_hook_get")]
		public void* get_hook ();
		[CCode (cname = "gsasl_session_hook_set")]
		public void set_hook (void* hook);

		[CCode (cname = "gsasl_property_set")]
		public void set_property (Gsasl.Property prop, string data);
		[CCode (cname = "gsasl_property_set_raw")]
		public void set_property_raw (Gsasl.Property prop, string data, size_t len);
		[CCode (cname = "gsasl_property_get")]
		public unowned string get_property (Gsasl.Property prop);
		[CCode (cname = "gsasl_property_fast")]
		public unowned string get_property_fast (Gsasl.Property prop);

		public Gsasl.Result step ([CCode (array_length_type = "size_t")] uint[] input, [CCode (array_length_type = "size_t")] out uint8[] output);
		public Gsasl.Result step64 (string b64input, out string b64output);

		public Gsasl.Result encode ([CCode (array_length_type = "size_t")] uint8[] input, [CCode (array_length_type = "size_t")] out uint8[] output);
		public Gsasl.Result decode ([CCode (array_length_type = "size_t")] uint8[] input, [CCode (array_length_type = "size_t")] out uint8[] output);

		public unowned string mechanism_name ();
	}

	[CCode (cname = "Gsasl_property", cprefix = "GSASL_", has_type_id = false)]
	public enum Property {
		AUTHID,
		AUTHZID,
		PASSWORD,
		ANONYMOUS_TOKEN,
		SERVICE,
		HOSTNAME,
		GSSAPI_DISPLAY_NAME,
		PASSCODE,
		SUGGESTED_PIN,
		PIN,
		REALM,
		DIGEST_MD5_HASHED_PASSWORD,
		QOPS,
		QOP,
		SCRAM_ITER,
		SCRAM_SALT,
		SCRAM_SALTED_PASSWORD,
		CB_TLS_UNIQUE,
		SAML20_IDP_IDENTIFIER,
		SAML20_REDIRECT_URL,
		OPENID20_REDIRECT_URL,
		OPENID20_OUTCOME_DATA,
		SAML20_AUTHENTICATE_IN_BROWSER,
		OPENID20_AUTHENTICATE_IN_BROWSER,
		VALIDATE_SIMPLE,
		VALIDATE_EXTERNAL,
		VALIDATE_ANONYMOUS,
		VALIDATE_GSSAPI,
		VALIDATE_SECURID,
		VALIDATE_SAML20,
		VALIDATE_OPENID20
	}

	[CCode (cname = "Gsasl_callback_function", has_target = false)]
	public delegate Gsasl.Result Callback (Gsasl.Context ctx, Gsasl.Session sctx, Gsasl.Property prop);

	[CCode (cname = "gsasl_saslprep")]
	public static Gsasl.Result prep (string in, Gsasl.PrepFlags flags, out string @out, out Gsasl.Result stringpreprc = null);

	public static Gsasl.Result simple_getpass (string filename, string username, out string key);
	public static Gsasl.Result base64_to ([CCode (array_length_type = "size_t")] uint[] in, [CCode (array_length_type = "size_t")] out uint8[] @out);
	public static Gsasl.Result base64_from ([CCode (array_length_type = "size_t")] uint[] in, [CCode (array_length_type = "size_t")] out uint8[] @out);
	public static Gsasl.Result nonce ([CCode (array_length_type = "size_t")] uint8[] data);
	public static Gsasl.Result md5 ([CCode (array_length_type = "size_t")] uint8[] in, out uint8 @out[16]);
	public static Gsasl.Result hmac_md5 ([CCode (array_length_type = "size_t")] uint8[] key, [CCode (array_length_type = "size_t")] uint8[] in, uint8 outhash[16]);
	public static Gsasl.Result sha1 ([CCode (array_length_type = "size_t")] uint8[] in, out uint8 @out[20]);
	public static Gsasl.Result hmac_sha1 ([CCode (array_length_type = "size_t")] uint8[] key, [CCode (array_length_type = "size_t")] uint8[] in, uint8 outhash[20]);
}
