find_packages(NOTIFICATION_SOUND_PACKAGES REQUIRED
    Canberra
    Gee
    GLib
    GModule
    GObject
    GDKPixbuf2
)

vala_precompile(NOTIFICATION_SOUND_VALA_C
SOURCES
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${NOTIFICATION_SOUND_PACKAGES}
)

add_definitions(${VALA_CFLAGS})
add_library(notification-sound SHARED ${NOTIFICATION_SOUND_VALA_C})
target_link_libraries(notification-sound libdino ${NOTIFICATION_SOUND_PACKAGES})
set_target_properties(notification-sound PROPERTIES PREFIX "")
set_target_properties(notification-sound PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS notification-sound ${PLUGIN_INSTALL})
