#ifndef GPGME_FIX
#define GPGME_FIX 1

#include <glib.h>
#include <gpgme.h>

extern GRecMutex gpgme_global_mutex;

gpgme_key_t gpgme_key_ref_vapi (gpgme_key_t key);
gpgme_key_t gpgme_key_unref_vapi (gpgme_key_t key);

#endif
