/* gcrypt.vapi
 *
 * Copyright:
 *   2008 Jiqing Qiang
 *   2008, 2010, 2012-2013 Evan Nemerson
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jiqing Qiang <jiqing.qiang@gmail.com>
 * 	Evan Nemerson <evan@coeus-group.com>
 */


[CCode (cheader_filename = "gcrypt.h", lower_case_cprefix = "gcry_")]
namespace GCrypt {
	[CCode (cname = "gpg_err_source_t", cprefix = "GPG_ERR_SOURCE_")]
	public enum ErrorSource {
		UNKNOWN,
		GCRYPT,
		GPG,
		GPGSM,
		GPGAGENT,
		PINENTRY,
		SCD,
		GPGME,
		KEYBOX,
		KSBA,
		DIRMNGR,
		GSTI,
		ANY,
		USER_1,
		USER_2,
		USER_3,
		USER_4,

		/* This is one more than the largest allowed entry.  */
		DIM
	}

	[CCode (cname = "gpg_err_code_t", cprefix = "GPG_ERR_")]
	public enum ErrorCode {
		NO_ERROR,
		GENERAL,
		UNKNOWN_PACKET,
		UNKNOWN_VERSION,
		PUBKEY_ALGO,
		DIGEST_ALGO,
		BAD_PUBKEY,
		BAD_SECKEY,
		BAD_SIGNATURE,
		NO_PUBKEY,
		CHECKSUM,
		BAD_PASSPHRASE,
		CIPHER_ALGO,
		KEYRING_OPEN,
		INV_PACKET,
		INV_ARMOR,
		NO_USER_ID,
		NO_SECKEY,
		WRONG_SECKEY,
		BAD_KEY,
		COMPR_ALGO,
		NO_PRIME,
		NO_ENCODING_METHOD,
		NO_ENCRYPTION_SCHEME,
		NO_SIGNATURE_SCHEME,
		INV_ATTR,
		NO_VALUE,
		NOT_FOUND,
		VALUE_NOT_FOUND,
		SYNTAX,
		BAD_MPI,
		INV_PASSPHRASE,
		SIG_CLASS,
		RESOURCE_LIMIT,
		INV_KEYRING,
		TRUSTDB,
		BAD_CERT,
		INV_USER_ID,
		UNEXPECTED,
		TIME_CONFLICT,
		KEYSERVER,
		WRONG_PUBKEY_ALGO,
		TRIBUTE_TO_D_A,
		WEAK_KEY,
		INV_KEYLEN,
		INV_ARG,
		BAD_URI,
		INV_URI,
		NETWORK,
		UNKNOWN_HOST,
		SELFTEST_FAILED,
		NOT_ENCRYPTED,
		NOT_PROCESSED,
		UNUSABLE_PUBKEY,
		UNUSABLE_SECKEY,
		INV_VALUE,
		BAD_CERT_CHAIN,
		MISSING_CERT,
		NO_DATA,
		BUG,
		NOT_SUPPORTED,
		INV_OP,
		TIMEOUT,
		INTERNAL,
		EOF_GCRYPT,
		INV_OBJ,
		TOO_SHORT,
		TOO_LARGE,
		NO_OBJ,
		NOT_IMPLEMENTED,
		CONFLICT,
		INV_CIPHER_MODE,
		INV_FLAG,
		INV_HANDLE,
		TRUNCATED,
		INCOMPLETE_LINE,
		INV_RESPONSE,
		NO_AGENT,
		AGENT,
		INV_DATA,
		ASSUAN_SERVER_FAULT,
		ASSUAN,
		INV_SESSION_KEY,
		INV_SEXP,
		UNSUPPORTED_ALGORITHM,
		NO_PIN_ENTRY,
		PIN_ENTRY,
		BAD_PIN,
		INV_NAME,
		BAD_DATA,
		INV_PARAMETER,
		WRONG_CARD,
		NO_DIRMNGR,
		DIRMNGR,
		CERT_REVOKED,
		NO_CRL_KNOWN,
		CRL_TOO_OLD,
		LINE_TOO_LONG,
		NOT_TRUSTED,
		CANCELED,
		BAD_CA_CERT,
		CERT_EXPIRED,
		CERT_TOO_YOUNG,
		UNSUPPORTED_CERT,
		UNKNOWN_SEXP,
		UNSUPPORTED_PROTECTION,
		CORRUPTED_PROTECTION,
		AMBIGUOUS_NAME,
		CARD,
		CARD_RESET,
		CARD_REMOVED,
		INV_CARD,
		CARD_NOT_PRESENT,
		NO_PKCS15_APP,
		NOT_CONFIRMED,
		CONFIGURATION,
		NO_POLICY_MATCH,
		INV_INDEX,
		INV_ID,
		NO_SCDAEMON,
		SCDAEMON,
		UNSUPPORTED_PROTOCOL,
		BAD_PIN_METHOD,
		CARD_NOT_INITIALIZED,
		UNSUPPORTED_OPERATION,
		WRONG_KEY_USAGE,
		NOTHING_FOUND,
		WRONG_BLOB_TYPE,
		MISSING_VALUE,
		HARDWARE,
		PIN_BLOCKED,
		USE_CONDITIONS,
		PIN_NOT_SYNCED,
		INV_CRL,
		BAD_BER,
		INV_BER,
		ELEMENT_NOT_FOUND,
		IDENTIFIER_NOT_FOUND,
		INV_TAG,
		INV_LENGTH,
		INV_KEYINFO,
		UNEXPECTED_TAG,
		NOT_DER_ENCODED,
		NO_CMS_OBJ,
		INV_CMS_OBJ,
		UNKNOWN_CMS_OBJ,
		UNSUPPORTED_CMS_OBJ,
		UNSUPPORTED_ENCODING,
		UNSUPPORTED_CMS_VERSION,
		UNKNOWN_ALGORITHM,
		INV_ENGINE,
		PUBKEY_NOT_TRUSTED,
		DECRYPT_FAILED,
		KEY_EXPIRED,
		SIG_EXPIRED,
		ENCODING_PROBLEM,
		INV_STATE,
		DUP_VALUE,
		MISSING_ACTION,
		MODULE_NOT_FOUND,
		INV_OID_STRING,
		INV_TIME,
		INV_CRL_OBJ,
		UNSUPPORTED_CRL_VERSION,
		INV_CERT_OBJ,
		UNKNOWN_NAME,
		LOCALE_PROBLEM,
		NOT_LOCKED,
		PROTOCOL_VIOLATION,
		INV_MAC,
		INV_REQUEST,
		UNKNOWN_EXTN,
		UNKNOWN_CRIT_EXTN,
		LOCKED,
		UNKNOWN_OPTION,
		UNKNOWN_COMMAND,
		BUFFER_TOO_SHORT,
		SEXP_INV_LEN_SPEC,
		SEXP_STRING_TOO_LONG,
		SEXP_UNMATCHED_PAREN,
		SEXP_NOT_CANONICAL,
		SEXP_BAD_CHARACTER,
		SEXP_BAD_QUOTATION,
		SEXP_ZERO_PREFIX,
		SEXP_NESTED_DH,
		SEXP_UNMATCHED_DH,
		SEXP_UNEXPECTED_PUNC,
		SEXP_BAD_HEX_CHAR,
		SEXP_ODD_HEX_NUMBERS,
		SEXP_BAD_OCT_CHAR,
		ASS_GENERAL,
		ASS_ACCEPT_FAILED,
		ASS_CONNECT_FAILED,
		ASS_INV_RESPONSE,
		ASS_INV_VALUE,
		ASS_INCOMPLETE_LINE,
		ASS_LINE_TOO_LONG,
		ASS_NESTED_COMMANDS,
		ASS_NO_DATA_CB,
		ASS_NO_INQUIRE_CB,
		ASS_NOT_A_SERVER,
		ASS_NOT_A_CLIENT,
		ASS_SERVER_START,
		ASS_READ_ERROR,
		ASS_WRITE_ERROR,
		ASS_TOO_MUCH_DATA,
		ASS_UNEXPECTED_CMD,
		ASS_UNKNOWN_CMD,
		ASS_SYNTAX,
		ASS_CANCELED,
		ASS_NO_INPUT,
		ASS_NO_OUTPUT,
		ASS_PARAMETER,
		ASS_UNKNOWN_INQUIRE,
		USER_1,
		USER_2,
		USER_3,
		USER_4,
		USER_5,
		USER_6,
		USER_7,
		USER_8,
		USER_9,
		USER_10,
		USER_11,
		USER_12,
		USER_13,
		USER_14,
		USER_15,
		USER_16,
		MISSING_ERRNO,
		UNKNOWN_ERRNO,
		EOF,

