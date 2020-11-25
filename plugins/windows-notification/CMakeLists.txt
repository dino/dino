set(GETTEXT_PACKAGE "dino-windows-notifications")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../main/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

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
    src/win_notification_provider.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/DinoWinToastLib.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/DinoWinToastTemplate.vapi
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

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/DinoWinToastTemplate.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastTemplate.h" "${CMAKE_BINARY_DIR}/exports/DinoWinToastTemplate.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastTemplate.h"
COMMENT
    Copy header file DinoWinToastTemplate.h
)

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/DinoWinToastDllExport.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastDllExport.h" "${CMAKE_BINARY_DIR}/exports/DinoWinToastDllExport.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastDllExport.h"
COMMENT
    Copy header file DinoWinToastDllExport.h
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_library(windows-notification SHARED ${WINDOWS_NOTIFICATION_VALA_C} ${CMAKE_BINARY_DIR}/exports/DinoWinToastLib.h ${CMAKE_BINARY_DIR}/exports/DinoWinToastTemplate.h ${CMAKE_BINARY_DIR}/exports/DinoWinToastDllExport.h)
add_dependencies(omemo ${GETTEXT_PACKAGE}-translations)

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(WINTOASTLIB "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastLib_AMD64.lib")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(WINTOASTLIB "${CMAKE_CURRENT_SOURCE_DIR}/src/DinoWinToastLib_x86.lib")
endif()

target_link_libraries(windows-notification libdino ${WINDOWS_NOTIFICATION_PACKAGES} ${WINTOASTLIB})
set_target_properties(windows-notification PROPERTIES PREFIX "")
set_target_properties(windows-notification PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS windows-notification ${PLUGIN_INSTALL})
