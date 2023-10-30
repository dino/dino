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
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/libgcrypt.vapi"
    "${CMAKE_CURRENT_SOURCE_DIR}/vapi/libsrtp2.vapi"
PACKAGES
    ${CRYPTO_VALA_PACKAGES}
GENERATE_VAPI
    crypto-vala
GENERATE_HEADER
    crypto-vala
)

add_custom_target(crypto-vala-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.deps
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="crypto-vala")
add_library(crypto-vala SHARED ${CRYPTO_VALA_C})
add_dependencies(crypto-vala crypto-vala-vapi)
target_link_libraries(crypto-vala ${CRYPTO_VALA_PACKAGES} gcrypt libsrtp2)
set_target_properties(crypto-vala PROPERTIES VERSION 0.0 SOVERSION 0)

install(TARGETS crypto-vala ${TARGET_INSTALL})
install(FILES ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi ${CMAKE_BINARY_DIR}/exports/crypto-vala.deps DESTINATION ${VAPI_INSTALL_DIR})
install(FILES ${CMAKE_BINARY_DIR}/exports/crypto-vala.h DESTINATION ${INCLUDE_INSTALL_DIR})
