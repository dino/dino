find_packages(MAIN_PACKAGES REQUIRED
    Gee
    GLib>=2.38
    GModule
    GObject
    GTK3>=3.22
    Libnotify
)

set(RESOURCE_LIST
    icons/dino-double-tick-symbolic.svg
    icons/dino-status-away.svg
    icons/dino-status-chat.svg
    icons/dino-status-dnd.svg
    icons/dino-status-online.svg
    icons/dino-symbolic.svg
    icons/dino-tick-symbolic.svg

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
    settings_dialog.ui
    unified_window_placeholder.ui
)

compile_gresources(
    MAIN_GRESOURCES_TARGET
    MAIN_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /org/dino-im
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

vala_precompile(MAIN_VALA_C
SOURCES
    src/main.vala

    src/ui/application.vala
    src/ui/add_conversation/chat/add_contact_dialog.vala
    src/ui/add_conversation/chat/roster_list.vala
    src/ui/add_conversation/chat/dialog.vala
    src/ui/add_conversation/conference/add_groupchat_dialog.vala
    src/ui/add_conversation/conference/conference_details_fragment.vala
    src/ui/add_conversation/conference/conference_list.vala
    src/ui/add_conversation/conference/dialog.vala
    src/ui/add_conversation/accounts_combo_box.vala
    src/ui/add_conversation/list_row.vala
    src/ui/add_conversation/select_jid_fragment.vala
    src/ui/avatar_generator.vala
    src/ui/chat_input/occupants_tab_completer.vala
    src/ui/chat_input/smiley_converter.vala
    src/ui/chat_input/view.vala
    src/ui/conversation_list_titlebar.vala
    src/ui/conversation_selector/chat_row.vala
    src/ui/conversation_selector/conversation_row.vala
    src/ui/conversation_selector/groupchat_row.vala
    src/ui/conversation_selector/list.vala
    src/ui/conversation_selector/view.vala
    src/ui/conversation_summary/conversation_item.vala
    src/ui/conversation_summary/merged_message_item.vala
    src/ui/conversation_summary/message_item.vala
    src/ui/conversation_summary/message_textview.vala
    src/ui/conversation_summary/slashme_item.vala
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
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino_internal.vapi
PACKAGES
    ${MAIN_PACKAGES}
GRESOURCES
    ${MAIN_GRESOURCES_XML}
)

add_definitions(${VALA_CFLAGS})
add_executable(dino ${MAIN_VALA_C} ${MAIN_GRESOURCES_TARGET})
add_dependencies(dino dino-vapi dino-gsettings-schema-compiled)
target_link_libraries(dino libdino ${MAIN_PACKAGES})

if(WIN32)
    target_link_libraries(dino -mwindows)
endif(WIN32)

install(TARGETS dino ${TARGET_INSTALL})
install(FILES data/dino.desktop DESTINATION ${APPLICATION_INSTALL_DIR})
install(FILES data/icons/dino.svg DESTINATION ${ICON_INSTALL_DIR}/hicolor/scalable/apps)
install(FILES data/icons/dino-symbolic.svg DESTINATION ${ICON_INSTALL_DIR}/hicolor/symbolic/apps)
install(FILES
    data/icons/dino-status-away.svg
    data/icons/dino-status-chat.svg
    data/icons/dino-status-dnd.svg
    data/icons/dino-status-online.svg

    data/icons/dino-double-tick-symbolic.svg
    data/icons/dino-tick-symbolic.svg
DESTINATION
    ${ICON_INSTALL_DIR}/hicolor/scalable/status
)
