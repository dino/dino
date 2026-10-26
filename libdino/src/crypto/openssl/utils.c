#include "utils.h"
#include <openssl/opensslv.h>
#include <openssl/ec.h>

#if defined(OPENSSL_VERSION_NUMBER) && OPENSSL_VERSION_NUMBER >= 0x30000000L
// This is for OpenSSL 3.0.0 and newer

EVP_PKEY *EVP_PKEY_new_generate_ecdsa (const char* curve) {
    // Generate EVP_PKEY directly
    EVP_PKEY *pkey = EVP_EC_gen (curve);
    return pkey;
}

#else
// This is for OpenSSL before 3.0.0 and forks of earlier OpenSSL versions like LibreSSL

EVP_PKEY *EVP_PKEY_new_generate_ecdsa (const char* curve) {
    // Get NID from curve name
    int nid = OBJ_sn2nid (curve);
    if (nid == NID_undef) return NULL;

    // Create EC_KEY
    EC_KEY *ec_key = EC_KEY_new_by_curve_name (nid);
    if (!ec_key) return NULL;

    // Generate key
    if (!EC_KEY_generate_key (ec_key)) {
        EC_KEY_free (ec_key);
        return NULL;
    }

    // Create EVP_PKEY
    EVP_PKEY *pkey = EVP_PKEY_new ();
    if (!pkey) {
        EC_KEY_free (ec_key);
        return NULL;
    }

    // Assign EC_KEY to EVP_PKEY
    if (!EVP_PKEY_assign_EC_KEY (pkey, ec_key)) {
        EC_KEY_free (ec_key);
        return NULL;
    }

    // EVP_PKEY_assign_EC_KEY takes ownership of ec_key, no need to free it explicitly
    return pkey;
}

#endif
