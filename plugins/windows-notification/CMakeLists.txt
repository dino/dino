set(GETTEXT_PACKAGE "dino-windows-notifications")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../main/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

project(windows-notification)

find_packages(WINDOWS_NOTIFICATION_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK4
)

vala_precompile(WINDOWS_NOTIFICATION_VALA_C
SOURCES
    src/windows_notifications_plugin.vala
    src/windows_notifications_register_plugin.vala
    src/toast_notification_builder.vala
    src/win_notification_provider.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/win32.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/winrt.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/shortcutcreator.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/enums.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/winrt_windows_ui_notifications.vapi
PACKAGES
    ${WINDOWS_NOTIFICATION_PACKAGES}
)

set(WINDOWS_API_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/gobject/winrt-enums.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/gobject/winrt-event-token.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/gobject/winrt-toast-notification.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/gobject/winrt-toast-notifier.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/gobject/winrt.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/win32.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/converter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/dyn_mod.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/ginvoke.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/api/src/shortcutcreator.cpp
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_library(windows-notification SHARED ${WINDOWS_NOTIFICATION_VALA_C} ${WINDOWS_API_SOURCES})
add_dependencies(windows-notification ${GETTEXT_PACKAGE}-translations)

target_include_directories(windows-notification
    PRIVATE
    ${PROJECT_SOURCE_DIR}/api/include
    ${PROJECT_SOURCE_DIR}/api/include/gobject
    ${PROJECT_SOURCE_DIR}/yolort/include
)

find_library(shlwapi_LIBRARY shlwapi libshlwapi libshlwapi.a HINTS ${CMAKE_C_IMPLICIT_LINK_DIRECTORIES})
if(NOT shlwapi_LIBRARY)
    message(FATAL_ERROR "shlwapi library not found")
endif(NOT shlwapi_LIBRARY)

find_library(ntdll_LIBRARY ntdll libntdll libntdll.a HINTS ${CMAKE_C_IMPLICIT_LINK_DIRECTORIES})
if(NOT ntdll_LIBRARY)
    message(FATAL_ERROR "ntdll library not found")
endif(NOT ntdll_LIBRARY)

target_link_libraries(windows-notification libdino ${shlwapi_LIBRARY} ${ntdll_LIBRARY} ${WINDOWS_NOTIFICATION_PACKAGES})
target_compile_features(windows-notification PRIVATE cxx_std_17)
target_compile_definitions(windows-notification PRIVATE WINRT_GLIB_H_INSIDE)
target_compile_options(windows-notification PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-iquote ${PROJECT_SOURCE_DIR}/yolort/include/winrt/yolort_impl>)

set_target_properties(windows-notification PROPERTIES PREFIX "")
set_target_properties(windows-notification PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS windows-notification ${PLUGIN_INSTALL})