		E2BIG,
		EACCES,
		EADDRINUSE,
		EADDRNOTAVAIL,
		EADV,
		EAFNOSUPPORT,
		EAGAIN,
		EALREADY,
		EAUTH,
		EBACKGROUND,
		EBADE,
		EBADF,
		EBADFD,
		EBADMSG,
		EBADR,
		EBADRPC,
		EBADRQC,
		EBADSLT,
		EBFONT,
		EBUSY,
		ECANCELED,
		ECHILD,
		ECHRNG,
		ECOMM,
		ECONNABORTED,
		ECONNREFUSED,
		ECONNRESET,
		ED,
		EDEADLK,
		EDEADLOCK,
		EDESTADDRREQ,
		EDIED,
		EDOM,
		EDOTDOT,
		EDQUOT,
		EEXIST,
		EFAULT,
		EFBIG,
		EFTYPE,
		EGRATUITOUS,
		EGREGIOUS,
		EHOSTDOWN,
		EHOSTUNREACH,
		EIDRM,
		EIEIO,
		EILSEQ,
		EINPROGRESS,
		EINTR,
		EINVAL,
		EIO,
		EISCONN,
		EISDIR,
		EISNAM,
		EL2HLT,
		EL2NSYNC,
		EL3HLT,
		EL3RST,
		ELIBACC,
		ELIBBAD,
		ELIBEXEC,
		ELIBMAX,
		ELIBSCN,
		ELNRNG,
		ELOOP,
		EMEDIUMTYPE,
		EMFILE,
		EMLINK,
		EMSGSIZE,
		EMULTIHOP,
		ENAMETOOLONG,
		ENAVAIL,
		ENEEDAUTH,
		ENETDOWN,
		ENETRESET,
		ENETUNREACH,
		ENFILE,
		ENOANO,
		ENOBUFS,
		ENOCSI,
		ENODATA,
		ENODEV,
		ENOENT,
		ENOEXEC,
		ENOLCK,
		ENOLINK,
		ENOMEDIUM,
		ENOMEM,
		ENOMSG,
		ENONET,
		ENOPKG,
		ENOPROTOOPT,
		ENOSPC,
		ENOSR,
		ENOSTR,
		ENOSYS,
		ENOTBLK,
		ENOTCONN,
		ENOTDIR,
		ENOTEMPTY,
		ENOTNAM,
		ENOTSOCK,
		ENOTSUP,
		ENOTTY,
		ENOTUNIQ,
		ENXIO,
		EOPNOTSUPP,
		EOVERFLOW,
		EPERM,
		EPFNOSUPPORT,
		EPIPE,
		EPROCLIM,
		EPROCUNAVAIL,
		EPROGMISMATCH,
		EPROGUNAVAIL,
		EPROTO,
		EPROTONOSUPPORT,
		EPROTOTYPE,
		ERANGE,
		EREMCHG,
		EREMOTE,
		EREMOTEIO,
		ERESTART,
		EROFS,
		ERPCMISMATCH,
		ESHUTDOWN,
		ESOCKTNOSUPPORT,
		ESPIPE,
		ESRCH,
		ESRMNT,
		ESTALE,
		ESTRPIPE,
		ETIME,
		ETIMEDOUT,
		ETOOMANYREFS,
		ETXTBSY,
		EUCLEAN,
		EUNATCH,
		EUSERS,
		EWOULDBLOCK,
		EXDEV,
		EXFULL,

