/* OpenSSL Vala Bindings
 * Copyright 2020 Zuhong Tao <taozuhong@gmail>
 * Copyright 2016 Guillaume Poirier-Morency <guillaumepoiriermorency@gmail>
 * Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
 *
 * Licensed under the OpenSSL license (the "License").  You may not use
 * this file except in compliance with the License.  You can obtain a copy
 * in the file LICENSE in the source distribution or at
 * https://www.openssl.org/source/license.html
 */

[CCode (cprefix = "")]
namespace OpenSSL
{
	[CCode (cprefix = "AES_", lower_case_cprefix = "AES_", cheader_filename = "openssl/aes.h")]
	namespace AES
	{
		public const int BLOCK_SIZE;
	}

	[Compact]
	[CCode (cname = "ENGINE", lower_case_cprefix = "ENGINE_", cprefix = "ENGINE_", cheader_filename = "openssl/engine.h", free_function = "ENGINE_free")]
	public class Engine {
		[CCode (cname = "ENGINE_new")]
		public Engine ();
		[CCode (cname = "ENGINE_by_id")]
		public Engine.by_id (string id);
		[CCode (cname = "ENGINE_get_default_RSA")]
		public Engine.get_default_RSA ();
		[CCode (cname = "ENGINE_get_default_DSA")]
		public Engine.get_default_DSA ();
		[CCode (cname = "ENGINE_get_default_DH")]
		public Engine.get_default_DH ();
		[CCode (cname = "ENGINE_get_default_RAND")]
		public Engine.get_default_RAND ();
		[CCode (cname = "ENGINE_get_cipher_engine")]
		public Engine.get_cipher_engine (int nid);
		[CCode (cname = "ENGINE_get_digest_engine")]
		public Engine.get_digest_engine (int nid);

		public int init ();
		public int finish ();
		public int set_default (uint flags);
		public int set_default_RSA ();
		public int set_default_DSA ();
		public int set_default_DH ();
		public int set_default_RAND ();
		public int set_default_ciphers ();
		public int set_default_digests ();
		public int set_default_string (string list);

	}

	[CCode (cprefix = "NID_", cheader_filename = "openssl/objects.h")]
	public enum NID
	{
		sha256
	}

	[Compact]
	[CCode (cname = "BIO_METHOD", cheader_filename = "openssl/bio.h", free_function = "BIO_meth_free")]
	public class BIOMethod
	{
		public const int BIO_TYPE_DESCRIPTOR;
		public const int BIO_TYPE_FILTER;
		public const int BIO_TYPE_SOURCE_SINK;
		public const int BIO_TYPE_NONE;
		public const int BIO_TYPE_MEM;
		public const int BIO_TYPE_FILE;
		public const int BIO_TYPE_FD;
		public const int BIO_TYPE_SOCKET;
		public const int BIO_TYPE_NULL;
		public const int BIO_TYPE_SSL;
		public const int BIO_TYPE_MD;
		public const int BIO_TYPE_BUFFER;
		public const int BIO_TYPE_CIPHER;
		public const int BIO_TYPE_BASE64;
		public const int BIO_TYPE_CONNECT;
		public const int BIO_TYPE_ACCEPT;
		public const int BIO_TYPE_NBIO_TEST;
		public const int BIO_TYPE_NULL_FILTER;
		public const int BIO_TYPE_BIO;
		public const int BIO_TYPE_LINEBUFFER;
		public const int BIO_TYPE_DGRAM;
		public const int BIO_TYPE_ASN1;
		public const int BIO_TYPE_COMP;
		public const int BIO_TYPE_DGRAM_SCTP;

		[CCode (cname = "BIO_meth_new")]
		public BIOMethod (int type, string name);

		[CCode (cname = "BIO_get_new_index")]
		public int get_new_index ();
	}

	[Compact]
	[CCode (lower_case_cprefix = "BUF_MEM_", cheader_filename = "openssl/buffer.h", free_function = "BUF_MEM_free")]
	public class Buffer {

		[CCode (cname = "BUF_MEM_new")]
		public Buffer ();

		[CCode (cname = "BUF_MEM_new_ex")]
		public Buffer.with_flags ();

		public int grow (int len);
		public size_t grow_clean (size_t len);
	}

	[Compact]
	[CCode (lower_case_cprefix = "BIO_", cheader_filename = "openssl/bio.h", free_function = "BIO_free")]
	public class BIO
	{
		public const int NOCLOSE;

		public static unowned BIOMethod s_mem ();
		public static unowned BIOMethod s_secmem ();

		public BIO (BIOMethod type);

