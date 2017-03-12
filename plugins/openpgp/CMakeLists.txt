find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
include(${VALA_USE_FILE})
include(GlibCompileResourcesSupport)

set(OPENPGP_PACKAGES
    gee-0.8
    glib-2.0
    gtk+-3.0
    gmodule-2.0
    sqlite3
)

pkg_check_modules(OPENPGP REQUIRED ${OPENPGP_PACKAGES})

set(RESOURCE_LIST
    account_settings_item.ui
)

compile_gresources(
    OPENPGP_GRESOURCES_TARGET
    OPENPGP_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /org/dino-im
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(OPENPGP_VALA_C
SOURCES
    src/account_settings_entry.vala
    src/account_settings_widget.vala
    src/encryption_list_entry.vala
    src/manager.vala
    src/plugin.vala
    src/register_plugin.vala
    src/xmpp_flag.vala
    src/xmpp_module.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/gpgme.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
PACKAGES
    ${OPENPGP_PACKAGES}
GRESOURCES
    ${OPENPGP_GRESOURCES_XML}
OPTIONS
    --target-glib=2.38
    ${GLOBAL_DEBUG_FLAGS}
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${OPENPGP_CFLAGS})
add_definitions(${CFLAGS})
add_library(openpgp SHARED ${OPENPGP_VALA_C} ${OPENPGP_GRESOURCES_TARGET})
add_dependencies(openpgp dino-vapi gpgme-vapi)
target_link_libraries(openpgp libdino gpgme-vala)
set_target_properties(openpgp PROPERTIES PREFIX "")
set_target_properties(openpgp PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)
