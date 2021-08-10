set(GETTEXT_PACKAGE "dino-omemo")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

find_package(Qrencode REQUIRED)
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
    src/dtls_srtp_verification_draft.vala
    src/plugin.vala
    src/register_plugin.vala
    src/trust_level.vala

    src/file_transfer/file_decryptor.vala
    src/file_transfer/file_encryptor.vala
    src/jingle/jingle_helper.vala
    src/jingle/jet_omemo.vala

    src/logic/database.vala
    src/logic/decrypt.vala
    src/logic/encrypt.vala
    src/logic/manager.vala
    src/logic/pre_key_store.vala
    src/logic/session_store.vala
    src/logic/signed_pre_key_store.vala
    src/logic/trust_manager.vala

    src/protocol/bundle.vala
    src/protocol/message_flag.vala
    src/protocol/stream_module.vala

    src/ui/account_settings_entry.vala
    src/ui/account_settings_widget.vala
    src/ui/bad_messages_populator.vala
    src/ui/call_encryption_entry.vala
    src/ui/contact_details_provider.vala
    src/ui/contact_details_dialog.vala
    src/ui/device_notification_populator.vala
    src/ui/own_notifications.vala
    src/ui/encryption_list_entry.vala
    src/ui/manage_key_dialog.vala
    src/ui/util.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/signal-protocol.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/libqrencode.vapi
PACKAGES
    ${OMEMO_PACKAGES}
GRESOURCES
    ${OMEMO_GRESOURCES_XML}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\"  -DG_LOG_DOMAIN="OMEMO")
add_library(omemo SHARED ${OMEMO_VALA_C} ${OMEMO_GRESOURCES_TARGET})
add_dependencies(omemo ${GETTEXT_PACKAGE}-translations)
target_link_libraries(omemo libdino signal-protocol-vala crypto-vala ${OMEMO_PACKAGES} libqrencode)
set_target_properties(omemo PROPERTIES PREFIX "")
set_target_properties(omemo PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS omemo ${PLUGIN_INSTALL})