		/* This is one more than the largest allowed entry.  */
		CODE_DIM
	}

	[CCode (cname = "gcry_error_t", cprefix = "gpg_err_")]
	public struct Error : uint {
		[CCode (cname = "gcry_err_make")]
		public Error (ErrorSource source, ErrorCode code);
		[CCode (cname = "gcry_err_make_from_errno")]
		public Error.from_errno (ErrorSource source, int err);
		public ErrorCode code ();
		public ErrorSource source ();

		[CCode (cname = "gcry_strerror")]
		public unowned string to_string ();

		[CCode (cname = "gcry_strsource")]
		public unowned string source_to_string ();
	}

	[CCode (cname = "enum gcry_ctl_cmds", cprefix = "GCRYCTL_")]
	public enum ControlCommand {
		SET_KEY,
		SET_IV,
		CFB_SYNC,
		RESET,
		FINALIZE,
		GET_KEYLEN,
		GET_BLKLEN,
		TEST_ALGO,
		IS_SECURE,
		GET_ASNOID,
		ENABLE_ALGO,
		DISABLE_ALGO,
		DUMP_RANDOM_STATS,
		DUMP_SECMEM_STATS,
		GET_ALGO_NPKEY,
		GET_ALGO_NSKEY,
		GET_ALGO_NSIGN,
		GET_ALGO_NENCR,
		SET_VERBOSITY,
		SET_DEBUG_FLAGS,
		CLEAR_DEBUG_FLAGS,
		USE_SECURE_RNDPOOL,
		DUMP_MEMORY_STATS,
		INIT_SECMEM,
		TERM_SECMEM,
		DISABLE_SECMEM_WARN,
		SUSPEND_SECMEM_WARN,
		RESUME_SECMEM_WARN,
		DROP_PRIVS,
		ENABLE_M_GUARD,
		START_DUMP,
		STOP_DUMP,
		GET_ALGO_USAGE,
		IS_ALGO_ENABLED,
		DISABLE_INTERNAL_LOCKING,
		DISABLE_SECMEM,
		INITIALIZATION_FINISHED,
		INITIALIZATION_FINISHED_P,
		ANY_INITIALIZATION_P,
		SET_CBC_CTS,
		SET_CBC_MAC,
		SET_CTR,
		ENABLE_QUICK_RANDOM,
		SET_RANDOM_SEED_FILE,
		UPDATE_RANDOM_SEED_FILE,
		SET_THREAD_CBS,
		FAST_POLL
	}
	public Error control (ControlCommand cmd, ...);

