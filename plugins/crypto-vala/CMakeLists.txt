find_package(GCrypt REQUIRED)
find_package(Srtp2 REQUIRED)
find_packages(CRYPTO_VALA_PACKAGES REQUIRED
    GLib
    GObject
    GIO
)

vala_precompile(CRYPTO_VALA_C
SOURCES
    "src/cipher.vala"
    "src/cipher_converter.vala"
    "src/error.vala"
    "src/random.vala"
    "src/srtp.vala"
CUSTOM_VAPIS
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gcrypt.vapi"
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/libsrtp2.vapi"
PACKAGES
    ${CRYPTO_VALA_PACKAGES}
GENERATE_VAPI
    crypto-vala
GENERATE_HEADER
    crypto-vala
)

set(CFLAGS ${VALA_CFLAGS})
add_definitions(${CFLAGS})
add_library(crypto-vala STATIC ${CRYPTO_VALA_C})
target_link_libraries(crypto-vala ${CRYPTO_VALA_PACKAGES} gcrypt libsrtp2)
set_property(TARGET crypto-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

