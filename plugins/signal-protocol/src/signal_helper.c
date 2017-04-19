#include <signal_helper.h>
#include <signal_protocol_internal.h>

#include <gcrypt.h>

signal_type_base* signal_type_ref_vapi(signal_type_base* instance) {
    g_return_val_if_fail(instance != NULL, NULL);
    signal_type_ref(instance);
    return instance;
}

signal_type_base* signal_type_unref_vapi(signal_type_base* instance) {
    g_return_val_if_fail(instance != NULL, NULL);
    signal_type_unref(instance);
    return NULL;
}

signal_protocol_address* signal_protocol_address_new(const gchar* name, int32_t device_id) {
    g_return_val_if_fail(name != NULL, NULL);
    signal_protocol_address* address = malloc(sizeof(signal_protocol_address));
    address->device_id = NULL;
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
    g_return_val_if_fail(self != NULL, NULL);
    return self->device_id;
}

void signal_protocol_address_set_device_id(signal_protocol_address* self, int32_t device_id) {
    g_return_if_fail(self != NULL);
    self->device_id = device_id;
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



int signal_vala_random_generator(uint8_t *data, size_t len, void *user_data) {
    gcry_randomize(data, len, GCRY_STRONG_RANDOM);
    return SG_SUCCESS;
}

int signal_vala_hmac_sha256_init(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data) {
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
}

int signal_vala_hmac_sha256_update(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data) {
    gcry_mac_hd_t* *ctx = hmac_context;

    if (gcry_mac_write(*ctx, data, data_len)) return SG_ERR_UNKNOWN;

    return SG_SUCCESS;
}

int signal_vala_hmac_sha256_final(void *hmac_context, signal_buffer **output, void *user_data) {
    size_t len = gcry_mac_get_algo_maclen(GCRY_MAC_HMAC_SHA256);
    uint8_t md[len];
    gcry_mac_hd_t* ctx = hmac_context;

    if (gcry_mac_read(*ctx, md, &len)) return SG_ERR_UNKNOWN;

    signal_buffer *output_buffer = signal_buffer_create(md, len);
    if (!output_buffer) return SG_ERR_NOMEM;

    *output = output_buffer;

    return SG_SUCCESS;
}

void signal_vala_hmac_sha256_cleanup(void *hmac_context, void *user_data) {
    gcry_mac_hd_t* ctx = hmac_context;
    if (ctx) {
        gcry_mac_close(*ctx);
        free(ctx);
    }
}

int signal_vala_sha512_digest_init(void **digest_context, void *user_data) {
    gcry_md_hd_t* ctx = malloc(sizeof(gcry_mac_hd_t));
    if (!ctx) return SG_ERR_NOMEM;

    if (gcry_md_open(ctx, GCRY_MD_SHA512, 0)) {
        free(ctx);
        return SG_ERR_UNKNOWN;
    }

    *digest_context = ctx;

    return SG_SUCCESS;
}

int signal_vala_sha512_digest_update(void *digest_context, const uint8_t *data, size_t data_len, void *user_data) {
    gcry_md_hd_t* ctx = digest_context;

    gcry_md_write(*ctx, data, data_len);

    return SG_SUCCESS;
}

int signal_vala_sha512_digest_final(void *digest_context, signal_buffer **output, void *user_data) {
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
}

void signal_vala_sha512_digest_cleanup(void *digest_context, void *user_data) {
    gcry_md_hd_t* ctx = digest_context;
    if (ctx) {
        gcry_md_close(*ctx);
        free(ctx);
    }
}

const int aes_cipher(int cipher, size_t key_len, int* algo, int* mode) {
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

int signal_vala_encrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *plaintext, size_t plaintext_len,
        void *user_data) {
    int algo, mode;
    if (aes_cipher(cipher, key_len, &algo, &mode)) return SG_ERR_UNKNOWN;

    if (iv_len != 16) return SG_ERR_UNKNOWN;

    gcry_cipher_hd_t ctx = {0};

    if (gcry_cipher_open(&ctx, algo, mode, 0)) return SG_ERR_UNKNOWN;

    goto no_error;
error:
    gcry_cipher_close(ctx);
    return SG_ERR_UNKNOWN;
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
    uint8_t padded[padded_len];
    memset(padded + plaintext_len, pad_len, pad_len);
    memcpy(padded, plaintext, plaintext_len);

    uint8_t out_buf[padded_len + tag_len];

    if (gcry_cipher_encrypt(ctx, out_buf, padded_len, padded, padded_len)) goto error;

    if (tag_len > 0) {
        if (gcry_cipher_gettag(ctx, out_buf + padded_len, tag_len)) goto error;
    }

    *output = signal_buffer_create(out_buf, padded_len + tag_len);

    gcry_cipher_close(ctx);
    return SG_SUCCESS;
}

int signal_vala_decrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *ciphertext, size_t ciphertext_len,
        void *user_data) {
    int algo, mode;
    if (aes_cipher(cipher, key_len, &algo, &mode)) return SG_ERR_UNKNOWN;

    if (iv_len != 16) return SG_ERR_UNKNOWN;

    gcry_cipher_hd_t ctx = {0};

    if (gcry_cipher_open(&ctx, algo, mode, 0)) return SG_ERR_UNKNOWN;

    goto no_error;
error:
    gcry_cipher_close(ctx);
    return SG_ERR_UNKNOWN;
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
            return SG_ERR_UNKNOWN;
    }

    size_t padded_len = ciphertext_len - tag_len;
    uint8_t out_buf[padded_len];

    if (gcry_cipher_decrypt(ctx, out_buf, padded_len, ciphertext, padded_len)) goto error;

    if (tag_len > 0) {
        if (gcry_cipher_checktag(ctx, ciphertext + padded_len, tag_len)) goto error;
    }

    if (pkcs_pad) {
        uint8_t pad_len = out_buf[padded_len - 1];
        if (pad_len > 16) goto error;
        *output = signal_buffer_create(out_buf, padded_len - pad_len);
    } else {
        *output = signal_buffer_create(out_buf, padded_len);
    }

    gcry_cipher_close(ctx);
    return SG_SUCCESS;
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