	[CCode (lower_case_cname = "cipher_")]
	namespace Cipher {
		[CCode (cname = "enum gcry_cipher_algos", cprefix = "GCRY_CIPHER_")]
		public enum Algorithm {
			NONE,
			IDEA,
			3DES,
			CAST5,
			BLOWFISH,
			SAFER_SK128,
			DES_SK,
			AES,
			AES128,
			RIJNDAEL,
			RIJNDAEL128,
			AES192,
			RIJNDAEL192,
			AES256,
			RIJNDAEL256,
			TWOFISH,
			TWOFISH128,
			ARCFOUR,
			DES,
			SERPENT128,
			SERPENT192,
			SERPENT256,
			RFC2268_40,
			RFC2268_128,
			SEED,
			CAMELLIA128,
			CAMELLIA192,
			CAMELLIA256,
			SALSA20,
			SALSA20R12,
			GOST28147,
			CHACHA20;

			[CCode (cname = "gcry_cipher_algo_info")]
			public Error info (ControlCommand what, ref uchar[] buffer);
			[CCode (cname = "gcry_cipher_algo_name")]
			public unowned string to_string ();
			[CCode (cname = "gcry_cipher_map_name")]
			public static Algorithm from_string (string name);
			[CCode (cname = "gcry_cipher_map_oid")]
			public static Algorithm from_oid (string oid);
		}

		[CCode (cname = "enum gcry_cipher_modes", cprefix = "GCRY_CIPHER_MODE_")]
		public enum Mode {
			NONE, /* No mode specified */
			ECB, /* Electronic Codebook */
			CFB, /* Cipher Feedback */
			CBC, /* Cipher Block Chaining */
			STREAM, /* Used with stream ciphers */
			OFB, /* Output Feedback */
			CTR, /* Counter */
			AESWRAP, /* AES-WRAP algorithm */
			CCM, /* Counter with CBC-MAC */
			GCM, /* Galois/Counter Mode */
			POLY1305, /* Poly1305 based AEAD mode */
			OCB, /* OCB3 mode */
			CFB8, /* Cipher Feedback /* Poly1305 based AEAD mode. */
			XTS; /* XTS mode */

