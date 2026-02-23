subdir('po')
dependencies = [
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gtk4,
    dep_icu_uc,
    dep_libadwaita,
    dep_m,
    dep_qlite,
    dep_xmpp_vala,
    meson.get_compiler('vala').find_library('posix'),
]
sources = files(
    'src/main.vala',
    'src/ui/add_conversation/add_conference_dialog.vala',
    'src/ui/add_conversation/add_contact_dialog.vala',
    'src/ui/add_conversation/add_groupchat_dialog.vala',
    'src/ui/add_conversation/conference_details_fragment.vala',
    'src/ui/add_conversation/conference_list.vala',
    'src/ui/add_conversation/list_row.vala',
    'src/ui/add_conversation/roster_list.vala',
    'src/ui/add_conversation/select_contact_dialog.vala',
    'src/ui/add_conversation/select_jid_fragment.vala',
    'src/ui/application.vala',
    'src/ui/call_window/audio_settings_popover.vala',
    'src/ui/call_window/call_bottom_bar.vala',
    'src/ui/call_window/call_connection_details_window.vala',
    'src/ui/call_window/call_encryption_button.vala',
    'src/ui/call_window/call_window.vala',
    'src/ui/call_window/call_window_controller.vala',
    'src/ui/call_window/participant_widget.vala',
    'src/ui/call_window/video_settings_popover.vala',
    'src/ui/chat_input/chat_input_controller.vala',
    'src/ui/chat_input/chat_text_view.vala',
    'src/ui/chat_input/encryption_button.vala',
    'src/ui/chat_input/occupants_tab_completer.vala',
    'src/ui/chat_input/smiley_converter.vala',
    'src/ui/chat_input/view.vala',
    'src/ui/contact_details/permissions_provider.vala',
    'src/ui/contact_details/settings_provider.vala',
    'src/ui/conversation_content_view/call_widget.vala',
    'src/ui/conversation_content_view/chat_state_populator.vala',
    'src/ui/conversation_content_view/content_populator.vala',
    'src/ui/conversation_content_view/conversation_item_skeleton.vala',
    'src/ui/conversation_content_view/conversation_view.vala',
    'src/ui/conversation_content_view/date_separator_populator.vala',
    'src/ui/conversation_content_view/file_default_widget.vala',
    'src/ui/conversation_content_view/file_image_widget.vala',
    'src/ui/conversation_content_view/file_transmission_progress.vala',
    'src/ui/conversation_content_view/file_widget.vala',
    'src/ui/conversation_content_view/item_actions.vala',
    'src/ui/conversation_content_view/message_widget.vala',
    'src/ui/conversation_content_view/quote_widget.vala',
    'src/ui/conversation_content_view/reactions_widget.vala',
    'src/ui/conversation_content_view/subscription_notification.vala',
    'src/ui/conversation_content_view/unread_indicator_populator.vala',
    'src/ui/conversation_details.vala',
    'src/ui/conversation_selector/conversation_selector.vala',
    'src/ui/conversation_selector/conversation_selector_row.vala',
    'src/ui/conversation_titlebar/call_entry.vala',
    'src/ui/conversation_titlebar/menu_entry.vala',
    'src/ui/conversation_titlebar/occupants_entry.vala',
    'src/ui/conversation_titlebar/search_entry.vala',
    'src/ui/conversation_view.vala',
    'src/ui/conversation_view_controller.vala',
    'src/ui/file_send_overlay.vala',
    'src/ui/global_search.vala',
    'src/ui/main_window.vala',
    'src/ui/main_window_controller.vala',
    'src/ui/notifier_freedesktop.vala',
    'src/ui/notifier_gnotifications.vala',
    'src/ui/occupant_menu/list.vala',
    'src/ui/occupant_menu/list_row.vala',
    'src/ui/occupant_menu/view.vala',
    'src/ui/util/accounts_combo_box.vala',
    'src/ui/util/config.vala',
    'src/ui/util/data_forms.vala',
    'src/ui/util/file_metadata_providers.vala',
    'src/ui/util/helper.vala',
    'src/ui/util/preference_group.vala',
    'src/ui/util/size_request_box.vala',
    'src/ui/util/sizing_bin.vala',
    'src/ui/widgets/avatar_picture.vala',
    'src/ui/widgets/date_separator.vala',
    'src/ui/widgets/fixed_ratio_picture.vala',
    'src/ui/widgets/natural_size_increase.vala',
    'src/view_model/account_details.vala',
    'src/view_model/conversation_details.vala',
    'src/view_model/preferences_dialog.vala',
    'src/view_model/preferences_row.vala',
    'src/windows/preferences_window/account_preferences_subpage.vala',
    'src/windows/preferences_window/accounts_preferences_page.vala',
    'src/windows/preferences_window/add_account_dialog.vala',
    'src/windows/preferences_window/change_password_dialog.vala',
    'src/windows/preferences_window/encryption_preferences_page.vala',
    'src/windows/preferences_window/general_preferences_page.vala',
    'src/windows/preferences_window/preferences_dialog.vala',
    'src/windows/conversation_details.vala',
)
sources += gnome.compile_resources(
    'resources',
    'data/gresource.xml',
    source_dir: 'data',
)

