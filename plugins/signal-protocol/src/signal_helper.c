#include <signal_helper.h>
#include <signal_protocol_internal.h>

#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <openssl/rand.h>
#include <openssl/sha.h>
#include <openssl/err.h>

signal_type_base* signal_type_ref_vapi(signal_type_base* instance) {
    if (instance->ref_count > 100 || instance->ref_count < 1)
        printf("REF %x -> %d\n", instance, instance->ref_count+1);
    signal_type_ref(instance);
    return instance;
}

signal_type_base* signal_type_unref_vapi(signal_type_base* instance) {
    if (instance->ref_count > 100 || instance->ref_count < 0)
        printf("UNREF %x -> %d\n", instance, instance->ref_count-1);
    signal_type_unref(instance);
    return 0;
}

signal_protocol_address* signal_protocol_address_new() {
    signal_protocol_address* address = malloc(sizeof(signal_protocol_address));
    address->name = 0;
    address->device_id = 0;
    return address;
}

void signal_protocol_address_free(signal_protocol_address* ptr) {
    if (ptr->name) {
        g_free((void*)ptr->name);
    }
    return free(ptr);
}

void signal_protocol_address_set_name(signal_protocol_address* self, const gchar* name) {
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
    if (self->name == 0) return 0;
    gchar* res = g_malloc(sizeof(char) * (self->name_len + 1));
    memcpy(res, self->name, self->name_len);
    res[self->name_len] = 0;
    return res;
}

session_pre_key* session_pre_key_new(uint32_t pre_key_id, ec_key_pair* pair, int* err) {
    session_pre_key* res;
    *err = session_pre_key_create(&res, pre_key_id, pair);
    return res;
}

session_signed_pre_key* session_signed_pre_key_new(uint32_t id, uint64_t timestamp, ec_key_pair* pair, uint8_t* key, int key_len, int* err) {
    session_signed_pre_key* res;
    *err = session_signed_pre_key_create(&res, id, timestamp, pair, key, key_len);
    return res;
}



int signal_vala_random_generator(uint8_t *data, size_t len, void *user_data)
{
    if(RAND_bytes(data, len)) {
        return 0;
    }
    else {
        return SG_ERR_UNKNOWN;
    }
}

int signal_vala_hmac_sha256_init(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data)
{
#if OPENSSL_VERSION_NUMBER >= 0x10100001L
    HMAC_CTX *ctx = HMAC_CTX_new();
#else
    HMAC_CTX *ctx = malloc(sizeof(HMAC_CTX));
    if(!ctx) {
        return SG_ERR_NOMEM;
    }
    HMAC_CTX_init(ctx);
#endif
    *hmac_context = ctx;

    if(HMAC_Init_ex(ctx, key, key_len, EVP_sha256(), 0) != 1) {
        return SG_ERR_UNKNOWN;
    }

    return 0;
}

int signal_vala_hmac_sha256_update(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data)
{
    HMAC_CTX *ctx = hmac_context;
    int result = HMAC_Update(ctx, data, data_len);

    return (result == 1) ? 0 : -1;
}

int signal_vala_hmac_sha256_final(void *hmac_context, signal_buffer **output, void *user_data)
{
    int result = 0;
    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int len = 0;
    HMAC_CTX *ctx = hmac_context;

    if(HMAC_Final(ctx, md, &len) != 1) {
        return SG_ERR_UNKNOWN;
    }

    signal_buffer *output_buffer = signal_buffer_create(md, len);
    if(!output_buffer) {
        result = SG_ERR_NOMEM;
        goto complete;
    }

    *output = output_buffer;

complete:
    return result;
}

void signal_vala_hmac_sha256_cleanup(void *hmac_context, void *user_data)
{
    if(hmac_context) {
        HMAC_CTX *ctx = hmac_context;
#if OPENSSL_VERSION_NUMBER >= 0x10100001L
        HMAC_CTX_free(ctx);
#else
        HMAC_CTX_cleanup(ctx);
        free(ctx);
#endif
    }
}

