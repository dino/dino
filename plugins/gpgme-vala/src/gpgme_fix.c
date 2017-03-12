#include <gpgme_fix.h>

static GRecMutex gpgme_global_mutex = {0};

gpgme_key_t gpgme_key_ref_vapi (gpgme_key_t key) {
    gpgme_key_ref(key);
    return key;
}
gpgme_key_t gpgme_key_unref_vapi (gpgme_key_t key) {
    gpgme_key_unref(key);
    return key;
}