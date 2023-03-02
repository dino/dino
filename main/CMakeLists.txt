set(GETTEXT_PACKAGE "dino")
find_package(Gettext)
include(${GETTEXT_USE_FILE})
gettext_compile(${GETTEXT_PACKAGE} SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/po TARGET_NAME ${GETTEXT_PACKAGE}-translations)

find_package(GTK4 REQUIRED)
find_packages(MAIN_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK4
    ICU
    Adwaita
)

set(RESOURCE_LIST
    dino-conversation-list-placeholder-arrow.svg

    icons/scalable/actions/dino-account-plus-symbolic.svg
    icons/scalable/actions/dino-emoticon-add-symbolic.svg
    icons/scalable/actions/dino-emoticon-symbolic.svg
    icons/scalable/actions/dino-qr-code-symbolic.svg

    icons/scalable/apps/im.dino.Dino.svg
    icons/scalable/apps/im.dino.Dino-symbolic.svg

    icons/scalable/devices/dino-device-desktop-symbolic.svg
    icons/scalable/devices/dino-device-phone-symbolic.svg
    icons/scalable/devices/dino-phone-hangup-symbolic.svg
    icons/scalable/devices/dino-phone-in-talk-symbolic.svg
    icons/scalable/devices/dino-phone-missed-symbolic.svg
    icons/scalable/devices/dino-phone-ring-symbolic.svg
    icons/scalable/devices/dino-phone-symbolic.svg

    icons/scalable/mimetypes/dino-file-document-symbolic.svg
    icons/scalable/mimetypes/dino-file-download-symbolic.svg
    icons/scalable/mimetypes/dino-file-image-symbolic.svg
    icons/scalable/mimetypes/dino-file-music-symbolic.svg
    icons/scalable/mimetypes/dino-file-symbolic.svg
    icons/scalable/mimetypes/dino-file-table-symbolic.svg
    icons/scalable/mimetypes/dino-file-video-symbolic.svg

    icons/scalable/status/dino-double-tick-symbolic.svg
    icons/scalable/status/dino-microphone-off-symbolic.svg
    icons/scalable/status/dino-microphone-symbolic.svg
    icons/scalable/status/dino-party-popper-symbolic.svg
    icons/scalable/status/dino-security-high-symbolic.svg
    icons/scalable/status/dino-status-away.svg
    icons/scalable/status/dino-status-chat.svg
    icons/scalable/status/dino-status-dnd.svg
    icons/scalable/status/dino-status-online.svg
    icons/scalable/status/dino-tick-symbolic.svg
    icons/scalable/status/dino-video-off-symbolic.svg
    icons/scalable/status/dino-video-symbolic.svg

    add_conversation/add_contact_dialog.ui
    add_conversation/add_groupchat_dialog.ui
    add_conversation/conference_details_fragment.ui
    add_conversation/list_row.ui
    add_conversation/select_jid_fragment.ui

    call_widget.ui
    chat_input.ui
    contact_details_dialog.ui
    conversation_item_widget.ui
    conversation_list_titlebar.ui
    conversation_list_titlebar_csd.ui
    conversation_row.ui
    conversation_view.ui
    file_default_widget.ui
    file_send_overlay.ui
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
    quote.ui
    search_autocomplete.ui
    settings_dialog.ui
    shortcuts.ui
    unified_main_content.ui
    unified_window_placeholder.ui

    style.css
    style-dark.css
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
set(MAIN_EXTRA_OPTIONS ${MAIN_EXTRA_OPTIONS} --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi)

set(MAIN_DEFINITIONS)
if(GTK4_VERSION VERSION_GREATER_EQUAL "4.6")
    set(MAIN_DEFINITIONS ${MAIN_DEFINITIONS} GTK_4_6)
endif()
if(GTK4_VERSION VERSION_GREATER_EQUAL "4.8")
    set(MAIN_DEFINITIONS ${MAIN_DEFINITIONS} GTK_4_8)
endif()
if(Adwaita_VERSION VERSION_GREATER_EQUAL "1.2")
    set(MAIN_DEFINITIONS ${MAIN_DEFINITIONS} Adw_1_2)
endif()

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
    src/ui/notifier_freedesktop.vala
    src/ui/notifier_gnotifications.vala
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

    src/ui/call_window/audio_settings_popover.vala
    src/ui/call_window/call_bottom_bar.vala
    src/ui/call_window/call_connection_details_window.vala
    src/ui/call_window/call_encryption_button.vala
    src/ui/call_window/call_window.vala
    src/ui/call_window/call_window_controller.vala
    src/ui/call_window/participant_widget.vala
    src/ui/call_window/video_settings_popover.vala

    src/ui/conversation_content_view/call_widget.vala
    src/ui/conversation_content_view/chat_state_populator.vala
    src/ui/conversation_content_view/content_populator.vala
    src/ui/conversation_content_view/conversation_item_skeleton.vala
    src/ui/conversation_content_view/conversation_view.vala
    src/ui/conversation_content_view/date_separator_populator.vala
    src/ui/conversation_content_view/file_default_widget.vala
    src/ui/conversation_content_view/file_image_widget.vala
    src/ui/conversation_content_view/file_widget.vala
    src/ui/conversation_content_view/item_actions.vala
    src/ui/conversation_content_view/message_widget.vala
    src/ui/conversation_content_view/quote_widget.vala
    src/ui/conversation_content_view/reactions_widget.vala
    src/ui/conversation_content_view/subscription_notification.vala

    src/ui/chat_input/chat_input_controller.vala
    src/ui/chat_input/chat_text_view.vala
    src/ui/chat_input/encryption_button.vala
    src/ui/chat_input/occupants_tab_completer.vala
    src/ui/chat_input/smiley_converter.vala
    src/ui/chat_input/view.vala

    src/ui/contact_details/blocking_provider.vala
    src/ui/contact_details/settings_provider.vala
    src/ui/contact_details/permissions_provider.vala
    src/ui/contact_details/dialog.vala
    src/ui/contact_details/muc_config_form_provider.vala

    src/ui/conversation_selector/conversation_selector.vala
    src/ui/conversation_selector/conversation_selector_row.vala

    src/ui/conversation_titlebar/call_entry.vala
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

    src/ui/widgets/date_separator.vala
    src/ui/widgets/fixed_ratio_picture.vala
    src/ui/widgets/natural_size_increase.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
    ${CMAKE_BINARY_DIR}/exports/dino_internal.vapi
PACKAGES
    ${MAIN_PACKAGES}
    ${MAIN_EXTRA_PACKAGES}
GRESOURCES
    ${MAIN_GRESOURCES_XML}
DEFINITIONS
    ${MAIN_DEFINITIONS}
OPTIONS
    ${MAIN_EXTRA_OPTIONS}
)