const EVP_CIPHER *aes_cipher(int cipher, size_t key_len)
{
    if(cipher == SG_CIPHER_AES_CBC_PKCS5) {
        if(key_len == 16) {
            return EVP_aes_128_cbc();
        }
        else if(key_len == 24) {
            return EVP_aes_192_cbc();
        }
        else if(key_len == 32) {
            return EVP_aes_256_cbc();
        }
    }
    else if(cipher == SG_CIPHER_AES_CTR_NOPADDING) {
        if(key_len == 16) {
            return EVP_aes_128_ctr();
        }
        else if(key_len == 24) {
            return EVP_aes_192_ctr();
        }
        else if(key_len == 32) {
            return EVP_aes_256_ctr();
        }
    }
    else if (cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        if(key_len == 16) {
            return EVP_aes_128_gcm();
        }
        else if(key_len == 24) {
            return EVP_aes_192_gcm();
        }
        else if(key_len == 32) {
            return EVP_aes_256_gcm();
        }
    }
    return 0;
}

int signal_vala_sha512_digest_init(void **digest_context, void *user_data)
{
    int result = 0;
    EVP_MD_CTX *ctx;

    ctx = EVP_MD_CTX_create();
    if(!ctx) {
        result = SG_ERR_NOMEM;
        goto complete;
    }

    result = EVP_DigestInit_ex(ctx, EVP_sha512(), 0);
    if(result == 1) {
        result = SG_SUCCESS;
    }
    else {
        result = SG_ERR_UNKNOWN;
    }

complete:
    if(result < 0) {
        if(ctx) {
            EVP_MD_CTX_destroy(ctx);
        }
    }
    else {
        *digest_context = ctx;
    }
    return result;
}

int signal_vala_sha512_digest_update(void *digest_context, const uint8_t *data, size_t data_len, void *user_data)
{
    EVP_MD_CTX *ctx = digest_context;

    int result = EVP_DigestUpdate(ctx, data, data_len);

    return (result == 1) ? SG_SUCCESS : SG_ERR_UNKNOWN;
}