		[CCode (cname = "BIO_new_file")]
		public BIO.with_file (string filename, string mode);

		[CCode (cname = "BIO_new_fp")]
		public BIO.with_stream (GLib.FileStream stream, int flags);

		[CCode (cname = "BIO_new_mem_buf")]
		public BIO.with_buffer (uint8[] buf);

		public int read_filename (string name);
		public int write_filename (string name);
		public int append_filename (string name);
		public int rw_filename (string name);

		public int set_mem_eof_return (int v);
		public long get_mem_data ([CCode (array_length = false)] out uint8[] pp);
		public int set_mem_buf (Buffer bm, int c);
		public int get_mem_ptr (out Buffer pp);

		public int set (BIOMethod type);
		public int read (uint8[] data);
		public int write (uint8[] data);

		[PrintfFormat]
		public int printf (string format, ...);

		[PrintfFormat]
		public int vprintf (string format, va_list args);

		[PrintfFormat]
		public static int snprintf (uint8[] buf, string format, ...);

		[PrintfFormat]
		public static int vsnprintf (uint8[] buf, string format, va_list args);

		public int reset ();
		public int seek (int ofs);
		public int pending ();
		public int wpending ();
		public int flush ();
		public int eof ();
		public int tell ();
		public int set_close (long flag);
		public int get_close ();
		public long ctrl (int cmd, long larg, [CCode (array_length = false)] uint8[] parg);

		public int read_ex (uint8[] data, out size_t readbytes);
		public int write_ex (uint8[] data, out size_t written);
	}

	[CCode (lower_case_cprefix = "CRYPTO_", cheader_filename = "openssl/crypto.h")]
	namespace Crypto
	{
		public int memcmp (void* v1, void* v2, size_t n);
	}

	[Compact]
	[CCode (cname = "ASN1_PCTX", lower_case_cprefix = "ASN1_PCTX_", free_function = "ASN1_PCTX_free")]
	public class ASN1_PCTX {
		public ASN1_PCTX ();

		public ulong get_flags ();
		public void set_flags (ulong flags);
		public ulong get_nm_flags ();
		public void set_nm_flags (ulong flags);
		public ulong get_cert_flags ();
		public void set_cert_flags (ulong flags);

		public ulong get_oid_flags ();
		public void set_oid_flags (ulong flags);
		public ulong get_str_flags ();
		public void set_str_flags (ulong flags);
	}

	[Compact]
	[CCode (cname = "ASN1_SCTX", lower_case_cprefix = "ASN1_SCTX_", free_function = "ASN1_SCTX_free")]
	public class ASN1_SCTX {
		public ASN1_SCTX ();

		public ulong get_flags ();
	}

	[CCode (cprefix = "EVP_", lower_case_cprefix = "EVP_", cheader_filename = "openssl/evp.h")]
	namespace EVP
	{
		public const int CIPH_STREAM_CIPHER;
		public const int CIPH_ECB_MODE;
		public const int CIPH_CBC_MODE;
		public const int CIPH_CFB_MODE;
		public const int CIPH_OFB_MODE;
		public const int CIPH_CTR_MODE;
		public const int CIPH_GCM_MODE;
		public const int CIPH_CCM_MODE;
		public const int CIPH_XTS_MODE;
		public const int CIPH_WRAP_MODE;
		public const int CIPH_OCB_MODE;
		public const int CIPH_MODE;
		public const int CIPH_VARIABLE_LENGTH;
		public const int CIPH_CUSTOM_IV;
		public const int CIPH_ALWAYS_CALL_INIT;
		public const int CIPH_CTRL_INIT;
		public const int CIPH_CUSTOM_KEY_LENGTH;
		public const int CIPH_NO_PADDING;
		public const int CIPH_RAND_KEY;
		public const int CIPH_CUSTOM_COPY;
		public const int CIPH_CUSTOM_IV_LENGTH;
		public const int CIPH_FLAG_DEFAULT_ASN1;
		public const int CIPH_FLAG_LENGTH_BITS;
		public const int CIPH_FLAG_FIPS;
		public const int CIPH_FLAG_NON_FIPS_ALLOW;
		public const int CIPH_FLAG_CUSTOM_CIPHER;
		public const int CIPH_FLAG_AEAD_CIPHER;
		public const int CIPH_FLAG_TLS1_1_MULTIBLOCK;
		public const int CIPH_FLAG_PIPELINE;

