set(GETTEXT_PACKAGE "dino")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

find_packages(MAIN_PACKAGES REQUIRED
    Gee
    GLib>=2.38
    GModule
    GObject
    GTK3>=3.22
)

set(RESOURCE_LIST
    icons/dino-changes-prevent-symbolic.svg
    icons/dino-double-tick-symbolic.svg
    icons/dino-status-away.svg
    icons/dino-status-chat.svg
    icons/dino-status-dnd.svg
    icons/dino-status-online.svg
    icons/im.dino.Dino-symbolic.svg
    icons/dino-tick-symbolic.svg

    add_conversation/add_contact_dialog.ui
    add_conversation/add_groupchat_dialog.ui
    add_conversation/conference_details_fragment.ui
    add_conversation/list_row.ui
    add_conversation/select_jid_fragment.ui
    chat_input.ui
    contact_details_dialog.ui
    conversation_list_titlebar.ui
    conversation_selector/view.ui
    conversation_selector/chat_row_tooltip.ui
    conversation_selector/conversation_row.ui
    conversation_summary/image_toolbar.ui
    conversation_summary/view.ui
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

    theme.css
)

compile_gresources(
    MAIN_GRESOURCES_TARGET
    MAIN_GRESOURCES_XML
    TARGET ${CMAKE_CURRENT_BINARY_DIR}/resources/resources.c
    TYPE EMBED_C
    RESOURCES ${RESOURCE_LIST}
    PREFIX /im/dino/Dino
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/data
)

unset(MAIN_EXTRA_OPTIONS)
unset(MAIN_EXTRA_PACKAGES)
find_package(GDK3)
if(GDK3_WITH_X11)
    set(MAIN_EXTRA_OPTIONS ${MAIN_EXTRA_OPTIONS} -D GDK3_WITH_X11)
    set(MAIN_EXTRA_PACKAGES ${MAIN_EXTRA_PACKAGES} gdk-x11-3.0)
endif(GDK3_WITH_X11)

vala_precompile(MAIN_VALA_C
SOURCES
    src/main.vala

    src/ui/application.vala
    src/ui/add_conversation/add_conference_dialog.vala
    src/ui/add_conversation/add_contact_dialog.vala
    src/ui/add_conversation/add_groupchat_dialog.vala
    src/ui/add_conversation/conference_details_fragment.vala
    src/ui/add_conversation/conference_list.vala
    src/ui/add_conversation/list_row.vala
    src/ui/add_conversation/roster_list.vala
    src/ui/add_conversation/select_contact_dialog.vala
    src/ui/add_conversation/select_jid_fragment.vala
    src/ui/avatar_generator.vala
    src/ui/avatar_image.vala
    src/ui/chat_input/edit_history.vala
    src/ui/chat_input/encryption_button.vala
    src/ui/chat_input/occupants_tab_completer.vala
    src/ui/chat_input/smiley_converter.vala
    src/ui/chat_input/view.vala
    src/ui/contact_details/blocking_provider.vala
    src/ui/contact_details/settings_provider.vala
    src/ui/contact_details/dialog.vala
    src/ui/contact_details/muc_config_form_provider.vala
    src/ui/conversation_list_titlebar.vala
    src/ui/conversation_selector/chat_row.vala
    src/ui/conversation_selector/conversation_row.vala
    src/ui/conversation_selector/groupchat_pm_row.vala
    src/ui/conversation_selector/groupchat_row.vala
    src/ui/conversation_selector/list.vala
    src/ui/conversation_selector/view.vala
    src/ui/conversation_summary/chat_state_populator.vala
    src/ui/conversation_summary/conversation_item_skeleton.vala
    src/ui/conversation_summary/conversation_view.vala
    src/ui/conversation_summary/date_separator_populator.vala
    src/ui/conversation_summary/default_file_display.vala
    src/ui/conversation_summary/default_message_display.vala
    src/ui/conversation_summary/file_populator.vala
    src/ui/conversation_summary/image_display.vala
    src/ui/conversation_summary/message_populator.vala
    src/ui/conversation_summary/message_textview.vala
    src/ui/conversation_summary/slashme_message_display.vala
    src/ui/conversation_summary/subscription_notification.vala
    src/ui/conversation_titlebar/file_entry.vala
    src/ui/conversation_titlebar/menu_entry.vala
    src/ui/conversation_titlebar/occupants_entry.vala
    src/ui/conversation_titlebar/view.vala
    src/ui/manage_accounts/account_row.vala
    src/ui/manage_accounts/add_account_dialog.vala
    src/ui/manage_accounts/dialog.vala
    src/ui/notifications.vala
    src/ui/occupant_menu/list.vala
    src/ui/occupant_menu/list_row.vala
    src/ui/occupant_menu/view.vala
    src/ui/settings_dialog.vala
    src/ui/unified_window.vala
    src/ui/util/accounts_combo_box.vala
    src/ui/util/helper.vala
    src/ui/util/label_hybrid.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino_internal.vapi
PACKAGES
    ${MAIN_PACKAGES}
    ${MAIN_EXTRA_PACKAGES}
GRESOURCES
    ${MAIN_GRESOURCES_XML}
OPTIONS
    ${MAIN_EXTRA_OPTIONS}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\")
add_executable(dino ${MAIN_VALA_C} ${MAIN_GRESOURCES_TARGET})
add_dependencies(dino ${GETTEXT_PACKAGE}-translations)
target_link_libraries(dino libdino ${MAIN_PACKAGES})

if(WIN32)
    target_link_libraries(dino -mwindows)
endif(WIN32)

install(TARGETS dino ${TARGET_INSTALL})
install(FILES data/im.dino.Dino.desktop DESTINATION ${DESKTOP_FILE_INSTALL_DIR})
install(FILES data/im.dino.Dino.service DESTINATION ${SERVICE_FILE_INSTALL_DIR})
install(FILES data/icons/im.dino.Dino.svg DESTINATION ${ICON_INSTALL_DIR}/hicolor/scalable/apps)
install(FILES data/icons/im.dino.Dino-symbolic.svg DESTINATION ${ICON_INSTALL_DIR}/hicolor/symbolic/apps)
install(FILES
    data/icons/dino-status-away.svg
    data/icons/dino-status-chat.svg
    data/icons/dino-status-dnd.svg
    data/icons/dino-status-online.svg

    data/icons/dino-changes-prevent-symbolic.svg
    data/icons/dino-double-tick-symbolic.svg
    data/icons/dino-tick-symbolic.svg
DESTINATION
    ${ICON_INSTALL_DIR}/hicolor/scalable/status
)