c_args = [
    '-DG_LOG_DOMAIN="dino"',
    '-DGETTEXT_PACKAGE="dino"',
    '-DLOCALE_INSTALL_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.6')
    vala_args += ['-D', 'GTK_4_6']
endif
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.8')
    vala_args += ['-D', 'GTK_4_8']
endif
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.12')
    vala_args += ['-D', 'GTK_4_12']
endif
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.14')
    vala_args += ['-D', 'GTK_4_14']
    sources += files('src/ui/conversation_content_view/file_transmission_progress.c')
endif
if dep_libadwaita.version() == 'unknown' or dep_libadwaita.version().version_compare('>=1.4')
    vala_args += ['-D', 'Adw_1_4']
endif
if meson.get_compiler('vala').version().version_compare('>=0.56.5') and meson.get_compiler('vala').version().version_compare('<0.58')
    vala_args += ['-D', 'VALA_0_56_GREATER_5']
endif
if meson.get_compiler('vala').version().version_compare('>=0.56.11') and meson.get_compiler('vala').version().version_compare('<0.58')
    vala_args += ['-D', 'VALA_0_56_GREATER_11']
endif
if meson.get_compiler('vala').version().version_compare('=0.56.11')
    vala_args += ['-D', 'VALA_0_56_11']
endif
if meson.get_compiler('vala').version().version_compare('=0.56.12')
    vala_args += ['-D', 'VALA_0_56_12']
endif
exe_dino = executable('dino', sources, c_args: c_args, vala_args: vala_args, dependencies: dependencies, install: true, install_rpath: default_install_rpath)

install_data('data/icons/scalable/apps/im.dino.Dino.svg', install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps')
install_data('data/icons/scalable/apps/im.dino.Dino-symbolic.svg', install_dir: get_option('datadir') / 'icons/hicolor/symbolic/apps')
# these icons are actuallty 128, but there's no apps/128 folder in KDE's themes; apps/48 is the closest.
install_data('data/icons/scalable/apps/im.dino.Dino-symbolic-light.svg', install_dir: get_option('datadir') / 'icons/breeze/apps/48', rename: 'im.dino.Dino-symbolic.svg')
install_data('data/icons/scalable/apps/im.dino.Dino-symbolic-dark.svg', install_dir: get_option('datadir') / 'icons/breeze-dark/apps/48', rename: 'im.dino.Dino-symbolic.svg')
install_data('data/im.dino.Dino.appdata.xml', install_dir: get_option('datadir') / 'metainfo')
install_data('data/im.dino.Dino.desktop', install_dir: get_option('datadir') / 'applications')
install_data('data/im.dino.Dino.service', install_dir: get_option('datadir') / 'dbus-1/services')
