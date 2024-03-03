#include "signal_helper.h"

#ifdef GCRYPT
#include <gcrypt.h>
#else
#include <openssl/evp.h>
#include <openssl/rand.h>
#endif

signal_type_base* signal_type_ref_vapi(void* instance) {
    g_return_val_if_fail(instance != NULL, NULL);
    signal_type_ref(instance);
    return instance;
}

signal_type_base* signal_type_unref_vapi(void* instance) {
    g_return_val_if_fail(instance != NULL, NULL);
    signal_type_unref(instance);
    return NULL;
}

signal_protocol_address* signal_protocol_address_new(const gchar* name, int32_t device_id) {
    g_return_val_if_fail(name != NULL, NULL);
    signal_protocol_address* address = malloc(sizeof(signal_protocol_address));
    address->device_id = -1;
    address->name = NULL;
    signal_protocol_address_set_name(address, name);
    signal_protocol_address_set_device_id(address, device_id);
    return address;
}

void signal_protocol_address_free(signal_protocol_address* ptr) {
    g_return_if_fail(ptr != NULL);
    if (ptr->name) {
        g_free((void*)ptr->name);
    }
    return free(ptr);
}

void signal_protocol_address_set_name(signal_protocol_address* self, const gchar* name) {
    g_return_if_fail(self != NULL);
    g_return_if_fail(name != NULL);
    gchar* n = g_malloc(strlen(name)+1);
    memcpy(n, name, strlen(name));
    n[strlen(name)] = 0;
    if (self->name) {
        g_free((void*)self->name);
    }
    self->name = n;
    self->name_len = strlen(n);
}

gchar* signal_protocol_address_get_name(signal_protocol_address* self) {
    g_return_val_if_fail(self != NULL, NULL);
    g_return_val_if_fail(self->name != NULL, 0);
    gchar* res = g_malloc(sizeof(char) * (self->name_len + 1));
    memcpy(res, self->name, self->name_len);
    res[self->name_len] = 0;
    return res;
}

int32_t signal_protocol_address_get_device_id(signal_protocol_address* self) {
    g_return_val_if_fail(self != NULL, -1);
    return self->device_id;
}

void signal_protocol_address_set_device_id(signal_protocol_address* self, int32_t device_id) {
    g_return_if_fail(self != NULL);
    self->device_id = device_id;
}

int signal_vala_randomize(uint8_t *data, size_t len) {
#ifdef GCRYPT
    gcry_randomize(data, len, GCRY_STRONG_RANDOM);
    return SG_SUCCESS;
#else
    return RAND_bytes(data, len) == 1 ? SG_SUCCESS : SG_ERR_UNKNOWN;
#endif
}

int signal_vala_random_generator(uint8_t *data, size_t len, void *user_data) {
#ifdef GCRYPT
    gcry_randomize(data, len, GCRY_STRONG_RANDOM);
    return SG_SUCCESS;
#else
    return RAND_bytes(data, len) == 1 ? SG_SUCCESS : SG_ERR_UNKNOWN;
#endif
}

#ifndef GCRYPT
struct SIGNAL_VALA_HMAC_CTX {
    EVP_PKEY *pkey;
    EVP_MD_CTX *ctx;
};
#endif
int signal_vala_hmac_sha256_init(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data) {
#ifdef GCRYPT
    gcry_mac_hd_t* ctx = malloc(sizeof(gcry_mac_hd_t));
    if (!ctx) return SG_ERR_NOMEM;

    if (gcry_mac_open(ctx, GCRY_MAC_HMAC_SHA256, 0, 0)) {
        free(ctx);
        return SG_ERR_UNKNOWN;
    }

    if (gcry_mac_setkey(*ctx, key, key_len)) {
        free(ctx);
        return SG_ERR_UNKNOWN;
    }

    *hmac_context = ctx;

    return SG_SUCCESS;
#else
    EVP_PKEY *pkey = EVP_PKEY_new_raw_private_key(EVP_PKEY_HMAC, NULL, key, key_len);
    if (!pkey) {
        return SG_ERR_NOMEM;
    }
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    if (!ctx) {
        EVP_PKEY_free(pkey);
        return SG_ERR_NOMEM;
    }
    if (EVP_DigestSignInit(ctx, NULL, EVP_sha256(), NULL, pkey) != 1) {
        EVP_MD_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return SG_ERR_UNKNOWN;
    }

    struct SIGNAL_VALA_HMAC_CTX *hmac_ctx = malloc(sizeof(*hmac_ctx));
    hmac_ctx->pkey = pkey;
    hmac_ctx->ctx = ctx;
    *hmac_context = hmac_ctx;

    return SG_SUCCESS;
#endif
}

