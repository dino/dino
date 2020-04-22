set(GETTEXT_PACKAGE "dino")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

find_packages(MAIN_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK3
    ICU
)

set(RESOURCE_LIST
    icons/dino-changes-allowed-symbolic.svg
    icons/dino-changes-prevent-symbolic.svg
    icons/dino-conversation-list-placeholder-arrow.svg
    icons/dino-double-tick-symbolic.svg
    icons/dino-emoticon-symbolic.svg
    icons/dino-qr-code-symbolic.svg
    icons/dino-security-high-symbolic.svg
    icons/dino-party-popper-symbolic.svg
    icons/dino-status-away.svg
    icons/dino-status-chat.svg
    icons/dino-status-dnd.svg
    icons/dino-status-online.svg
    icons/im.dino.Dino-symbolic.svg
    icons/dino-tick-symbolic.svg

    icons/dino-device-desktop-symbolic.svg
    icons/dino-device-phone-symbolic.svg

    icons/dino-file-document-symbolic.svg
    icons/dino-file-download-symbolic.svg
    icons/dino-file-image-symbolic.svg
    icons/dino-file-music-symbolic.svg
    icons/dino-file-symbolic.svg
    icons/dino-file-table-symbolic.svg
    icons/dino-file-video-symbolic.svg

    add_conversation/add_contact_dialog.ui
    add_conversation/add_groupchat_dialog.ui
    add_conversation/conference_details_fragment.ui
    add_conversation/list_row.ui
    add_conversation/select_jid_fragment.ui
    chat_input.ui
    contact_details_dialog.ui
    conversation_list_titlebar.ui
    conversation_list_titlebar_csd.ui
    conversation_row.ui
    conversation_view.ui
    file_default_widget.ui
    file_send_overlay.ui
    emojichooser.ui
    global_search.ui
    conversation_content_view/item_metadata_header.ui
    conversation_content_view/view.ui
    manage_accounts/account_row.ui
    manage_accounts/add_account_dialog.ui
    manage_accounts/dialog.ui
    menu_add.ui
    menu_app.ui
    menu_conversation.ui
    menu_encryption.ui
    message_item_widget_edit_mode.ui
    occupant_list.ui
    occupant_list_item.ui
    search_autocomplete.ui
    settings_dialog.ui
    shortcuts.ui
    unified_main_content.ui
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
set(MAIN_EXTRA_OPTIONS ${MAIN_EXTRA_OPTIONS} --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi)

vala_precompile(MAIN_VALA_C
SOURCES
    src/main.vala

    src/ui/application.vala
    src/ui/avatar_drawer.vala
    src/ui/avatar_image.vala
    src/ui/conversation_list_titlebar.vala
    src/ui/conversation_view.vala
    src/ui/conversation_view_controller.vala
    src/ui/file_send_overlay.vala
    src/ui/global_search.vala
    src/ui/notifications.vala
    src/ui/settings_dialog.vala
    src/ui/main_window.vala
    src/ui/main_window_controller.vala

    src/ui/add_conversation/add_conference_dialog.vala
    src/ui/add_conversation/add_contact_dialog.vala
    src/ui/add_conversation/add_groupchat_dialog.vala
    src/ui/add_conversation/conference_details_fragment.vala
    src/ui/add_conversation/conference_list.vala
    src/ui/add_conversation/list_row.vala
    src/ui/add_conversation/roster_list.vala
    src/ui/add_conversation/select_contact_dialog.vala
    src/ui/add_conversation/select_jid_fragment.vala

    src/ui/chat_input/chat_input_controller.vala
    src/ui/chat_input/chat_text_view.vala
    src/ui/chat_input/edit_history.vala
    src/ui/chat_input/encryption_button.vala
    src/ui/chat_input/occupants_tab_completer.vala
    src/ui/chat_input/smiley_converter.vala
    src/ui/chat_input/view.vala

    src/ui/contact_details/blocking_provider.vala
    src/ui/contact_details/settings_provider.vala
    src/ui/contact_details/permissions_provider.vala
    src/ui/contact_details/dialog.vala
    src/ui/contact_details/muc_config_form_provider.vala

    src/ui/conversation_selector/conversation_selector_row.vala
    src/ui/conversation_selector/conversation_selector.vala

    src/ui/conversation_content_view/chat_state_populator.vala
    src/ui/conversation_content_view/content_populator.vala
    src/ui/conversation_content_view/conversation_item_skeleton.vala
    src/ui/conversation_content_view/conversation_view.vala
    src/ui/conversation_content_view/date_separator_populator.vala
    src/ui/conversation_content_view/file_default_widget.vala
    src/ui/conversation_content_view/file_image_widget.vala
    src/ui/conversation_content_view/file_widget.vala
    src/ui/conversation_content_view/message_widget.vala
    src/ui/conversation_content_view/subscription_notification.vala

    src/ui/conversation_titlebar/menu_entry.vala
    src/ui/conversation_titlebar/occupants_entry.vala
    src/ui/conversation_titlebar/search_entry.vala
    src/ui/conversation_titlebar/conversation_titlebar.vala

    src/ui/manage_accounts/account_row.vala
    src/ui/manage_accounts/add_account_dialog.vala
    src/ui/manage_accounts/dialog.vala

    src/ui/occupant_menu/list.vala
    src/ui/occupant_menu/list_row.vala
    src/ui/occupant_menu/view.vala

    src/ui/util/accounts_combo_box.vala
    src/ui/util/config.vala
    src/ui/util/data_forms.vala
    src/ui/util/helper.vala
    src/ui/util/label_hybrid.vala
    src/ui/util/sizing_bin.vala
    src/ui/util/size_request_box.vala
    src/ui/util/scaling_image.vala
    src/ui/util/preview_file_chooser_native.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino_internal.vapi
    vapi/emojichooser.vapi
PACKAGES
    ${MAIN_PACKAGES}
    ${MAIN_EXTRA_PACKAGES}
GRESOURCES
    ${MAIN_GRESOURCES_XML}
OPTIONS
    ${MAIN_EXTRA_OPTIONS}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\" -DDINO_VERSION=\"${PROJECT_VERSION}\")
add_executable(dino ${MAIN_VALA_C} ${MAIN_GRESOURCES_TARGET} src/emojichooser.c)
add_dependencies(dino ${GETTEXT_PACKAGE}-translations)
target_include_directories(dino PRIVATE src)
target_link_libraries(dino libdino ${MAIN_PACKAGES})

if(WIN32)
    target_link_libraries(dino -mwindows)
endif(WIN32)

install(TARGETS dino ${TARGET_INSTALL})
install(FILES data/im.dino.Dino.appdata.xml DESTINATION ${APPDATA_FILE_INSTALL_DIR})
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
    data/icons/dino-qr-code-symbolic.svg
    data/icons/dino-tick-symbolic.svg
DESTINATION
    ${ICON_INSTALL_DIR}/hicolor/scalable/status
)