			public unowned string to_string () {
				switch (this) {
					case ECB: return "ECB";
					case CFB: return "CFB";
					case CBC: return "CBC";
					case STREAM: return "STREAM";
					case OFB: return "OFB";
					case CTR: return "CTR";
					case AESWRAP: return "AESWRAP";
					case GCM: return "GCM";
					case POLY1305: return "POLY1305";
					case OCB: return "OCB";
					case CFB8: return "CFB8";
					case XTS: return "XTS";
				}
				return "NONE";
			}

			public static Mode from_string (string name) {
				switch (name) {
					case "ECB": return ECB;
					case "CFB": return CFB;
					case "CBC": return CBC;
					case "STREAM": return STREAM;
					case "OFB": return OFB;
					case "CTR": return CTR;
					case "AESWRAP": return AESWRAP;
					case "GCM": return GCM;
					case "POLY1305": return POLY1305;
					case "OCB": return OCB;
					case "CFB8": return CFB8;
					case "XTS": return XTS;
				}
				return NONE;
			}
		}

		[CCode (cname = "enum gcry_cipher_flags", cprefix = "GCRY_CIPHER_")]
		public enum Flag {
			SECURE,  /* Allocate in secure memory. */
			ENABLE_SYNC,  /* Enable CFB sync mode. */
			CBC_CTS,  /* Enable CBC cipher text stealing (CTS). */
			CBC_MAC   /* Enable CBC message auth. code (MAC). */
		}
		[Compact]
		[CCode (cname = "gcry_cipher_hd_t", lower_case_cprefix = "gcry_cipher_", free_function = "gcry_cipher_close")]
		public class Cipher {
			public static Error open (out Cipher cipher, Algorithm algo, Mode mode, Flag flags);
			public void close ();
			[CCode (cname = "gcry_cipher_ctl")]
			public Error control (ControlCommand cmd, uchar[] buffer);
			public Error info (ControlCommand what, ref uchar[] buffer);

			public Error encrypt (uchar[] out_buffer, uchar[] in_buffer);
			public Error decrypt (uchar[] out_buffer, uchar[] in_buffer);

			[CCode (cname = "gcry_cipher_setkey")]
			public Error set_key (uchar[] key_data);
			[CCode (cname = "gcry_cipher_setiv")]
			public Error set_iv (uchar[] iv_data);
			[CCode (cname = "gcry_cipher_setctr")]
			public Error set_counter_vector (uchar[] counter_vector);

			[CCode (cname = "gcry_cipher_gettag")]
			public Error get_tag(uchar[] out_buffer);
			[CCode (cname = "gcry_cipher_checktag")]
			public Error check_tag(uchar[] in_buffer);

			public Error reset ();
			public Error sync ();
		}
	}

	[Compact, CCode (cname = "struct gcry_md_handle", cprefix = "gcry_md_", free_function = "gcry_md_close")]
	public class Hash {
		[CCode (cname = "enum gcry_md_algos", cprefix = "GCRY_MD_")]
		public enum Algorithm {
			NONE,
			SHA1,
			RMD160,
			MD5,
			MD4,
			MD2,
			TIGER,
			TIGER1,
			TIGER2,
			HAVAL,
			SHA224,
			SHA256,
			SHA384,
			SHA512,
			SHA3_224,
			SHA3_256,
			SHA3_384,
			SHA3_512,
			SHAKE128,
			SHAKE256,
			CRC32,
			CRC32_RFC1510,
			CRC24_RFC2440,
			WHIRLPOOL,
			GOSTR3411_94,
			STRIBOG256,
			STRIBOG512;

