#include "../omemo/helper.h"
#include <openssl/evp.h>
#include <openssl/rand.h>

int signal_vala_random_generator(uint8_t *data, size_t len, void *user_data) {
    return RAND_bytes(data, len) == 1 ? SG_SUCCESS : SG_ERR_UNKNOWN;
}

struct SIGNAL_VALA_HMAC_CTX {
    EVP_PKEY *pkey;
    EVP_MD_CTX *ctx;
};

int signal_vala_hmac_sha256_init(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data) {
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
}

int signal_vala_hmac_sha256_update(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data) {
    struct SIGNAL_VALA_HMAC_CTX *hmac_ctx = hmac_context;
    if (EVP_DigestSignUpdate(hmac_ctx->ctx, data, data_len) != 1) {
        return SG_ERR_UNKNOWN;
    }
    return SG_SUCCESS;
}

int signal_vala_hmac_sha256_final(void *hmac_context, signal_buffer **output, void *user_data) {
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
}

void signal_vala_hmac_sha256_cleanup(void *hmac_context, void *user_data) {
    struct SIGNAL_VALA_HMAC_CTX *hmac_ctx = hmac_context;
    if (hmac_ctx) {
        EVP_MD_CTX_free(hmac_ctx->ctx);
        EVP_PKEY_free(hmac_ctx->pkey);
        free(hmac_ctx);
    }
}

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

int signal_vala_encrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *plaintext, size_t plaintext_len,
        void *user_data) {
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
}

int signal_vala_decrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *ciphertext, size_t ciphertext_len,
        void *user_data) {
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
}

void setup_signal_vala_crypto_provider(signal_context *context) {
    signal_crypto_provider provider = {
            .random_func = signal_vala_random_generator,
            .hmac_sha256_init_func = signal_vala_hmac_sha256_init,
            .hmac_sha256_update_func = signal_vala_hmac_sha256_update,
            .hmac_sha256_final_func = signal_vala_hmac_sha256_final,
            .hmac_sha256_cleanup_func = signal_vala_hmac_sha256_cleanup,
            .encrypt_func = signal_vala_encrypt,
            .decrypt_func = signal_vala_decrypt,
            .user_data = 0
    };

    signal_context_set_crypto_provider(context, &provider);
}
