find_package(Vala REQUIRED)
find_package(PkgConfig REQUIRED)
include(${VALA_USE_FILE})

set(LIBDINO_PACKAGES
    gee-0.8
    glib-2.0
    gtk+-3.0
    gmodule-2.0
    sqlite3
)

pkg_check_modules(LIBDINO REQUIRED ${LIBDINO_PACKAGES})

vala_precompile(LIBDINO_VALA_C
SOURCES
    src/application.vala

    src/dbus/login1.vala
    src/dbus/networkmanager.vala
    src/dbus/upower.vala

    src/entity/account.vala
    src/entity/conversation.vala
    src/entity/jid.vala
    src/entity/message.vala
    src/entity/encryption.vala

    src/plugin/interfaces.vala
    src/plugin/loader.vala
    src/plugin/registry.vala

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
    src/service/presence_manager.vala
    src/service/roster_manager.vala
    src/service/stream_interactor.vala

    src/settings.vala
CUSTOM_VAPIS
    "${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi"
    "${CMAKE_BINARY_DIR}/exports/qlite.vapi"
PACKAGES
    ${LIBDINO_PACKAGES}
GENERATE_VAPI
    dino
GENERATE_HEADER
    dino
OPTIONS
    --target-glib=2.38
    ${GLOBAL_DEBUG_FLAGS}
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${LIBDINO_CFLAGS})
add_definitions(${CFLAGS})
add_library(libdino SHARED ${LIBDINO_VALA_C})
add_dependencies(libdino xmpp-vala-vapi qlite-vapi)
target_link_libraries(libdino xmpp-vala qlite ${LIBDINO_LIBRARIES} -lm)
set_target_properties(libdino PROPERTIES PREFIX "")

add_custom_target(dino-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
)

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/gschemas.compiled
COMMAND
    glib-compile-schemas --targetdir=${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/data
DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/data/dino.gschema.xml
)

add_custom_target(dino-gsettings-schema-compiled
DEPENDS
    ${CMAKE_BINARY_DIR}/gschemas.compiled
)