find_packages(LIBDINO_PACKAGES REQUIRED
    GDKPixbuf2
    Gee
    GLib
    GModule
    GObject
)

vala_precompile(LIBDINO_VALA_C
SOURCES
    src/application.vala

    src/dbus/login1.vala
    src/dbus/upower.vala

    src/entity/account.vala
    src/entity/conversation.vala
    src/entity/encryption.vala
    src/entity/file_transfer.vala
    src/entity/message.vala
    src/entity/settings.vala

    src/plugin/interfaces.vala
    src/plugin/loader.vala
    src/plugin/registry.vala

    src/service/avatar_manager.vala
    src/service/blocking_manager.vala
    src/service/chat_interaction.vala
    src/service/connection_manager.vala
    src/service/content_item_store.vala
    src/service/conversation_manager.vala
    src/service/counterpart_interaction_manager.vala
    src/service/database.vala
    src/service/entity_capabilities_storage.vala
    src/service/entity_info.vala
    src/service/file_manager.vala
    src/service/jingle_file_transfers.vala
    src/service/message_correction.vala
    src/service/message_processor.vala
    src/service/message_storage.vala
    src/service/module_manager.vala
    src/service/muc_manager.vala
    src/service/notification_events.vala
    src/service/presence_manager.vala
    src/service/registration.vala
    src/service/roster_manager.vala
    src/service/search_processor.vala
    src/service/stream_interactor.vala
    src/service/util.vala

    src/util.vala
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

add_custom_command(OUTPUT "${CMAKE_BINARY_DIR}/exports/dino_i18n.h"
COMMAND
    cp "${CMAKE_CURRENT_SOURCE_DIR}/src/dino_i18n.h" "${CMAKE_BINARY_DIR}/exports/dino_i18n.h"
DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/dino_i18n.h"
COMMENT
    Copy header file dino_i18n.h
)

add_custom_target(dino-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.deps
    ${CMAKE_BINARY_DIR}/exports/dino_i18n.h
)

add_definitions(${VALA_CFLAGS} -DDINO_SYSTEM_PLUGIN_DIR="${PLUGIN_INSTALL_DIR}" -DDINO_SYSTEM_LIBDIR_NAME="${LIBDIR_NAME}" -DG_LOG_DOMAIN="libdino")
add_library(libdino SHARED ${LIBDINO_VALA_C} ${CMAKE_BINARY_DIR}/exports/dino_i18n.h)
add_dependencies(libdino dino-vapi)
target_link_libraries(libdino xmpp-vala qlite ${LIBDINO_PACKAGES} m)
set_target_properties(libdino PROPERTIES PREFIX "" VERSION 0.0 SOVERSION 0)

install(TARGETS libdino ${TARGET_INSTALL})
install(FILES ${CMAKE_BINARY_DIR}/exports/dino.vapi ${CMAKE_BINARY_DIR}/exports/dino.deps DESTINATION ${VAPI_INSTALL_DIR})
install(FILES ${CMAKE_BINARY_DIR}/exports/dino.h ${CMAKE_BINARY_DIR}/exports/dino_i18n.h DESTINATION ${INCLUDE_INSTALL_DIR})
