set(GETTEXT_PACKAGE "dino-openpgp")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)


find_packages(OPENPGP_PACKAGES REQUIRED
    Gee
    GLib>=2.38
    GModule
    GObject
    GTK3
)

set(RESOURCE_LIST
    account_settings_item.ui
)

compile_gresources(
    OPENPGP_GRESOURCES_TARGET
    OPENPGP_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /im/dino/Dino/openpgp
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(OPENPGP_VALA_C
SOURCES
    src/file_transfer/file_decryptor.vala
    src/file_transfer/file_encryptor.vala

    src/account_settings_entry.vala
    src/account_settings_widget.vala
    src/contact_details_provider.vala
    src/database.vala
    src/encryption_list_entry.vala
    src/manager.vala
    src/plugin.vala
    src/register_plugin.vala
    src/stream_flag.vala
    src/stream_module.vala
    src/util.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/gpgme.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
PACKAGES
    ${OPENPGP_PACKAGES}
GRESOURCES
    ${OPENPGP_GRESOURCES_XML}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_library(openpgp SHARED ${OPENPGP_VALA_C} ${OPENPGP_GRESOURCES_TARGET})
add_dependencies(openpgp ${GETTEXT_PACKAGE}-translations)
target_link_libraries(openpgp libdino gpgme-vala ${OPENPGP_PACKAGES})
set_target_properties(openpgp PROPERTIES PREFIX "")
set_target_properties(openpgp PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS openpgp ${PLUGIN_INSTALL})