int signal_vala_hmac_sha256_update(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data) {
#ifdef GCRYPT
    gcry_mac_hd_t* ctx = hmac_context;

    if (gcry_mac_write(*ctx, data, data_len)) return SG_ERR_UNKNOWN;

    return SG_SUCCESS;
#else
    struct SIGNAL_VALA_HMAC_CTX *hmac_ctx = hmac_context;
    if (EVP_DigestSignUpdate(hmac_ctx->ctx, data, data_len) != 1) {
        return SG_ERR_UNKNOWN;
    }
    return SG_SUCCESS;
#endif
}

int signal_vala_hmac_sha256_final(void *hmac_context, signal_buffer **output, void *user_data) {
#ifdef GCRYPT
    size_t len = gcry_mac_get_algo_maclen(GCRY_MAC_HMAC_SHA256);
    uint8_t md[len];
    gcry_mac_hd_t* ctx = hmac_context;

    if (gcry_mac_read(*ctx, md, &len)) return SG_ERR_UNKNOWN;

    signal_buffer *output_buffer = signal_buffer_create(md, len);
    if (!output_buffer) return SG_ERR_NOMEM;

    *output = output_buffer;

    return SG_SUCCESS;
#else
    size_t len;
    struct SIGNAL_VALA_HMAC_CTX *hmac_ctx = hmac_context;
    if (EVP_DigestSignFinal(hmac_ctx->ctx, NULL, &len) != 1) {
        return SG_ERR_UNKNOWN;
    }
    signal_buffer *output_buffer = signal_buffer_alloc(len);
    if (!output_buffer) {
        return SG_ERR_NOMEM;
    }
    size_t another_len = len;
    if (EVP_DigestSignFinal(hmac_ctx->ctx, signal_buffer_data(output_buffer), &another_len) != 1) {
        signal_buffer_free(output_buffer);
        return SG_ERR_UNKNOWN;
    }
    if (another_len != len) {
        signal_buffer_free(output_buffer);
        return SG_ERR_UNKNOWN;
    }
    *output = output_buffer;
    return SG_SUCCESS;
#endif
}

void signal_vala_hmac_sha256_cleanup(void *hmac_context, void *user_data) {
#ifdef GCRYPT
    gcry_mac_hd_t* ctx = hmac_context;
    if (ctx) {
        gcry_mac_close(*ctx);
        free(ctx);
    }
#else
    struct SIGNAL_VALA_HMAC_CTX *hmac_ctx = hmac_context;
    if (hmac_ctx) {
        EVP_MD_CTX_free(hmac_ctx->ctx);
        EVP_PKEY_free(hmac_ctx->pkey);
        free(hmac_ctx);
    }
#endif
}

int signal_vala_sha512_digest_init(void **digest_context, void *user_data) {
#ifdef GCRYPT
    gcry_md_hd_t* ctx = malloc(sizeof(gcry_mac_hd_t));
    if (!ctx) return SG_ERR_NOMEM;

    if (gcry_md_open(ctx, GCRY_MD_SHA512, 0)) {
        free(ctx);
        return SG_ERR_UNKNOWN;
    }

    *digest_context = ctx;

    return SG_SUCCESS;
#else
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    if (!ctx) {
        return SG_ERR_NOMEM;
    }
    if (EVP_DigestInit_ex(ctx, EVP_sha512(), NULL) != 1) {
        EVP_MD_CTX_free(ctx);
        return SG_ERR_UNKNOWN;
    }
    *digest_context = ctx;
    return SG_SUCCESS;
#endif
}

