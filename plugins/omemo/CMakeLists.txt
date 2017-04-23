set(GETTEXT_PACKAGE "dino-omemo")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

find_packages(OMEMO_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
)

vala_precompile(OMEMO_VALA_C
SOURCES
    src/account_settings_entry.vala
    src/account_settings_widget.vala
    src/bundle.vala
    src/database.vala
    src/encrypt_state.vala
    src/encryption_list_entry.vala
    src/manager.vala
    src/message_flag.vala
    src/plugin.vala
    src/pre_key_store.vala
    src/register_plugin.vala
    src/session_store.vala
    src/signed_pre_key_store.vala
    src/stream_module.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
PACKAGES
    ${OMEMO_PACKAGES}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_library(omemo SHARED ${OMEMO_VALA_C})
add_dependencies(omemo ${GETTEXT_PACKAGE}-translations)
target_link_libraries(omemo libdino signal-protocol-vala ${OMEMO_PACKAGES})
set_target_properties(omemo PROPERTIES PREFIX "")
set_target_properties(omemo PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS omemo ${PLUGIN_INSTALL})