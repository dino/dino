find_package(GCrypt REQUIRED)
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
CUSTOM_VAPIS
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gcrypt.vapi"
PACKAGES
    ${CRYPTO_VALA_PACKAGES}
GENERATE_VAPI
    crypto-vala
GENERATE_HEADER
    crypto-vala
)

set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_definitions(${CFLAGS})
add_library(crypto-vala ${CRYPTO_VALA_C})
target_link_libraries(crypto-vala ${CRYPTO_VALA_PACKAGES} gcrypt)
set_property(TARGET crypto-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