		public const int CTRL_INIT;
		public const int CTRL_SET_KEY_LENGTH;
		public const int CTRL_GET_RC2_KEY_BITS;
		public const int CTRL_SET_RC2_KEY_BITS;
		public const int CTRL_GET_RC5_ROUNDS;
		public const int CTRL_SET_RC5_ROUNDS;
		public const int CTRL_RAND_KEY;
		public const int CTRL_PBE_PRF_NID;
		public const int CTRL_COPY;
		public const int CTRL_AEAD_SET_IVLEN;
		public const int CTRL_AEAD_GET_TAG;
		public const int CTRL_AEAD_SET_TAG;
		public const int CTRL_AEAD_SET_IV_FIXED;
		public const int CTRL_GCM_SET_IVLEN;
		public const int CTRL_GCM_GET_TAG;
		public const int CTRL_GCM_SET_TAG;
		public const int CTRL_GCM_SET_IV_FIXED;
		public const int CTRL_GCM_IV_GEN;
		public const int CTRL_CCM_SET_IVLEN;
		public const int CTRL_CCM_GET_TAG;
		public const int CTRL_CCM_SET_TAG;
		public const int CTRL_CCM_SET_IV_FIXED;
		public const int CTRL_CCM_SET_L;
		public const int CTRL_CCM_SET_MSGLEN;
		public const int CTRL_AEAD_TLS1_AAD;
		public const int CTRL_AEAD_SET_MAC_KEY;
		public const int CTRL_GCM_SET_IV_INV;
		public const int CTRL_TLS1_1_MULTIBLOCK_AAD;
		public const int CTRL_TLS1_1_MULTIBLOCK_ENCRYPT;
		public const int CTRL_TLS1_1_MULTIBLOCK_DECRYPT;
		public const int CTRL_TLS1_1_MULTIBLOCK_MAX_BUFSIZE;
		public const int CTRL_SSL3_MASTER_SECRET;
		public const int CTRL_SET_SBOX;
		public const int CTRL_SBOX_USED;
		public const int CTRL_KEY_MESH;
		public const int CTRL_BLOCK_PADDING_MODE;
		public const int CTRL_SET_PIPELINE_OUTPUT_BUFS;
		public const int CTRL_SET_PIPELINE_INPUT_BUFS;
		public const int CTRL_SET_PIPELINE_INPUT_LENS;
		public const int CTRL_GET_IVLEN;

		[CCode (cprefix = "EVP_PADDING_")]
		public enum Padding {
			PKCS7,
			ISO7816_4,
			ANSI923,
			ISO10126,
			ZERO,
		}

		[CCode (cprefix = "EVP_PKEY_OP_")]
		public enum PublicKeyOperation {
			UNDEFINED,
			PARAMGEN,
			KEYGEN,
			SIGN,
			VERIFY,
			VERIFYRECOVER,
			SIGNCTX,
			VERIFYCTX,
			ENCRYPT,
			DECRYPT,
			DERIVE,
		}
		public const int PKEY_OP_TYPE_SIG;
		public const int PKEY_OP_TYPE_CRYPT;
		public const int PKEY_OP_TYPE_NOGEN;
		public const int PKEY_OP_TYPE_GEN;

		[CCode (cprefix = "EVP_PKEY_CTRL_")]
		public enum PublicKeyControl {
			MD,
			PEER_KEY,
			PKCS7_ENCRYPT,
			PKCS7_DECRYPT,
			PKCS7_SIGN,
			SET_MAC_KEY,
			DIGESTINIT,
			SET_IV,
			CMS_ENCRYPT,
			CMS_DECRYPT,
			CMS_SIGN,
			CIPHER,
			GET_MD,
			SET_DIGEST_SIZE,
		}

		[CCode (cprefix = "EVP_PKEY_CTRL_", cheader_filename = "openssl/rsa.h")]
		public enum PublicKeyRsaControl {
			RSA_PADDING,
			RSA_PSS_SALTLEN,
			RSA_KEYGEN_BITS,
			RSA_KEYGEN_PUBEXP,
			RSA_MGF1_MD,
			GET_RSA_PADDING,
			GET_RSA_PSS_SALTLEN,
			GET_RSA_MGF1_MD,
			RSA_OAEP_MD,
			RSA_OAEP_LABEL,
			GET_RSA_OAEP_MD,
			GET_RSA_OAEP_LABEL,
			RSA_KEYGEN_PRIMES,
		}

		[Compact]
		[CCode (cname = "EVP_PKEY", lower_case_cprefix = "EVP_PKEY_", cprefix = "EVP_PKEY_", free_function = "EVP_PKEY_free")]
		public class PublicKey {
			public const int NONE;
			public const int RSA;
			public const int RSA2;
			public const int RSA_PSS;
			public const int DSA;
			public const int DSA1;
			public const int DSA2;
			public const int DSA3;
			public const int DSA4;
			public const int DH;
			public const int DHX;
			public const int EC;
			public const int SM2;
			public const int HMAC;
			public const int CMAC;
			public const int SCRYPT;
			public const int TLS1_PRF;
			public const int HKDF;
			public const int POLY1305;
			public const int SIPHASH;
			public const int X25519;
			public const int ED25519;
			public const int X448;
			public const int ED448;

