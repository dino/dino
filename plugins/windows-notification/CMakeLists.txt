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
    src/helper.vala
    src/wintoast.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${WINDOWS_NOTIFICATION_PACKAGES}
)

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/DinoWinToastLib.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastLib.h" "${CMAKE_BINARY_DIR}/exports/DinoWinToastLib.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastLib.h"
COMMENT
    Copy header file DinoWinToastLib.h
)

add_definitions(${VALA_CFLAGS})
add_library(windows-notification SHARED ${WINDOWS_NOTIFICATION_VALA_C} ${CMAKE_BINARY_DIR}/exports/DinoWinToastLib.h)
target_link_libraries(windows-notification libdino ${WINDOWS_NOTIFICATION_PACKAGES} "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastLib.lib")
set_target_properties(windows-notification PROPERTIES PREFIX "")
set_target_properties(windows-notification PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS windows-notification ${PLUGIN_INSTALL})
