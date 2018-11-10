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

set(RESOURCE_LIST
    contact_details_dialog.ui
    manage_key_dialog.ui
)

compile_gresources(
    OMEMO_GRESOURCES_TARGET
    OMEMO_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /im/dino/Dino/omemo
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(OMEMO_VALA_C
SOURCES
    src/account_settings_entry.vala
    src/account_settings_widget.vala
    src/bundle.vala
    src/contact_details_provider.vala
    src/contact_details_dialog.vala
    src/database.vala
    src/device_notification_populator.vala
    src/own_notifications.vala
    src/encrypt_state.vala
    src/encryption_list_entry.vala
    src/manage_key_dialog.vala
    src/manager.vala
    src/message_flag.vala
    src/plugin.vala
    src/pre_key_store.vala
    src/register_plugin.vala
    src/session_store.vala
    src/signed_pre_key_store.vala
    src/stream_module.vala
    src/trust_manager.vala
    src/util.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/qrencode.vapi
PACKAGES
    ${OMEMO_PACKAGES}
GRESOURCES
    ${OMEMO_GRESOURCES_XML}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_library(omemo SHARED ${OMEMO_VALA_C} ${OMEMO_GRESOURCES_TARGET})
add_dependencies(omemo ${GETTEXT_PACKAGE}-translations)
target_link_libraries(omemo libdino signal-protocol-vala qrencode ${OMEMO_PACKAGES})
set_target_properties(omemo PROPERTIES PREFIX "")
set_target_properties(omemo PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS omemo ${PLUGIN_INSTALL})