			public PublicKey ();

			[CCode (cname = "EVP_PKEY_new_raw_private_key")]
			public PublicKey.raw_private_key (int type, Engine? e, uint8[] key);

			[CCode (cname = "EVP_PKEY_new_raw_public_key")]
			public PublicKey.raw_public_key (int type, Engine? e, uint8[] key);

			[CCode (cname = "EVP_PKEY_new_CMAC_key")]
			public PublicKey.CMAC_key (Engine? e, uint8[] priv, Cipher? cipher);

			[CCode (cname = "EVP_PKEY_new_mac_key")]
			public PublicKey.mac_key (int type, Engine? e, uint8[] key);

			public int id ();
			public int size ();
			public int base_id ();
			public static int type (int type);
			public int set_alias_type (int type);
			public int up_ref ();
			public RSA? get1_RSA ();
			public RSA? get0_RSA ();
			public int set1_RSA (RSA? key);
			public int assign_RSA (RSA? key);
			public int security_bits ();

			[CCode (instance_pos = 1.1)]
			public int print_public (BIO out, int indent, ASN1_PCTX? pctx);

			[CCode (instance_pos = 1.1)]
			public int print_private (BIO out, int indent, ASN1_PCTX? pctx);

			public Engine? get0_engine ();
			public int set1_engine (Engine? engine);

			public int get_raw_private_key ([CCode (array_length = false)] uint8[] priv, out size_t len);
			public int get_raw_public_key ([CCode (array_length = false)] uint8[] pub, out size_t len);
		}

		[Compact]
		[CCode (cname = "EVP_PKEY_CTX", lower_case_cprefix = "EVP_PKEY_CTX_", cprefix = "EVP_PKEY_CTX_", free_function = "EVP_PKEY_CTX_free")]
		public class PublicKeyContext {
			public PublicKeyContext (PublicKey pkey, Engine? e);
			public PublicKeyContext.id (int id, Engine? e);

			public PublicKeyContext dup ();

			public int ctrl_str (string type, string value);
			public int ctrl_uint64(int keytype, int optype, int cmd, uint64 value);
			public int ctrl (int keytype, int optype, int cmd, int p1, [CCode (array_length = false)] uint8[] p2);

			[CCode (cname = "EVP_PKEY_CTX_set_rsa_padding", cheader_filename = "openssl/rsa.h")]
			public int set_rsa_padding (int pad);
			[CCode (cname = "EVP_PKEY_CTX_get_rsa_padding", cheader_filename = "openssl/rsa.h")]
			public int get_rsa_padding (out int pad);
			[CCode (cname = "EVP_PKEY_CTX_set_rsa_pss_saltlen", cheader_filename = "openssl/rsa.h")]
			public int set_rsa_pss_saltlen (int len);
			[CCode (cname = "EVP_PKEY_CTX_get_rsa_pss_saltlen", cheader_filename = "openssl/rsa.h")]
			public int get_rsa_pss_saltlen (out int len);
			[CCode (cname = "EVP_PKEY_CTX_set_rsa_keygen_bits", cheader_filename = "openssl/rsa.h")]
			public int set_rsa_keygen_bits (int mbits);
			[CCode (cname = "EVP_PKEY_CTX_set_rsa_keygen_pubexp", cheader_filename = "openssl/rsa.h")]
			public int set_rsa_keygen_pubexp (BIGNUM pubexp);
			[CCode (cname = "EVP_PKEY_CTX_set_rsa_keygen_primes", cheader_filename = "openssl/rsa.h")]
			public int set_rsa_keygen_primes (int primes);

			public int md (int optype, int cmd, string md);
			public int set_signature_md (MessageDigest md);
			public int get_signature_md (out MessageDigest pmd);
			public int set_mac_key (uint8[] key);

			[CCode (cname = "EVP_PKEY_keygen_init")]
			public int keygen_init ();

			[CCode (cname = "EVP_PKEY_keygen")]
			public int keygen (out PublicKey ppkey);

			[CCode (cname = "EVP_PKEY_paramgen_init")]
			public int paramgen_init ();

			[CCode (cname = "EVP_PKEY_paramgen")]
			public int paramgen (out PublicKey ppkey);