int signal_vala_sha512_digest_update(void *digest_context, const uint8_t *data, size_t data_len, void *user_data) {
#ifdef GCRYPT
    gcry_md_hd_t* ctx = digest_context;

    gcry_md_write(*ctx, data, data_len);

    return SG_SUCCESS;
#else
    EVP_MD_CTX *ctx = digest_context;
    if (EVP_DigestUpdate(ctx, data, data_len) != 1) {
        return SG_ERR_UNKNOWN;
    }
    return SG_SUCCESS;
#endif
}

int signal_vala_sha512_digest_final(void *digest_context, signal_buffer **output, void *user_data) {
#ifdef GCRYPT
    size_t len = gcry_md_get_algo_dlen(GCRY_MD_SHA512);
    gcry_md_hd_t* ctx = digest_context;

    uint8_t* md = gcry_md_read(*ctx, GCRY_MD_SHA512);
    if (!md) return SG_ERR_UNKNOWN;

    gcry_md_reset(*ctx);

    signal_buffer *output_buffer = signal_buffer_create(md, len);
    free(md);
    if (!output_buffer) return SG_ERR_NOMEM;

    *output = output_buffer;

    return SG_SUCCESS;
#else
    EVP_MD_CTX *ctx = digest_context;
    size_t len = EVP_MD_size(EVP_sha512());
    signal_buffer *output_buffer = signal_buffer_alloc(len);
    if (!output_buffer) {
        return SG_ERR_NOMEM;
    }
    if (EVP_DigestSignFinal(ctx, signal_buffer_data(output_buffer), &len) != 1) {
        signal_buffer_free(output_buffer);
        return SG_ERR_UNKNOWN;
    }
    if (len != EVP_MD_size(EVP_sha512())) {
        signal_buffer_free(output_buffer);
        return SG_ERR_UNKNOWN;
    }
    *output = output_buffer;
    return SG_SUCCESS;
#endif
}

void signal_vala_sha512_digest_cleanup(void *digest_context, void *user_data) {
#ifdef GCRYPT
    gcry_md_hd_t* ctx = digest_context;
    if (ctx) {
        gcry_md_close(*ctx);
        free(ctx);
    }
#else
    EVP_MD_CTX *ctx = digest_context;
    if (ctx) {
        EVP_MD_CTX_free(ctx);
    }
#endif
}

#ifdef GCRYPT
static int aes_cipher(int cipher, size_t key_len, int* algo, int* mode) {
    switch (key_len) {
        case 16:
            *algo = GCRY_CIPHER_AES128;
            break;
        case 24:
            *algo = GCRY_CIPHER_AES192;
            break;
        case 32:
            *algo = GCRY_CIPHER_AES256;
            break;
        default:
            return SG_ERR_UNKNOWN;
    }
    switch (cipher) {
        case SG_CIPHER_AES_CBC_PKCS5:
            *mode = GCRY_CIPHER_MODE_CBC;
            break;
        case SG_CIPHER_AES_CTR_NOPADDING:
            *mode = GCRY_CIPHER_MODE_CTR;
            break;
        case SG_CIPHER_AES_GCM_NOPADDING:
            *mode = GCRY_CIPHER_MODE_GCM;
            break;
        default:
            return SG_ERR_UNKNOWN;
    }
    return SG_SUCCESS;
}
#else
static const EVP_CIPHER *aes_cipher(int cipher, size_t key_len) {
    switch (cipher) {
        case SG_CIPHER_AES_CBC_PKCS5:
            switch (key_len) {
                case 16: return EVP_aes_128_cbc();
                case 24: return EVP_aes_192_cbc();
                case 32: return EVP_aes_256_cbc();
            }
            break;
        case SG_CIPHER_AES_CTR_NOPADDING:
            switch (key_len) {
                case 16: return EVP_aes_128_ctr();
                case 24: return EVP_aes_192_ctr();
                case 32: return EVP_aes_256_ctr();
            }
            break;
        case SG_CIPHER_AES_GCM_NOPADDING:
            switch (key_len) {
                case 16: return EVP_aes_128_gcm();
                case 24: return EVP_aes_192_gcm();
                case 32: return EVP_aes_256_gcm();
            }
            break;

    }
    return NULL;
}
#endif

