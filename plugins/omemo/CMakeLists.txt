set(GETTEXT_PACKAGE "dino-omemo")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

find_package(Adwaita REQUIRED)
find_package(Qrencode REQUIRED)
find_packages(OMEMO_PACKAGES REQUIRED
    Adwaita
    Gee
    GLib
    GModule
    GObject
    GTK4
)

# libsignal-protocol-c has a history of breaking compatibility on the patch level
# we'll have to check compatibility for every new release
# distro maintainers may update this dependency after compatibility tests
find_package(SignalProtocol 2.3.2 REQUIRED)

set(RESOURCE_LIST
    contact_details_dialog.ui
    encryption_preferences_entry.ui
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
set(OMEMO_DEFINITIONS)
if(Adwaita_VERSION VERSION_GREATER_EQUAL "1.2")
    set(OMEMO_DEFINITIONS ${OMEMO_DEFINITIONS} Adw_1_2)
endif()

message(STATUS ${Adwaita_VERSION})
message(STATUS ${Adw_1_2})

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

    src/signal/context.vala
    src/signal/simple_iks.vala
    src/signal/simple_ss.vala
    src/signal/simple_pks.vala
    src/signal/simple_spks.vala
    src/signal/store.vala
    src/signal/util.vala

    src/ui/bad_messages_populator.vala
    src/ui/call_encryption_entry.vala
    src/ui/contact_details_provider.vala
    src/ui/contact_details_dialog.vala
    src/ui/device_notification_populator.vala
    src/ui/own_notifications.vala
    src/ui/encryption_list_entry.vala
    src/ui/encryption_preferences_entry.vala
    src/ui/manage_key_dialog.vala
    src/ui/util.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/libqrencode.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/libsignal-protocol-c.vapi
PACKAGES
    ${OMEMO_PACKAGES}
GRESOURCES
    ${OMEMO_GRESOURCES_XML}
DEFINITIONS
    ${OMEMO_DEFINITIONS}
GENERATE_VAPI
    omemo
GENERATE_HEADER
    omemo
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\" -DG_LOG_DOMAIN="OMEMO")
add_library(omemo SHARED ${OMEMO_VALA_C} ${OMEMO_GRESOURCES_TARGET} ${CMAKE_CURRENT_SOURCE_DIR}/src/signal/signal_helper.c)
add_dependencies(omemo ${GETTEXT_PACKAGE}-translations)
target_include_directories(omemo PUBLIC src)
target_link_libraries(omemo libdino crypto-vala gcrypt ${OMEMO_PACKAGES} libqrencode signal-protocol-c)
set_target_properties(omemo PROPERTIES PREFIX "")
set_target_properties(omemo PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS omemo ${PLUGIN_INSTALL})

if(BUILD_TESTS)
    vala_precompile(OMEMO_TEST_VALA_C
    SOURCES
        "tests/signal/common.vala"
        "tests/signal/testcase.vala"

        "tests/signal/curve25519.vala"
        "tests/signal/hkdf.vala"
        "tests/signal/session_builder.vala"
    CUSTOM_VAPIS
        ${CMAKE_BINARY_DIR}/exports/omemo_internal.vapi
        ${CMAKE_BINARY_DIR}/exports/qlite.vapi
        ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
        ${CMAKE_BINARY_DIR}/exports/dino.vapi
        ${CMAKE_CURRENT_SOURCE_DIR}/vapi/libsignal-protocol-c.vapi
    PACKAGES
        ${OMEMO_PACKAGES}
    )

    set(CFLAGS ${VALA_CFLAGS})
    add_executable(omemo-test ${OMEMO_TEST_VALA_C})
    add_dependencies(omemo-test omemo)
    target_link_libraries(omemo-test omemo ${OMEMO_PACKAGES})
endif(BUILD_TESTS)