			[CCode (cname = "EVP_PKEY_encrypt_init")]
			public int encrypt_init ();

			[CCode (cname = "EVP_PKEY_encrypt")]
			public int encrypt ([CCode (array_length = false)] uint8[] out, out size_t outlen, uint8[] in);

			[CCode (cname = "EVP_PKEY_decrypt_init")]
			public int decrypt_init ();

			[CCode (cname = "EVP_PKEY_decrypt")]
			public int decrypt ([CCode (array_length = false)] uint8[] out, out size_t outlen, uint8[] in);

			[CCode (cname = "EVP_PKEY_derive_init")]
			public int derive_init ();

			[CCode (cname = "EVP_PKEY_derive_set_peer")]
			public int derive_set_peer (PublicKey peer);

			[CCode (cname = "EVP_PKEY_derive")]
			public int derive ([CCode (array_length = false)] uint8[] key, out size_t keylen);

			[CCode (cname = "EVP_PKEY_sign_init")]
			public int sign_init ();

			[CCode (cname = "EVP_PKEY_sign")]
			public int sign ([CCode (array_length = false)] uint8[] sig, out size_t siglen, uint8[] tbs);

			[CCode (cname = "EVP_PKEY_verify_init")]
			public int verify_init ();

			[CCode (cname = "EVP_PKEY_verify")]
			public int verify (uint8[] sig, uint8[] tbs);

			[CCode (cname = "EVP_PKEY_verify_recover_init")]
			public int verify_recover_init ();

			[CCode (cname = "EVP_PKEY_verify_recover")]
			public int verify_recover ([CCode (array_length = false)] uint8[] rout, out size_t routlen, uint8[] sig);
		}

		[Compact]
		[CCode (cname = "EVP_MD")]
		public class MessageDigest
		{

		}

		public unowned MessageDigest? md_null ();
		public unowned MessageDigest? md2 ();
		public unowned MessageDigest? md4 ();
		public unowned MessageDigest? md5 ();
		public unowned MessageDigest? md5_sha1 ();
		public unowned MessageDigest? blake2b512 ();
		public unowned MessageDigest? blake2s256 ();
		public unowned MessageDigest? sha1 ();
		public unowned MessageDigest? sha224 ();
		public unowned MessageDigest? sha256 ();
		public unowned MessageDigest? sha384 ();
		public unowned MessageDigest? sha512 ();
		public unowned MessageDigest? mdc2 ();
		public unowned MessageDigest? ripmed160 ();
		public unowned MessageDigest? whirlpool ();
		[CCode (cname = "get_digestbyname")]
		public unowned MessageDigest? get_digest_by_name (string name);

		[Compact]
		[CCode (cname = "EVP_MD_CTX", lower_case_cprefix = "EVP_MD_CTX_")]
		public class MessageDigestContext
		{
			public MessageDigestContext ();
			[CCode (cname = "EVP_DigestInit_ex")]
			public int init (MessageDigest type, Engine? engine);
			[CCode (cname = "EVP_DigestUpdate")]
			public int update (uint8[] d);
			[CCode (cname = "EVP_DigestFinal_ex")]
			public int final ([CCode (array_length = false)] uchar[] md, out int s);
		}

		[Compact]
		[CCode (cname = "EVP_CIPHER", lower_case_cprefix = "EVP_CIPHER_")]
		public class Cipher
		{
			[CCode (cname = "EVP_CIPHER_meth_new")]
			public Cipher (int cipher_type, int block_size, int key_len);
			public int key_length ();
			public int iv_length ();
		}