int signal_vala_sha512_digest_final(void *digest_context, signal_buffer **output, void *user_data)
{
    int result = 0;
    unsigned char md[EVP_MAX_MD_SIZE];
    unsigned int len = 0;
    EVP_MD_CTX *ctx = digest_context;

    result = EVP_DigestFinal_ex(ctx, md, &len);
    if(result == 1) {
        result = SG_SUCCESS;
    }
    else {
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    result = EVP_DigestInit_ex(ctx, EVP_sha512(), 0);
    if(result == 1) {
        result = SG_SUCCESS;
    }
    else {
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    signal_buffer *output_buffer = signal_buffer_create(md, len);
    if(!output_buffer) {
        result = SG_ERR_NOMEM;
        goto complete;
    }

    *output = output_buffer;

complete:
    return result;
}

void signal_vala_sha512_digest_cleanup(void *digest_context, void *user_data)
{
    EVP_MD_CTX *ctx = digest_context;
    EVP_MD_CTX_destroy(ctx);
}

int signal_vala_encrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *plaintext, size_t plaintext_len,
        void *user_data)
{
    int result = 0;
    uint8_t *out_buf = 0;

    const EVP_CIPHER *evp_cipher = aes_cipher(cipher, key_len);
    if(!evp_cipher) {
        fprintf(stderr, "invalid AES mode or key size: %zu\n", key_len);
        return SG_ERR_UNKNOWN;
    }

    if(iv_len != 16) {
        fprintf(stderr, "invalid AES IV size: %zu\n", iv_len);
        return SG_ERR_UNKNOWN;
    }

    if(plaintext_len > INT_MAX - EVP_CIPHER_block_size(evp_cipher)) {
        fprintf(stderr, "invalid plaintext length: %zu\n", plaintext_len);
        return SG_ERR_UNKNOWN;
    }

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();

    int buf_extra = 0;

    if(cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        // In GCM mode we use the last 16 bytes as auth tag
        buf_extra += 16;

        result = EVP_EncryptInit_ex(ctx, evp_cipher, NULL, NULL, NULL);
        if(!result) {
            fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        result = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 16, NULL);
        if(!result) {
            fprintf(stderr, "cannot set iv size\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        result = EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv);
        if(!result) {
            fprintf(stderr, "cannot set key/iv\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    } else {
        result = EVP_EncryptInit_ex(ctx, evp_cipher, 0, key, iv);
        if(!result) {
            fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    if(cipher == SG_CIPHER_AES_CTR_NOPADDING || cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        result = EVP_CIPHER_CTX_set_padding(ctx, 0);
        if(!result) {
            fprintf(stderr, "cannot set padding\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    out_buf = malloc(sizeof(uint8_t) * (plaintext_len + EVP_CIPHER_block_size(evp_cipher) + buf_extra));
    if(!out_buf) {
        fprintf(stderr, "cannot allocate output buffer\n");
        result = SG_ERR_NOMEM;
        goto complete;
    }

    int out_len = 0;
    result = EVP_EncryptUpdate(ctx,
        out_buf, &out_len, plaintext, plaintext_len);
    if(!result) {
        fprintf(stderr, "cannot encrypt plaintext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    int final_len = 0;
    result = EVP_EncryptFinal_ex(ctx, out_buf + out_len, &final_len);
    if(!result) {
        fprintf(stderr, "cannot finish encrypting plaintext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    if(cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        result = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, out_buf + (out_len + final_len));
        if(!result) {
            fprintf(stderr, "cannot get tag\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    *output = signal_buffer_create(out_buf, out_len + final_len + buf_extra);

complete:
    EVP_CIPHER_CTX_free(ctx);
    if(out_buf) {
        free(out_buf);
    }
    return result;
}

int signal_vala_decrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *ciphertext, size_t ciphertext_len,
        void *user_data)
{
    int result = 0;
    uint8_t *out_buf = 0;

    const EVP_CIPHER *evp_cipher = aes_cipher(cipher, key_len);
    if(!evp_cipher) {
        fprintf(stderr, "invalid AES mode or key size: %zu\n", key_len);
        return SG_ERR_INVAL;
    }

    if(iv_len != 16) {
        fprintf(stderr, "invalid AES IV size: %zu\n", iv_len);
        return SG_ERR_INVAL;
    }

    if(ciphertext_len > INT_MAX - EVP_CIPHER_block_size(evp_cipher)) {
        fprintf(stderr, "invalid ciphertext length: %zu\n", ciphertext_len);
        return SG_ERR_UNKNOWN;
    }

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();

    if(cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        // In GCM mode we use the last 16 bytes as auth tag
        ciphertext_len -= 16;

        result = EVP_DecryptInit_ex(ctx, evp_cipher, NULL, NULL, NULL);
        if(!result) {
            fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        result = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 16, NULL);
        if(!result) {
            fprintf(stderr, "cannot set iv size\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }

        result = EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv);
        if(!result) {
            fprintf(stderr, "cannot set key/iv\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    } else {
        result = EVP_DecryptInit_ex(ctx, evp_cipher, 0, key, iv);
        if(!result) {
            fprintf(stderr, "cannot initialize cipher\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    if(cipher == SG_CIPHER_AES_CTR_NOPADDING || cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        result = EVP_CIPHER_CTX_set_padding(ctx, 0);
        if(!result) {
            fprintf(stderr, "cannot set padding\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    out_buf = malloc(sizeof(uint8_t) * (ciphertext_len + EVP_CIPHER_block_size(evp_cipher)));
    if(!out_buf) {
        fprintf(stderr, "cannot allocate output buffer\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    int out_len = 0;
    result = EVP_DecryptUpdate(ctx,
        out_buf, &out_len, ciphertext, ciphertext_len);
    if(!result) {
        fprintf(stderr, "cannot decrypt ciphertext\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    if(cipher == SG_CIPHER_AES_GCM_NOPADDING) {
        result = EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, (uint8_t*)ciphertext + ciphertext_len);
        if(!result) {
            fprintf(stderr, "cannot set tag\n");
            result = SG_ERR_UNKNOWN;
            goto complete;
        }
    }

    int final_len = 0;
    result = EVP_DecryptFinal_ex(ctx, out_buf + out_len, &final_len);
    if(!result) {
        fprintf(stderr, "cannot finish decrypting ciphertexts\n");
        result = SG_ERR_UNKNOWN;
        goto complete;
    }

    *output = signal_buffer_create(out_buf, out_len + final_len);

complete:
    EVP_CIPHER_CTX_free(ctx);
    if(out_buf) {
        free(out_buf);
    }
    return result;
}

void setup_signal_vala_crypto_provider(signal_context *context)
{
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