			[CCode (cname = "gcry_md_get_algo_dlen")]
			public size_t get_digest_length ();
			[CCode (cname = "gcry_md_algo_info")]
			public Error info (ControlCommand what, ref uchar[] buffer);
			[CCode (cname = "gcry_md_algo_name")]
			public unowned string to_string ();
			[CCode (cname = "gcry_md_map_name")]
			public static Algorithm from_string (string name);
			[CCode (cname = "gcry_md_test_algo")]
			public Error is_available ();
			[CCode (cname = "gcry_md_get_asnoid")]
			public Error get_oid (uchar[] buffer);
		}

		[CCode (cname = "enum gcry_md_flags", cprefix = "GCRY_MD_FLAG_")]
		public enum Flag {
			SECURE,
			HMAC,
			BUGEMU1
		}

		public static Error open (out Hash hash, Algorithm algo, Flag flag);
		public void close ();
		public Error enable (Algorithm algo);
		[CCode (instance_pos = -1)]
		public Error copy (out Hash dst);
		public void reset ();
		[CCode (cname = "enum gcry_md_ctl")]
		public Error control (ControlCommand cmd, uchar[] buffer);
		public void write (uchar[] buffer);
		[CCode (array_length = false)]
		public unowned uchar[] read (Algorithm algo);
		public static void hash_buffer (Algorithm algo, [CCode (array_length = false)] uchar[] digest, uchar[] buffer);
		public Algorithm get_algo ();
		public bool is_enabled (Algorithm algo);
		public bool is_secure ();
		public Error info (ControlCommand what, uchar[] buffer);
		[CCode (cname = "gcry_md_setkey")]
		public Error set_key (uchar[] key_data);
		public void putc (char c);
		public void final ();
		public static Error list (ref Algorithm[] algos);
	}

	namespace Random {
		[CCode (cname = "gcry_random_level_t")]
		public enum Level {
			[CCode (cname = "GCRY_WEAK_RANDOM")]
			WEAK,
			[CCode (cname = "GCRY_STRONG_RANDOM")]
			STRONG,
			[CCode (cname = "GCRY_VERY_STRONG_RANDOM")]
			VERY_STRONG
		}

		[CCode (cname = "gcry_randomize")]
		public static void randomize (uchar[] buffer, Level level = Level.VERY_STRONG);
		[CCode (cname = "gcry_fast_random_poll")]
		public static Error poll ();
		[CCode (cname = "gcry_random_bytes", array_length = false)]
		public static uchar[] random_bytes (size_t nbytes, Level level = Level.VERY_STRONG);
		[CCode (cname = "gcry_random_bytes_secure")]
		public static uchar[] random_bytes_secure (size_t nbytes, Level level = Level.VERY_STRONG);
		[CCode (cname = "gcry_create_nonce")]
		public static void nonce (uchar[] buffer);
	}

	[Compact, CCode (cname = "struct gcry_mpi", cprefix = "gcry_mpi_", free_function = "gcry_mpi_release")]
	public class MPI {
		[CCode (cname = "enum gcry_mpi_format", cprefix = "GCRYMPI_FMT_")]
		public enum Format {
			NONE,
			STD,
			PGP,
			SSH,
			HEX,
			USG
		}

		[CCode (cname = "enum gcry_mpi_flag", cprefix = "GCRYMPI_FLAG_")]
		public enum Flag {
			SECURE,
			OPAQUE
		}

		public MPI (uint nbits);
		[CCode (cname = "gcry_mpi_snew")]
		public MPI.secure (uint nbits);
		public MPI copy ();
		public void set (MPI u);
		public void set_ui (ulong u);
		public void swap ();
		public int cmp (MPI v);
		public int cmp_ui (ulong v);

		public static Error scan (out MPI ret, MPI.Format format, [CCode (array_length = false)] uchar[] buffer, size_t buflen, out size_t nscanned);
		[CCode (instance_pos = -1)]
		public Error print (MPI.Format format, [CCode (array_length = false)] uchar[] buffer, size_t buflen, out size_t nwritter);
		[CCode (instance_pos = -1)]
		public Error aprint (MPI.Format format, out uchar[] buffer);

