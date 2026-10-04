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
    'src/ui/conversation_content_view/file_transmission_progress.c',
    'src/ui/conversation_content_view/file_transmission_progress.vala',
    'src/ui/conversation_content_view/file_group_widget.vala',
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
    'src/ui/util/leak.vala',
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

c_args = vala_c_args + [
    '-DG_LOG_DOMAIN="dino"',
    '-DGETTEXT_PACKAGE="dino"',
    '-DLOCALE_INSTALL_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]

if get_option('rtp').allowed() and dep_gstreamer.found() and dep_gstreamer_app.found() and dep_gstreamer_audio.found() and dep_gstreamer_rtp.found() and dep_gstreamer_video.found()
    dependencies += [
        dep_gstreamer,
        dep_gstreamer_app,
        dep_gstreamer_audio,
        dep_gstreamer_rtp,
        dep_gstreamer_video,
    ]

    sources += files(
        'src/plugins/rtp/codec_util.vala',
        'src/plugins/rtp/device.vala',
        'src/plugins/rtp/gst_fixes.c',
        'src/plugins/rtp/module.vala',
        'src/plugins/rtp/plugin.vala',
        'src/plugins/rtp/stream.vala',
        'src/plugins/rtp/video_widget.vala',
    )

    if dep_webrtc_audio_processing.found() and get_option('voice-processing').allowed()
        voice_dependencies = [
            dep_gstreamer_audio,
            dep_webrtc_audio_processing,
        ]
        voice_sources = files(
            'src/plugins/rtp/voice_processor_native.cpp',
        )
        voice_c_args = c_args
        if dep_webrtc_audio_processing.version().version_compare('>=2.0')
            voice_c_args += ['-DWEBRTC2']
        elif dep_webrtc_audio_processing.version().version_compare('>=1.0')
            voice_c_args += ['-DWEBRTC1']
        else
            voice_c_args += ['-DWEBRTC0']
        endif
        lib_rtp_voice_processor = static_library('rtp-voice-processor', voice_sources, c_args: voice_c_args, cpp_args: voice_c_args, dependencies: voice_dependencies, install: false)
        dep_rtp_voice_processor = declare_dependency(link_with: lib_rtp_voice_processor)
        vala_args += ['-D', 'WITH_VOICE_PROCESSOR']
        dependencies += [dep_rtp_voice_processor]
        sources += files(
            'src/plugins/rtp/voice_processor.vala',
        )
    endif
    if get_option('rtp-h264')
        vala_args += ['-D', 'ENABLE_H264']
    endif
    if get_option('rtp-msdk')
        vala_args += ['-D', 'ENABLE_MSDK']
    endif
    if get_option('rtp-vaapi')
        vala_args += ['-D', 'ENABLE_VAAPI']
    endif
    if get_option('rtp-vp9')
        vala_args += ['-D', 'ENABLE_VP9']
    endif
    vala_args += ['-D', 'WITH_RTP']

    summary('Voice/video calls (rtp)', true, bool_yn: true, section: 'Plugins')
    summary('H264 codec', get_option('rtp-h264'), bool_yn: true, section: 'RTP configuration')
    summary('VP9 codec', get_option('rtp-vp9'), bool_yn: true, section: 'RTP configuration')
    summary('Intel MediaSDK', get_option('rtp-msdk'), bool_yn: true, section: 'RTP configuration')
    summary('Video Acceleration API', get_option('rtp-vaapi'), bool_yn: true, section: 'RTP configuration')
    summary('Voice preprocessing', dep_webrtc_audio_processing.found() and get_option('voice-processing').allowed(), bool_yn: true, section: 'RTP configuration')
else
    summary('Voice/video calls (rtp)', false, bool_yn: true, section: 'Plugins')
endif

if get_option('omemo').allowed() and dep_libomemo_c.found() and dep_libqrencode.found()
    dependencies += [
        dep_libomemo_c,
        dep_libqrencode,
    ]
    sources += files(
        'src/plugins/omemo/dtls_srtp_verification_draft.vala',
        'src/plugins/omemo/file_transfer/file_decryptor.vala',
        'src/plugins/omemo/file_transfer/file_encryptor.vala',
        'src/plugins/omemo/jingle/jet_omemo.vala',
        'src/plugins/omemo/jingle/jingle_helper.vala',
        'src/plugins/omemo/logic/database.vala',
        'src/plugins/omemo/logic/decrypt.vala',
        'src/plugins/omemo/logic/encrypt.vala',
        'src/plugins/omemo/logic/manager.vala',
        'src/plugins/omemo/logic/pre_key_store.vala',
        'src/plugins/omemo/logic/session_store.vala',
        'src/plugins/omemo/logic/signed_pre_key_store.vala',
        'src/plugins/omemo/logic/trust_manager.vala',
        'src/plugins/omemo/plugin.vala',
        'src/plugins/omemo/protocol/bundle.vala',
        'src/plugins/omemo/protocol/message_flag.vala',
        'src/plugins/omemo/protocol/stream_module.vala',
        'src/plugins/omemo/trust_level.vala',
        'src/plugins/omemo/ui/bad_messages_populator.vala',
        'src/plugins/omemo/ui/call_encryption_entry.vala',
        'src/plugins/omemo/ui/contact_details_provider.vala',
        'src/plugins/omemo/ui/device_notification_populator.vala',
        'src/plugins/omemo/ui/encryption_list_entry.vala',
        'src/plugins/omemo/ui/encryption_preferences_entry.vala',
        'src/plugins/omemo/ui/manage_key_dialog.vala',
        'src/plugins/omemo/ui/own_notifications.vala',
        'src/plugins/omemo/ui/util.vala',
    )
    vala_args += ['-D', 'WITH_OMEMO']

    summary('End-to-end encryption using OMEMO (omemo)', true, bool_yn: true, section: 'Plugins')
else
    summary('End-to-end encryption using OMEMO (omemo)', false, bool_yn: true, section: 'Plugins')
endif

if get_option('openpgp').allowed() and dep_gpgme.found()
    dependencies += [
        dep_gpgme,
    ]
    sources += files(
        'src/plugins/openpgp/contact_details_provider.vala',
        'src/plugins/openpgp/database.vala',
        'src/plugins/openpgp/encryption_list_entry.vala',
        'src/plugins/openpgp/encryption_preferences_entry.vala',
        'src/plugins/openpgp/file_transfer/file_decryptor.vala',
        'src/plugins/openpgp/file_transfer/file_encryptor.vala',
        'src/plugins/openpgp/gpgme_fix.c',
        'src/plugins/openpgp/gpgme_helper.vala',
        'src/plugins/openpgp/manager.vala',
        'src/plugins/openpgp/plugin.vala',
        'src/plugins/openpgp/stream_module.vala',
        'src/plugins/openpgp/util.vala',
        'vapi/gpg-error.vapi',
    )
    vala_args += ['-D', 'WITH_OPENPGP']

    summary('End-to-end encryption using PGP (openpgp)', true, bool_yn: true, section: 'Plugins')
else
    summary('End-to-end encryption using PGP (openpgp)', false, bool_yn: true, section: 'Plugins')
endif

exe_dino = executable('dino', sources, c_args: c_args, vala_args: vala_args, dependencies: dependencies, install: true, install_rpath: default_install_rpath)

install_data('data/icons/scalable/apps/im.dino.Dino-symbolic.svg', install_dir: get_option('datadir') / 'icons/hicolor/symbolic/apps')
install_data('data/icons/scalable/apps/im.dino.Dino.svg', install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps')
install_data('data/im.dino.Dino.appdata.xml', install_dir: get_option('datadir') / 'metainfo')
install_data('data/im.dino.Dino.desktop', install_dir: get_option('datadir') / 'applications')
install_data('data/im.dino.Dino.service', install_dir: get_option('datadir') / 'dbus-1/services')
