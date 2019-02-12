#ifndef SIGNAL_PROTOCOL_VALA_HELPER
#define SIGNAL_PROTOCOL_VALA_HELPER 1

#include <signal/signal_protocol.h>
#include <string.h>
#include <glib.h>

#define SG_CIPHER_AES_GCM_NOPADDING 1000

signal_type_base* signal_type_ref_vapi(signal_type_base* what);
signal_type_base* signal_type_unref_vapi(signal_type_base* what);

signal_protocol_address* signal_protocol_address_new(const gchar* name, int32_t device_id);
void signal_protocol_address_free(signal_protocol_address* ptr);
void signal_protocol_address_set_name(signal_protocol_address* self, const gchar* name);
gchar* signal_protocol_address_get_name(signal_protocol_address* self);
void signal_protocol_address_set_device_id(signal_protocol_address* self, int32_t device_id);
int32_t signal_protocol_address_get_device_id(signal_protocol_address* self);

session_pre_key* session_pre_key_new(uint32_t pre_key_id, ec_key_pair* pair, int* err);
session_signed_pre_key* session_signed_pre_key_new(uint32_t id, uint64_t timestamp, ec_key_pair* pair, uint8_t* key, int key_len, int* err);

int signal_vala_randomize(uint8_t *data, size_t len);
int signal_vala_random_generator(uint8_t *data, size_t len, void *user_data);
int signal_vala_hmac_sha256_init(void **hmac_context, const uint8_t *key, size_t key_len, void *user_data);
int signal_vala_hmac_sha256_update(void *hmac_context, const uint8_t *data, size_t data_len, void *user_data);
int signal_vala_hmac_sha256_final(void *hmac_context, signal_buffer **output, void *user_data);
void signal_vala_hmac_sha256_cleanup(void *hmac_context, void *user_data);
int signal_vala_sha512_digest_init(void **digest_context, void *user_data);
int signal_vala_sha512_digest_update(void *digest_context, const uint8_t *data, size_t data_len, void *user_data);
int signal_vala_sha512_digest_final(void *digest_context, signal_buffer **output, void *user_data);
void signal_vala_sha512_digest_cleanup(void *digest_context, void *user_data);

int signal_vala_encrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *plaintext, size_t plaintext_len,
        void *user_data);
int signal_vala_decrypt(signal_buffer **output,
        int cipher,
        const uint8_t *key, size_t key_len,
        const uint8_t *iv, size_t iv_len,
        const uint8_t *ciphertext, size_t ciphertext_len,
        void *user_data);
void setup_signal_vala_crypto_provider(signal_context *context);

#endif