add_definitions(${VALA_CFLAGS} -DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\" -DLOCALE_INSTALL_DIR=\"${LOCALE_INSTALL_DIR}\" -DG_LOG_DOMAIN="dino")
add_executable(dino ${MAIN_VALA_C} ${MAIN_GRESOURCES_TARGET})
add_dependencies(dino ${GETTEXT_PACKAGE}-translations)
target_include_directories(dino PRIVATE src)
target_link_libraries(dino libdino ${MAIN_PACKAGES})
set_target_properties(dino PROPERTIES ENABLE_EXPORTS TRUE)

if(WIN32)
    target_link_libraries(dino -mwindows)
endif(WIN32)

install(TARGETS dino ${TARGET_INSTALL})
install(FILES data/im.dino.Dino.appdata.xml DESTINATION ${APPDATA_FILE_INSTALL_DIR})
install(FILES data/im.dino.Dino.desktop DESTINATION ${DESKTOP_FILE_INSTALL_DIR})
install(FILES data/im.dino.Dino.service DESTINATION ${SERVICE_FILE_INSTALL_DIR})
install(FILES data/icons/scalable/apps/im.dino.Dino.svg DESTINATION ${ICON_INSTALL_DIR}/hicolor/scalable/apps)
install(FILES data/icons/scalable/apps/im.dino.Dino-symbolic.svg DESTINATION ${ICON_INSTALL_DIR}/hicolor/symbolic/apps)
