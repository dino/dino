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
    libnotify
    sqlite3
)

pkg_check_modules(LIBDINO REQUIRED ${LIBDINO_PACKAGES})

set(RESOURCE_LIST
    img/double_tick.svg
    img/status_away.svg
    img/status_chat.svg
    img/status_dnd.svg
    img/status_online.svg
    img/tick.svg

    add_conversation/add_contact_dialog.ui
    add_conversation/add_groupchat_dialog.ui
    add_conversation/conference_details_fragment.ui
    add_conversation/list_row.ui
    add_conversation/select_jid_fragment.ui
    chat_input.ui
    conversation_list_titlebar.ui
    conversation_selector/view.ui
    conversation_selector/chat_row_tooltip.ui
    conversation_selector/conversation_row.ui
    conversation_summary/message_item.ui
    conversation_summary/view.ui
    conversation_titlebar.ui
    manage_accounts/account_row.ui
    manage_accounts/add_account_dialog.ui
    manage_accounts/dialog.ui
    menu_add.ui
    menu_app.ui
    menu_conversation.ui
    menu_encryption.ui
    occupant_list.ui
    occupant_list_item.ui
    style.css
    settings_dialog.ui
    unified_window.ui
)

compile_gresources(
    LIBDINO_GRESOURCES_TARGET
    LIBDINO_GRESOURCES_XML
    TARGET ${CMAKE_BINARY_DIR}/resources/resources.c
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

    src/ui/add_conversation/chat/add_contact_dialog.vala
    src/ui/add_conversation/chat/roster_list.vala
    src/ui/add_conversation/chat/dialog.vala
    src/ui/add_conversation/conference/add_groupchat_dialog.vala
    src/ui/add_conversation/conference/conference_details_fragment.vala
    src/ui/add_conversation/conference/conference_list.vala
    src/ui/add_conversation/conference/dialog.vala
    src/ui/add_conversation/list_row.vala
    src/ui/add_conversation/select_jid_fragment.vala
    src/ui/avatar_generator.vala
    src/ui/chat_input.vala
    src/ui/conversation_list_titlebar.vala
    src/ui/conversation_selector/chat_row.vala
    src/ui/conversation_selector/conversation_row.vala
    src/ui/conversation_selector/groupchat_row.vala
    src/ui/conversation_selector/list.vala
    src/ui/conversation_selector/view.vala
    src/ui/conversation_summary/merged_message_item.vala
    src/ui/conversation_summary/merged_status_item.vala
    src/ui/conversation_summary/status_item.vala
    src/ui/conversation_summary/view.vala
    src/ui/conversation_titlebar.vala
    src/ui/manage_accounts/account_row.vala
    src/ui/manage_accounts/add_account_dialog.vala
    src/ui/manage_accounts/dialog.vala
    src/ui/notifications.vala
    src/ui/occupant_list.vala
    src/ui/occupant_list_row.vala
    src/ui/settings_dialog.vala
    src/ui/unified_window.vala
    src/ui/util.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/xmpp-vala/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/qlite/qlite.vapi
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
    -g
    --thread
)

set(CFLAGS ${VALA_CFLAGS} ${LIBDINO_CFLAGS} -I${CMAKE_BINARY_DIR}/xmpp-vala -I${CMAKE_BINARY_DIR}/qlite)
add_definitions(${CFLAGS})
add_library(libdino SHARED ${LIBDINO_VALA_C} ${LIBDINO_GRESOURCES_TARGET})
add_dependencies(libdino xmpp-vala-vapi qlite-vapi)
target_link_libraries(libdino xmpp-vala qlite ${LIBDINO_LIBRARIES} -lm)
set_target_properties(libdino PROPERTIES PREFIX "")

add_custom_target(dino-vapi
DEPENDS
    ${CMAKE_BINARY_DIR}/libdino/dino.vapi
)
