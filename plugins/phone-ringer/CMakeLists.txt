find_packages(PHONE_RINGER_PACKAGES REQUIRED
    Canberra
    Gee
    GLib
    GModule
    GObject
    GDKPixbuf2
)

vala_precompile(PHONE_RINGER_VALA_C
SOURCES
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${PHONE_RINGER_PACKAGES}
)

add_definitions(${VALA_CFLAGS})
add_library(phone-ringer SHARED ${PHONE_RINGER_VALA_C})
target_link_libraries(phone-ringer libdino ${PHONE_RINGER_PACKAGES})
set_target_properties(phone-ringer PROPERTIES PREFIX "")
set_target_properties(phone-ringer PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS phone-ringer ${PLUGIN_INSTALL})
