find_packages(LIBDINO_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
)

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
CUSTOM_DEPS
    xmpp-vala
    qlite
PACKAGES
    ${LIBDINO_PACKAGES}
GENERATE_VAPI
    dino
GENERATE_HEADER
    dino
)

add_definitions(${VALA_CFLAGS} -DDINO_PLUGINS_SYSTEM_PLUGIN_DIR="${PLUGIN_INSTALL_DIR}" -DDINO_PLUGINS_SYSTEM_LIBDIR_NAME="${LIBDIR_NAME}")
add_library(libdino SHARED ${LIBDINO_VALA_C})
add_dependencies(libdino xmpp-vala-vapi qlite-vapi)
target_link_libraries(libdino xmpp-vala qlite ${LIBDINO_PACKAGES} m)
set_target_properties(libdino PROPERTIES PREFIX "" VERSION 0.0 SOVERSION 0)

add_custom_target(dino-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.deps
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

install(TARGETS libdino ${TARGET_INSTALL})
install(FILES ${CMAKE_BINARY_DIR}/exports/dino.vapi ${CMAKE_BINARY_DIR}/exports/dino.deps DESTINATION ${VAPI_INSTALL_DIR})
install(FILES ${CMAKE_BINARY_DIR}/exports/dino.h DESTINATION ${INCLUDE_INSTALL_DIR})
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/dino.gschema.xml DESTINATION ${SHARE_INSTALL_PREFIX}/glib-2.0/schemas/)