		public void add (MPI u, MPI v);
		public void add_ui (MPI u, ulong v);
		public void addm (MPI u, MPI v, MPI m);
		public void sub (MPI u, MPI v);
		public void sub_ui (MPI u, MPI v);
		public void subm (MPI u, MPI v, MPI m);
		public void mul (MPI u, MPI v);
		public void mul_ui (MPI u, ulong v);
		public void mulm (MPI u, MPI v, MPI m);
		public void mul_2exp (MPI u, ulong cnt);
		public void div (MPI q, MPI r, MPI dividend, MPI divisor, int round);
		public void mod (MPI dividend, MPI divisor);
		public void powm (MPI b, MPI e, MPI m);
		public int gcd (MPI a, MPI b);
		public int invm (MPI a, MPI m);

		public uint get_nbits ();
		public int test_bit (uint n);
		public void set_bit (uint n);
		public void clear_bit (uint n);
		public void set_highbit (uint n);
		public void clear_highbit (uint n);
		public void rshift (MPI a, uint n);
		public void lshift (MPI a, uint n);

		public void set_flag (MPI.Flag flag);
		public void clear_flag (MPI.Flag flag);
		public int get_flag (MPI.Flag flag);
	}

	[Compact, CCode (cname = "struct gcry_sexp", free_function = "gcry_sexp_release")]
	public class SExp {
		[CCode (cprefix = "GCRYSEXP_FMT_")]
		public enum Format {
			DEFAULT,
			CANON,
			BASE64,
			ADVANCED
		}

		public static Error @new (out SExp retsexp, void * buffer, size_t length, int autodetect);
		public static Error create (out SExp retsexp, void * buffer, size_t length, int autodetect, GLib.DestroyNotify free_function);
		public static Error sscan (out SExp retsexp, out size_t erroff, char[] buffer);
		public static Error build (out SExp retsexp, out size_t erroff, string format, ...);
		public size_t sprint (Format mode, char[] buffer);
		public static size_t canon_len (uchar[] buffer, out size_t erroff, out int errcode);
		public SExp find_token (string token, size_t token_length = 0);
		public int length ();
		public SExp? nth (int number);
		public SExp? car ();
		public SExp? cdr ();
		public unowned char[] nth_data (int number);
		public gcry_string nth_string (int number);
		public MPI nth_mpi (int number, MPI.Format mpifmt);
	}

	[CCode (cname = "char", free_function = "gcry_free")]
	public class gcry_string : string { }

	[CCode (lower_case_cprefix = "gcry_pk_")]
	namespace PublicKey {
		[CCode (cname = "enum gcry_pk_algos")]
		public enum Algorithm {
			RSA,
			ELG_E,
			DSA,
			ELG,
			ECDSA;

			[CCode (cname = "gcry_pk_algo_name")]
			public unowned string to_string ();
			[CCode (cname = "gcry_pk_map_name")]
			public static Algorithm map_name (string name);
		}

		public static Error encrypt (out SExp ciphertext, SExp data, SExp pkey);
		public static Error decrypt (out SExp plaintext, SExp data, SExp skey);
		public static Error sign (out SExp signature, SExp data, SExp skey);
		public static Error verify (SExp signature, SExp data, SExp pkey);
		public static Error testkey (SExp key);
		public static Error genkey (out SExp r_key, SExp s_params);
		public static uint get_nbits (SExp key);
	}

	[CCode (lower_case_cprefix = "gcry_kdf_")]
	namespace KeyDerivation {
		[CCode (cname = "gcry_kdf_algos", cprefix = "GCRY_KDF_", has_type_id = false)]
		public enum Algorithm {
			NONE,
			SIMPLE_S2K,
			SALTED_S2K,
			ITERSALTED_S2K,
			PBKDF1,
			PBKDF2,
			SCRYPT
		}

		public GCrypt.Error derive ([CCode (type = "const void*", array_length_type = "size_t")] uint8[] passphrasse, GCrypt.KeyDerivation.Algorithm algo, GCrypt.Hash.Algorithm subalgo, [CCode (type = "const void*", array_length_type = "size_t")] uint8[] salt, ulong iterations, [CCode (type = "void*", array_length_type = "size_t", array_length_pos = 5.5)] uint8[] keybuffer);
	}
}