		public unowned Cipher? enc_null ();
		public unowned Cipher? des_ecb ();
		public unowned Cipher? des_ede ();
		public unowned Cipher? des_ede3 ();
		public unowned Cipher? des_ede_ecb ();
		public unowned Cipher? des_ede3_ecb ();
		public unowned Cipher? des_cfb64 ();
		public unowned Cipher? des_cfb1 ();
		public unowned Cipher? des_cfb8 ();
		public unowned Cipher? des_ede_cfb64 ();
		public unowned Cipher? des_ede3_cfb64 ();
		public unowned Cipher? des_ede3_cfb1 ();
		public unowned Cipher? des_ede3_cfb8 ();
		public unowned Cipher? des_ofb ();
		public unowned Cipher? des_ede_ofb ();
		public unowned Cipher? des_ede3_ofb ();
		public unowned Cipher? des_cbc ();
		public unowned Cipher? des_ede_cbc ();
		public unowned Cipher? des_ede3_cbc ();
		public unowned Cipher? desx_cbc ();
		public unowned Cipher? des_ede3_wrap ();
		public unowned Cipher? rc4 ();
		public unowned Cipher? rc4_40 ();
		public unowned Cipher? rc4_hmac_md5 ();
		public unowned Cipher? idea_ecb ();
		public unowned Cipher? idea_cfb64 ();
		public unowned Cipher? idea_ofb ();
		public unowned Cipher? idea_cbc ();
		public unowned Cipher? rc2_ecb ();
		public unowned Cipher? rc2_cbc ();
		public unowned Cipher? rc2_40_cbc ();
		public unowned Cipher? rc2_64_cbc ();
		public unowned Cipher? rc2_cfb64 ();
		public unowned Cipher? rc2_ofb ();
		public unowned Cipher? bf_ecb ();
		public unowned Cipher? bf_cbc ();
		public unowned Cipher? bf_cfb64 ();
		public unowned Cipher? bf_ofb ();
		public unowned Cipher? cast5_ecb ();
		public unowned Cipher? cast5_cbc ();
		public unowned Cipher? cast5_cfb64 ();
		public unowned Cipher? cast5_ofb ();
		public unowned Cipher? rc5_32_12_16_cbc ();
		public unowned Cipher? rc5_32_12_16_ecb ();
		public unowned Cipher? rc5_32_12_16_cfb64 ();
		public unowned Cipher? rc5_32_12_16_ofb ();
		public unowned Cipher? aes_128_ecb ();
		public unowned Cipher? aes_128_cbc ();
		public unowned Cipher? aes_128_cfb1 ();
		public unowned Cipher? aes_128_cfb8 ();
		public unowned Cipher? aes_128_cfb128 ();
		public unowned Cipher? aes_128_ofb ();
		public unowned Cipher? aes_128_ctr ();
		public unowned Cipher? aes_128_ccm ();
		public unowned Cipher? aes_128_gcm ();
		public unowned Cipher? aes_128_xts ();
		public unowned Cipher? aes_128_wrap ();
		public unowned Cipher? aes_128_wrap_pad ();
		public unowned Cipher? aes_128_ocb ();
		public unowned Cipher? aes_192_ecb ();
		public unowned Cipher? aes_192_cbc ();
		public unowned Cipher? aes_192_cfb1 ();
		public unowned Cipher? aes_192_cfb8 ();
		public unowned Cipher? aes_192_cfb128 ();
		public unowned Cipher? aes_192_ofb ();
		public unowned Cipher? aes_192_ctr ();
		public unowned Cipher? aes_192_ccm ();
		public unowned Cipher? aes_192_gcm ();
		public unowned Cipher? aes_192_wrap ();
		public unowned Cipher? aes_192_wrap_pad ();
		public unowned Cipher? aes_192_ocb ();
		public unowned Cipher? aes_256_ecb ();
		public unowned Cipher? aes_256_cbc ();
		public unowned Cipher? aes_256_cfb1 ();
		public unowned Cipher? aes_256_cfb8 ();
		public unowned Cipher? aes_256_cfb128 ();
		public unowned Cipher? aes_256_ofb ();
		public unowned Cipher? aes_256_ctr ();
		public unowned Cipher? aes_256_ccm ();
		public unowned Cipher? aes_256_gcm ();
		public unowned Cipher? aes_256_xts ();
		public unowned Cipher? aes_256_wrap ();
		public unowned Cipher? aes_256_wrap_pad ();
		public unowned Cipher? aes_256_ocb ();
		public unowned Cipher? aes_128_cbc_hmac_sha1 ();
		public unowned Cipher? aes_256_cbc_hmac_sha1 ();
		public unowned Cipher? aes_128_cbc_hmac_sha256 ();
		public unowned Cipher? aes_256_cbc_hmac_sha256 ();
		public unowned Cipher? camellia_128_ecb ();
		public unowned Cipher? camellia_128_cbc ();
		public unowned Cipher? camellia_128_cfb1 ();
		public unowned Cipher? camellia_128_cfb8 ();
		public unowned Cipher? camellia_128_cfb128 ();
		public unowned Cipher? camellia_128_ofb ();
		public unowned Cipher? camellia_128_ctr ();
		public unowned Cipher? camellia_192_ecb ();
		public unowned Cipher? camellia_192_cbc ();
		public unowned Cipher? camellia_192_cfb1 ();
		public unowned Cipher? camellia_192_cfb8 ();
		public unowned Cipher? camellia_192_cfb128 ();
		public unowned Cipher? camellia_192_ofb ();
		public unowned Cipher? camellia_192_ctr ();
		public unowned Cipher? camellia_256_ecb ();
		public unowned Cipher? camellia_256_cbc ();
		public unowned Cipher? camellia_256_cfb1 ();
		public unowned Cipher? camellia_256_cfb8 ();
		public unowned Cipher? camellia_256_cfb128 ();
		public unowned Cipher? camellia_256_ofb ();
		public unowned Cipher? camellia_256_ctr ();
		public unowned Cipher? chacha20 ();
		public unowned Cipher? chacha20_poly1305 ();
		public unowned Cipher? seed_ecb ();
		public unowned Cipher? seed_cbc ();
		public unowned Cipher? seed_cfb128 ();
		public unowned Cipher? seed_ofb ();
		[CCode (cname = "EVP_get_cipherbyname")]
		public unowned Cipher? get_cipher_by_name (string name);

