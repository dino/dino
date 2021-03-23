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
    "src/random.vala"
    "src/srtp.vapi"
CUSTOM_VAPIS
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/gcrypt.vapi"
PACKAGES
    ${CRYPTO_VALA_PACKAGES}
GENERATE_VAPI
    crypto-vala
GENERATE_HEADER
    crypto-vala
)

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/srtp.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/srtp.h" "${CMAKE_BINARY_DIR}/exports/srtp.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/srtp.h"
COMMENT
    Copy header file srtp.h
)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/exports/crypto.vapi
COMMAND
    cat "${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi" "${CMAKE_CURRENT_SOURCE_DIR}/src/srtp.vapi" > "${CMAKE_BINARY_DIR}/exports/crypto.vapi"
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/src/srtp.vapi
)

add_custom_target(crypto-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/crypto.vapi
    ${CMAKE_BINARY_DIR}/exports/srtp.h
)

set(CFLAGS ${VALA_CFLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_definitions(${CFLAGS})
add_library(crypto-vala STATIC ${CRYPTO_VALA_C} src/srtp.c)
add_dependencies(crypto-vala crypto-vapi)
target_link_libraries(crypto-vala ${CRYPTO_VALA_PACKAGES} gcrypt)
set_property(TARGET crypto-vala PROPERTY POSITION_INDEPENDENT_CODE ON)

