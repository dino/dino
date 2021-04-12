find_package(Nice 0.1.15 REQUIRED)
find_package(GnuTLS REQUIRED)
find_packages(ICE_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
)

vala_precompile(ICE_VALA_C
SOURCES
    src/dtls_srtp.vala
    src/module.vala
    src/plugin.vala
    src/transport_parameters.vala
    src/util.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/nice.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/gnutls.vapi
PACKAGES
    ${ICE_PACKAGES}
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="ice")
add_library(ice SHARED ${ICE_VALA_C})
target_link_libraries(ice libdino crypto-vala ${ICE_PACKAGES} nice gnutls)
set_target_properties(ice PROPERTIES PREFIX "")
set_target_properties(ice PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS ice ${PLUGIN_INSTALL})
