find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
include(${VALA_USE_FILE})
include(GlibCompileResourcesSupport)

set(LIBDINO_PACKAGES
    gee-0.8
    gio-2.0
    glib-2.0
    gtk+-3.0
    gmodule-2.0
    sqlite3
)

pkg_check_modules(LIBDINO REQUIRED ${LIBDINO_PACKAGES})

set(RESOURCE_LIST
    pgp_stack.ui
)

compile_gresources(
    LIBDINO_GRESOURCES_TARGET
    LIBDINO_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /org/dino-im
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(LIBDINO_VALA_C
SOURCES
    src/application.vala

    src/plugin/interfaces.vala
    src/plugin/loader.vala
    src/plugin/registry.vala

    src/dbus/login1.vala
    src/dbus/networkmanager.vala
    src/dbus/upower.vala

    src/entity/account.vala
    src/entity/conversation.vala
    src/entity/jid.vala
    src/entity/message.vala
    src/entity/encryption.vala

    src/service/avatar_manager.vala
    src/service/avatar_storage.vala
    src/service/chat_interaction.vala
    src/service/connection_manager.vala
    src/service/conversation_manager.vala
    src/service/counterpart_interaction_manager.vala
    src/service/database.vala
    src/service/entity_capabilities_storage.vala
    src/service/message_manager.vala
    src/service/module_manager.vala
    src/service/muc_manager.vala
    src/service/pgp_manager.vala
    src/service/presence_manager.vala
    src/service/roster_manager.vala
    src/service/stream_interactor.vala

    src/settings.vala
CUSTOM_VAPIS
    "${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi"
    "${CMAKE_BINARY_DIR}/exports/qlite.vapi"
    "${CMAKE_BINARY_DIR}/exports/gpgme.vapi"
PACKAGES
    ${LIBDINO_PACKAGES}
GENERATE_VAPI
    dino
GENERATE_HEADER
    dino
GRESOURCES
    ${LIBDINO_GRESOURCES_XML}
OPTIONS
    --target-glib=2.38
    ${GLOBAL_DEBUG_FLAGS}
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${LIBDINO_CFLAGS})
add_definitions(${CFLAGS})
add_library(libdino SHARED ${LIBDINO_VALA_C} ${LIBDINO_GRESOURCES_TARGET})
add_dependencies(libdino xmpp-vala-vapi qlite-vapi gpgme-vapi)
target_link_libraries(libdino xmpp-vala qlite gpgme-vala ${LIBDINO_LIBRARIES} -lm)
set_target_properties(libdino PROPERTIES PREFIX "")

add_custom_target(dino-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
)
