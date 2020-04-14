find_packages(ICE_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
    Nice
)

vala_precompile(ICE_VALA_C
SOURCES
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${ICE_PACKAGES}
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_definitions(${VALA_CFLAGS})
add_library(ice SHARED ${ICE_VALA_C})
target_link_libraries(ice libdino ${ICE_PACKAGES})
set_target_properties(ice PROPERTIES PREFIX "")
set_target_properties(ice PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS ice ${PLUGIN_INSTALL})
