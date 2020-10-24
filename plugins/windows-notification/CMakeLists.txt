find_packages(WINDOWS_NOTIFICATION_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
)

vala_precompile(WINDOWS_NOTIFICATION_VALA_C
SOURCES
    src/plugin.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    #${CMAKE_CURRENT_SOURCE_DIR}/vapi/openal.vapi
PACKAGES
    ${WINDOWS_NOTIFICATION_PACKAGES}
)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/exports/wintoast.h
COMMAND
    cp ${CMAKE_CURRENT_SOURCE_DIR}/src/wintoast.h ${CMAKE_BINARY_DIR}/exports/wintoast.h
DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/wintoast.h
COMMENT
    Copy header file wintoast.h
)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/exports/wintoast.c
COMMAND
    cp ${CMAKE_CURRENT_SOURCE_DIR}/src/wintoast.c ${CMAKE_BINARY_DIR}/exports/wintoast.c
DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/wintoast.c
COMMENT
    Copy header file wintoast.c
)

add_custom_target(wintoast
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/wintoast.h
    ${CMAKE_BINARY_DIR}/exports/wintoast.c
)

add_definitions(${VALA_CFLAGS})
add_library(windows-notification SHARED ${WINDOWS_NOTIFICATION_VALA_C} src/wintoast.c)
target_link_libraries(windows-notification libdino ${WINDOWS_NOTIFICATION_PACKAGES})
add_dependencies(windows-notification wintoast)
set_target_properties(windows-notification PROPERTIES PREFIX "")
set_target_properties(windows-notification PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS windows-notification ${PLUGIN_INSTALL})