		[CCode (cname = "EVP_BytesToKey")]
		public int bytes_to_key (Cipher cipher, MessageDigest md, [CCode (array_length = false)] uchar[] salt, uchar[] key_data, int nrounds, [CCode (array_length = false)] uchar[] key, [CCode (array_length = false)] uchar[] iv);

		[Compact]
		[CCode (cname = "EVP_CIPHER_CTX", cprefix = "EVP_CIPHER_CTX_", lower_case_cprefix = "EVP_CIPHER_CTX_")]
		public class CipherContext
		{
			public CipherContext ();

			public int reset ();

			public int set_key_length (int keylen);
			public int set_padding (int pad);

			[CCode (cname = "EVP_EncryptInit_ex")]
			public int encrypt_init (Cipher cipher, Engine? engine, [CCode (array_length = false)] uchar[] key, [CCode (array_length = false)] uchar[] iv);

			[CCode (cname = "EVP_EncryptUpdate")]
			public int encrypt_update ([CCode (array_length = false)] uchar[] ciphertext, out int ciphertext_len, uchar[] plaintext);

			[CCode (cname = "EVP_EncryptFinal_ex")]
			public int encrypt_final ([CCode (array_length = false)] uchar[] ciphertext, out int ciphertext_len);

			[CCode (cname = "EVP_DecryptInit_ex")]
			public int decrypt_init (Cipher cipher, Engine? engine, [CCode (array_length = false)] uchar[] key, [CCode (array_length = false)] uchar[] iv);

			[CCode (cname = "EVP_DecryptUpdate")]
			public int decrypt_update ([CCode (array_length = false)] uchar[] plaintext, out int plaintext_len, uchar[] ciphertext);

			[CCode (cname = "EVP_DecryptFinal_ex")]
			public int decrypt_final ([CCode (array_length = false)] uchar[] plaintext, out int plaintext_len);
		}
	}

	[Compact]
	[CCode (cname = "BIGNUM", cheader_filename = "openssl/rsa.h", free_function = "BN_free")]
	public class BIGNUM {
		[CCode (cname = "BN_new", cheader_filename = "openssl/bn.h")]
		public BIGNUM ();

		[CCode (cname = "BN_secure_new", cheader_filename = "openssl/bn.h")]
		public BIGNUM.secure ();

		[CCode (cname = "BN_clear", cheader_filename = "openssl/bn.h")]
		public void clear ();

		[CCode (cname = "BN_set_word", cheader_filename = "openssl/bn.h")]
		public int set_word (ulong w);
	}

	[Compact]
	[CCode (cname = "BN_GENCB", cheader_filename = "openssl/rsa.h", free_function = "BN_GENCB_free")]
	public class BN_GENCB {
		public delegate int BigNumGenCallback (int a, int b, BN_GENCB gcb);

		[CCode (cname = "BN_GENCB_new")]
		public BN_GENCB ();

		[CCode (cname = "BN_GENCB_set")]
		public void set (BigNumGenCallback cb, [CCode (array_length = false)] uint8[] cb_arg);

		[CCode (cname = "BN_GENCB_call")]
		public int call (int a, int b);
	}

	[Compact]
	[CCode (lower_case_cprefix = "RSA_", cprefix = "RSA_", cheader_filename = "openssl/rsa.h", free_function = "RSA_free")]
	public class RSA
	{
		public const int PKCS1_PADDING;
		public const int SSLV23_PADDING;
		public const int NO_PADDING;
		public const int PKCS1_OAEP_PADDING;
		public const int X931_PADDING;
		public const int PKCS1_PSS_PADDING;
		public const int F4;
		[CCode (cname = "RSA_3")]
		public const int RSA_3;

		public RSA ();

		public int size ();

		public int set0_key (BIGNUM n, BIGNUM e, BIGNUM d);
		public void get0_key (out BIGNUM n, out BIGNUM e, out BIGNUM d);

