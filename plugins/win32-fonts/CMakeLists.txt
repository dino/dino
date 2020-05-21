find_packages(WIN32_FONTS_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
)

set(RESOURCE_LIST
    larger.css
)

compile_gresources(
    WIN32_FONTS_GRESOURCES_TARGET
    WIN32_FONTS_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /im/dino/Dino/win32-fonts
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(WIN32_FONTS_VALA_C
SOURCES
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${WIN32_FONTS_PACKAGES}
GRESOURCES
    ${WIN32_FONTS_GRESOURCES_XML}
)

add_definitions(${VALA_CFLAGS})
add_library(win32-fonts SHARED ${WIN32_FONTS_VALA_C} ${WIN32_FONTS_GRESOURCES_TARGET})
target_link_libraries(win32-fonts libdino ${WIN32_FONTS_PACKAGES})
set_target_properties(win32-fonts PROPERTIES PREFIX "")
set_target_properties(win32-fonts PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS win32-fonts ${PLUGIN_INSTALL})
