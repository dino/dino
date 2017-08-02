find_packages(HTTP_FILES_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
    Soup
)

vala_precompile(HTTP_FILES_VALA_C
SOURCES
    src/contact_titlebar_entry.vala
    src/manager.vala
    src/plugin.vala
    src/register_plugin.vala
    src/upload_stream_module.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${HTTP_FILES_PACKAGES}
)

add_definitions(${VALA_CFLAGS})
add_library(http-files SHARED ${HTTP_FILES_VALA_C})
target_link_libraries(http-files libdino ${HTTP_FILES_PACKAGES})
set_target_properties(http-files PROPERTIES PREFIX "")
set_target_properties(http-files PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS http-files ${PLUGIN_INSTALL})
