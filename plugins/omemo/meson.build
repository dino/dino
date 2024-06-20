subdir('po')
dependencies = [
    dep_libadwaita,
    dep_crypto_vala,
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gtk4,
    dep_libgcrypt,
    dep_libqrencode,
    dep_libsignal_protocol_c,
    dep_qlite,
    dep_xmpp_vala,
]
sources = files(
    'src/dtls_srtp_verification_draft.vala',
    'src/file_transfer/file_decryptor.vala',
    'src/file_transfer/file_encryptor.vala',
    'src/jingle/jet_omemo.vala',
    'src/jingle/jingle_helper.vala',
    'src/logic/database.vala',
    'src/logic/decrypt.vala',
    'src/logic/encrypt.vala',
    'src/logic/manager.vala',
    'src/logic/pre_key_store.vala',
    'src/logic/session_store.vala',
    'src/logic/signed_pre_key_store.vala',
    'src/logic/trust_manager.vala',
    'src/plugin.vala',
    'src/protocol/bundle.vala',
    'src/protocol/message_flag.vala',
    'src/protocol/stream_module.vala',
    'src/register_plugin.vala',
    'src/signal/context.vala',
    'src/signal/signal_helper.c',
    'src/signal/simple_iks.vala',
    'src/signal/simple_pks.vala',
    'src/signal/simple_spks.vala',
    'src/signal/simple_ss.vala',
    'src/signal/store.vala',
    'src/signal/util.vala',
    'src/trust_level.vala',
    'src/ui/bad_messages_populator.vala',
    'src/ui/call_encryption_entry.vala',
    'src/ui/contact_details_dialog.vala',
    'src/ui/contact_details_provider.vala',
    'src/ui/device_notification_populator.vala',
    'src/ui/encryption_list_entry.vala',
    'src/ui/encryption_preferences_entry.vala',
    'src/ui/manage_key_dialog.vala',
    'src/ui/own_notifications.vala',
    'src/ui/util.vala',
)
sources += gnome.compile_resources(
    'resources',
    'data/gresource.xml',
    source_dir: 'data',
)
c_args = [
    '-DG_LOG_DOMAIN="OMEMO"',
    '-DGETTEXT_PACKAGE="dino-omemo"',
    '-DLOCALE_INSTALL_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
if dep_libadwaita.version() == 'unknown' or dep_libadwaita.version().version_compare('>=1.2')
    vala_args += ['-D', 'Adw_1_2']
endif
lib_omemo = shared_library('omemo', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_omemo = declare_dependency(link_with: lib_omemo, include_directories: include_directories('.'))