int signal_vala_encrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *plaintext, size_t plaintext_len,
        void *user_data) {
#ifdef GCRYPT
    int algo, mode, error_code = SG_ERR_UNKNOWN;
    if (aes_cipher(cipher, key_len, &algo, &mode)) return SG_ERR_INVAL;

    gcry_cipher_hd_t ctx = {0};

    if (gcry_cipher_open(&ctx, algo, mode, 0)) return SG_ERR_NOMEM;

    signal_buffer* padded = 0;
    signal_buffer* out_buf = 0;
    goto no_error;
error:
    gcry_cipher_close(ctx);
    if (padded != 0) {
        signal_buffer_bzero_free(padded);
    }
    if (out_buf != 0) {
        signal_buffer_free(out_buf);
    }
    return error_code;
no_error:

    if (gcry_cipher_setkey(ctx, key, key_len)) goto error;

    uint8_t tag_len = 0, pad_len = 0;
    switch (cipher) {
        case SG_CIPHER_AES_CBC_PKCS5:
            if (gcry_cipher_setiv(ctx, iv, iv_len)) goto error;
            pad_len = 16 - (plaintext_len % 16);
            if (pad_len == 0) pad_len = 16;
            break;
        case SG_CIPHER_AES_CTR_NOPADDING:
            if (gcry_cipher_setctr(ctx, iv, iv_len)) goto error;
            break;
        case SG_CIPHER_AES_GCM_NOPADDING:
            if (gcry_cipher_setiv(ctx, iv, iv_len)) goto error;
            tag_len = 16;
            break;
        default:
            return SG_ERR_UNKNOWN;
    }

    size_t padded_len = plaintext_len + pad_len;
    padded = signal_buffer_alloc(padded_len);
    if (padded == 0) {
        error_code = SG_ERR_NOMEM;
        goto error;
    }

    memset(signal_buffer_data(padded) + plaintext_len, pad_len, pad_len);
    memcpy(signal_buffer_data(padded), plaintext, plaintext_len);

    out_buf = signal_buffer_alloc(padded_len + tag_len);
    if (out_buf == 0) {
        error_code = SG_ERR_NOMEM;
        goto error;
    }

    if (gcry_cipher_encrypt(ctx, signal_buffer_data(out_buf), padded_len, signal_buffer_data(padded), padded_len)) goto error;

    if (tag_len > 0) {
        if (gcry_cipher_gettag(ctx, signal_buffer_data(out_buf) + padded_len, tag_len)) goto error;
    }

    *output = out_buf;
    out_buf = 0;

    signal_buffer_bzero_free(padded);
    padded = 0;

    gcry_cipher_close(ctx);
    return SG_SUCCESS;
#else
    int result = 0;
    uint8_t *out_buf = NULL;
    const EVP_CIPHER *evp_cipher = aes_cipher(cipher, key_len);
    if (!evp_cipher) {
        // fprintf(stderr, "invalid AES mode or key size: %zu\n", key_len);
        return SG_ERR_INVAL;
    }
    if (plaintext_len > INT_MAX - EVP_CIPHER_block_size(evp_cipher)) {
        // fprintf(stderr, "invalid plaintext length: %zu\n", plaintext_len);
        return SG_ERR_UNKNOWN;
    }
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    int buf_extra = 0;

    if (cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        // In GCM mode we use the last 16 bytes as auth tag
        buf_extra += 16;

        if (EVP_EncryptInit_ex(ctx, evp_cipher, NULL, NULL, NULL) != 1) {
            // fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL) != 1) {
            // fprintf(stderr, "cannot set iv size\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        if (EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv) != 1) {
            // fprintf(stderr, "cannot set key/iv\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    } else {
        // TODO: set ivlen?
        if (EVP_EncryptInit_ex(ctx, evp_cipher, 0, key, iv) != 1) {
            // fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    if (cipher == SG_CIPHER_AES_CTR_NOPADDING || cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        if (EVP_CIPHER_CTX_set_padding(ctx, 0) != 1) {
            // fprintf(stderr, "cannot set padding\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    out_buf = malloc(plaintext_len + EVP_CIPHER_block_size(evp_cipher) + buf_extra);
    if (!out_buf) {
        // fprintf(stderr, "cannot allocate output buffer\n");
        result = SG_ERR_NOMEM;
        goto complete;
    }

    int out_len = 0;
    if (EVP_EncryptUpdate(ctx, out_buf, &out_len, plaintext, plaintext_len) != 1) {
        // fprintf(stderr, "cannot encrypt plaintext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    int final_len = 0;
    if (EVP_EncryptFinal_ex(ctx, out_buf + out_len, &final_len) != 1) {
        // fprintf(stderr, "cannot finish encrypting plaintext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    if (cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, out_buf + out_len + final_len) != 1) {
            // fprintf(stderr, "cannot get tag\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    *output = signal_buffer_create(out_buf, out_len + final_len + buf_extra);

complete:
    EVP_CIPHER_CTX_free(ctx);
    if (out_buf) {
        free(out_buf);
    }
    return result;
#endif
}

int signal_vala_decrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *ciphertext, size_t ciphertext_len,
        void *user_data) {
#ifdef GCRYPT
    int algo, mode, error_code = SG_ERR_UNKNOWN;
    *output = 0;
    if (aes_cipher(cipher, key_len, &algo, &mode)) return SG_ERR_INVAL;
    if (ciphertext_len == 0) return SG_ERR_INVAL;

    gcry_cipher_hd_t ctx = {0};

    if (gcry_cipher_open(&ctx, algo, mode, 0)) return SG_ERR_NOMEM;

    signal_buffer* out_buf = 0;
    goto no_error;
error:
    gcry_cipher_close(ctx);
    if (out_buf != 0) {
        signal_buffer_bzero_free(out_buf);
    }
    return error_code;
no_error:

    if (gcry_cipher_setkey(ctx, key, key_len)) goto error;

    uint8_t tag_len = 0, pkcs_pad = FALSE;
    switch (cipher) {
        case SG_CIPHER_AES_CBC_PKCS5:
            if (gcry_cipher_setiv(ctx, iv, iv_len)) goto error;
            pkcs_pad = TRUE;
            break;
        case SG_CIPHER_AES_CTR_NOPADDING:
            if (gcry_cipher_setctr(ctx, iv, iv_len)) goto error;
            break;
        case SG_CIPHER_AES_GCM_NOPADDING:
            if (gcry_cipher_setiv(ctx, iv, iv_len)) goto error;
            if (ciphertext_len < 16) goto error;
            tag_len = 16;
            break;
        default:
            goto error;
    }

    size_t padded_len = ciphertext_len - tag_len;
    out_buf = signal_buffer_alloc(padded_len);
    if (out_buf == 0) {
        error_code = SG_ERR_NOMEM;
        goto error;
    }

    if (gcry_cipher_decrypt(ctx, signal_buffer_data(out_buf), signal_buffer_len(out_buf), ciphertext, padded_len)) goto error;

    if (tag_len > 0) {
        if (gcry_cipher_checktag(ctx, ciphertext + padded_len, tag_len)) goto error;
    }

    if (pkcs_pad) {
        uint8_t pad_len = signal_buffer_data(out_buf)[padded_len - 1];
        if (pad_len > 16 || pad_len > padded_len) goto error;
        *output = signal_buffer_create(signal_buffer_data(out_buf), padded_len - pad_len);
        signal_buffer_bzero_free(out_buf);
        out_buf = 0;
    } else {
        *output = out_buf;
        out_buf = 0;
    }

    gcry_cipher_close(ctx);
    return SG_SUCCESS;
#else
    int result = 0;
    uint8_t *out_buf = NULL;
    const EVP_CIPHER *evp_cipher = aes_cipher(cipher, key_len);
    if (!evp_cipher) {
        // fprintf(stderr, "invalid AES mode or key size: %zu\n", key_len);
        return SG_ERR_INVAL;
    }
    if (ciphertext_len > INT_MAX - EVP_CIPHER_block_size(evp_cipher)) {
        // fprintf(stderr, "invalid ciphertext length: %zu\n", ciphertext_len);
        return SG_ERR_UNKNOWN;
    }

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();

    if (cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        // In GCM mode we use the last 16 bytes as auth tag
        ciphertext_len -= 16;

        if (EVP_DecryptInit_ex(ctx, evp_cipher, NULL, NULL, NULL) != 1) {
            // fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL) != 1) {
            // fprintf(stderr, "cannot set iv size\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        if (EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv) != 1) {
            // fprintf(stderr, "cannot set key/iv\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    } else {
        // TODO: set ivlen?
        if (EVP_DecryptInit_ex(ctx, evp_cipher, 0, key, iv) != 1) {
            // fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    if (cipher == SG_CIPHER_AES_CTR_NOPADDING || cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        if (EVP_CIPHER_CTX_set_padding(ctx, 0) != 1) {
            // fprintf(stderr, "cannot set padding\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    out_buf = malloc(ciphertext_len + EVP_CIPHER_block_size(evp_cipher));
    if (!out_buf) {
        // fprintf(stderr, "cannot allocate output buffer\n");
        result = SG_ERR_NOMEM;
        goto complete;
    }

    int out_len = 0;
    if (EVP_DecryptUpdate(ctx, out_buf, &out_len, ciphertext, ciphertext_len) != 1) {
        // fprintf(stderr, "cannot decrypt ciphertext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    if (cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, (void *)(ciphertext + ciphertext_len)) != 1) {
            // fprintf(stderr, "cannot set tag\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    int final_len = 0;
    if (EVP_DecryptFinal_ex(ctx, out_buf + out_len, &final_len) != 1) {
        // fprintf(stderr, "cannot finish decrypting ciphertexts\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    *output = signal_buffer_create(out_buf, out_len + final_len);

complete:
    EVP_CIPHER_CTX_free(ctx);
    if (out_buf) {
        free(out_buf);
    }
    return result;
#endif
}

void setup_signal_vala_crypto_provider(signal_context *context)
{
#ifdef GCRYPT
    gcry_check_version(NULL);
#endif

    signal_crypto_provider provider = {
            .random_func = signal_vala_random_generator,
            .hmac_sha256_init_func = signal_vala_hmac_sha256_init,
            .hmac_sha256_update_func = signal_vala_hmac_sha256_update,
            .hmac_sha256_final_func = signal_vala_hmac_sha256_final,
            .hmac_sha256_cleanup_func = signal_vala_hmac_sha256_cleanup,
            .sha512_digest_init_func = signal_vala_sha512_digest_init,
            .sha512_digest_update_func = signal_vala_sha512_digest_update,
            .sha512_digest_final_func = signal_vala_sha512_digest_final,
            .sha512_digest_cleanup_func = signal_vala_sha512_digest_cleanup,
            .encrypt_func = signal_vala_encrypt,
            .decrypt_func = signal_vala_decrypt,
            .user_data = 0
    };

    signal_context_set_crypto_provider(context, &provider);
}
