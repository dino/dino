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
    src/file_provider.vala
    src/file_sender.vala
    src/message_filter.vala
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${HTTP_FILES_PACKAGES}
)

add_definitions(${VALA_CFLAGS})
add_library(http-files SHARED ${HTTP_FILES_VALA_C})
if(UNIX AND APPLE)
    # for some reason, Dino on OS X can't load plugins named .dylib,
    # even though that's the native dlopen()able extension on OS X.
    add_custom_command(OUTPUT http-files.so COMMAND ${CMAKE_COMMAND} -E create_symlink http-files.dylib ${CMAKE_BINARY_DIR}/plugins/http-files.so)
    add_custom_target(http-files-symlink-workaround DEPENDS http-files.so)
    add_dependencies(http-files http-files-symlink-workaround)
endif(UNIX AND APPLE)
target_link_libraries(http-files libdino ${HTTP_FILES_PACKAGES})
set_target_properties(http-files PROPERTIES PREFIX "")
set_target_properties(http-files PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS http-files ${PLUGIN_INSTALL})