		public void clear_flags (int flags);
		public int test_flags (int flags);
		public void set_flags (int flags);
		public Engine get0_engine ();

		[CCode (instance_pos = 1.1)]
		public int print_fp (GLib.FileStream fp, int offset);
		[CCode (instance_pos = 1.1)]
		public int print (BIO bp, int offset);
		public int generate_key_ex (int bits, BIGNUM e, BN_GENCB? cb = null);
		[CCode (instance_pos = 4)]
		public bool sign (int type, uint8[] m, [CCode (array_length = false)] uint8[] sigret, out int siglen);
		[CCode (instance_pos = 3)]
		public int verify (int type, uint8[] m, uint8[] sigbuf);
		[CCode (instance_pos = 2.1)]
		public int public_encrypt ([CCode (array_length_pos = 0)] uint8[] from, [CCode (array_length = false)] uint8[] to, int padding);
		[CCode (instance_pos = 2.1)]
		public int private_encrypt ([CCode (array_length_pos = 0)] uint8[] from, [CCode (array_length = false)] uint8[] to, int padding);
		[CCode (instance_pos = 2.1)]
		public int public_decrypt ([CCode (array_length_pos = 0)] uint8[] from, [CCode (array_length = false)] uint8[] to,int padding);
		[CCode (instance_pos = 2.1)]
		public int private_decrypt ([CCode (array_length_pos = 0)] uint8[] from, [CCode (array_length = false)] uint8[] to, int padding);
	}

	[CCode (lower_case_cprefix = "PEM_", cheader_filename = "openssl/pem.h")]
	namespace PEM
	{
		[CCode (cname = "pem_password_cb")]
		public delegate int PasswordCallback (uint8[] buf, int flag);
		public void read_RSAPrivateKey (GLib.FileStream f, out RSA x, PasswordCallback? cb = null);
		public void read_RSAPublicKey (GLib.FileStream f, out RSA x, PasswordCallback? cb = null);
		public int write_RSAPrivateKey (GLib.FileStream f, RSA x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);
		public int write_RSAPublicKey (GLib.FileStream f, RSA x);

		public void read_bio_RSAPublicKey (BIO bp, out RSA x, PasswordCallback? cb = null);
		public void read_bio_RSAPrivateKey (BIO bp, out RSA x, PasswordCallback? cb = null);
		public bool write_bio_RSAPublicKey (BIO bp, RSA x);
		public bool write_bio_RSAPrivateKey (BIO bp, RSA x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);

		public void read_bio_PUBKEY (BIO bp, out EVP.PublicKey x, PasswordCallback? cb = null);
		public int write_bio_PUBKEY (BIO bp, EVP.PublicKey x);
		public void read_PUBKEY (GLib.FileStream fp, out EVP.PublicKey x, PasswordCallback? cb = null);
		public int write_PUBKEY (GLib.FileStream fp, EVP.PublicKey x);

		public void read_bio_PrivateKey (BIO bp, out EVP.PublicKey x, PasswordCallback? cb = null);
		public void read_PrivateKey (GLib.FileStream fp, out EVP.PublicKey x, PasswordCallback? cb = null);
		public int write_bio_PrivateKey (BIO bp, EVP.PublicKey x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);
		public int write_bio_PrivateKey_traditional (BIO bp, EVP.PublicKey x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);
		public int write_PrivateKey (GLib.FileStream fp, EVP.PublicKey x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);
		public int write_bio_PKCS8PrivateKey (BIO bp, EVP.PublicKey x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);
		public int write_bio_PKCS8PrivateKey_nid (BIO bp, EVP.PublicKey x, int nid, uint8[] kstr, PasswordCallback? cb = null);
		public int write_PKCS8PrivateKey (GLib.FileStream fp, EVP.PublicKey x, EVP.Cipher? enc, uint8[] kstr, PasswordCallback? cb = null);
		public int write_PKCS8PrivateKey_nid (GLib.FileStream fp, EVP.PublicKey x, int nid, uint8[] kstr, PasswordCallback? cb = null);
	}

	public RSA? d2i_RSA_PUBKEY (out RSA a, uint8[] ppin);
	public RSA? d2i_RSA_PUBKEY_bio (BIO bp, out RSA a);
	public RSA? d2i_RSA_PUBKEY_fp (GLib.FileStream fp, out RSA a);

	public int i2d_RSA_PUBKEY (RSA rsa, [CCode (array_length = false)] out uint8[] ppout);
	public int i2d_RSA_PUBKEY_fp (GLib.FileStream fp, RSA a);
	public int i2d_RSA_PUBKEY_bio (BIO bp, RSA a);
}
