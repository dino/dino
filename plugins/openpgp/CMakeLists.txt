find_package(GPGME REQUIRED)

set(GETTEXT_PACKAGE "dino-openpgp")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)


find_packages(OPENPGP_PACKAGES REQUIRED
    Adwaita
    Gee
    GLib
    GModule
    GObject
    GTK4
)

set(OPENPGP_DEFINITIONS)
if(Adwaita_VERSION VERSION_GREATER_EQUAL "1.4")
    set(OPENPGP_DEFINITIONS ${OPENPGP_DEFINITIONS} Adw_1_4)
endif()

vala_precompile(OPENPGP_VALA_C
SOURCES
    src/gpgme_helper.vala

    src/file_transfer/file_decryptor.vala
    src/file_transfer/file_encryptor.vala

    src/contact_details_provider.vala
    src/database.vala
    src/encryption_list_entry.vala
    src/encryption_preferences_entry.vala
    src/manager.vala
    src/plugin.vala
    src/register_plugin.vala
    src/stream_flag.vala
    src/stream_module.vala
    src/util.vala
CUSTOM_VAPIS
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpgme.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/gpg-error.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
PACKAGES
    ${OPENPGP_PACKAGES}
DEFINITIONS
    ${OPENPGP_DEFINITIONS}
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="OpenPGP" -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_library(openpgp SHARED ${OPENPGP_VALA_C} src/gpgme_fix.c)
add_dependencies(openpgp ${GETTEXT_PACKAGE}-translations)
target_include_directories(openpgp PRIVATE src)
target_link_libraries(openpgp libdino gpgme ${OPENPGP_PACKAGES})
set_target_properties(openpgp PROPERTIES PREFIX "")
set_target_properties(openpgp PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS openpgp ${PLUGIN_INSTALL})
