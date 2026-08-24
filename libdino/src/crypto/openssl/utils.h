#ifndef DINO_OPENSSL_UTILS_H
#define DINO_OPENSSL_UTILS_H

#include <openssl/evp.h>

EVP_PKEY *EVP_PKEY_new_generate_ecdsa (const char* curve);

#endif //DINO_OPENSSL_UTILS_H