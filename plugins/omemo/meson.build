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
    dep_m,
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
    # This is to build internal vapi for tests
    '--header', meson.current_build_dir() / 'omemo.h',
    '--internal-vapi', meson.current_build_dir() / 'omemo-internal.vapi',
    '--internal-header', meson.current_build_dir() / 'omemo-internal.h',
]
lib_omemo = shared_library('omemo', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, install: true, install_dir: get_option('libdir') / get_option('plugindir'))
dep_omemo = declare_dependency(link_with: lib_omemo, include_directories: include_directories('.'))
summary('End-to-end encryption using OMEMO (omemo)', dep_omemo, section: 'Plugins')
# This is to use the internal vapi instead of the regular
vapi_omemo_internal = custom_target('omemo-internal-vapi', command: [find_program('touch'), meson.current_build_dir() / 'omemo-internal.vapi'], output: ['omemo-internal.vapi'], depends: lib_omemo)
dep_omemo_internal = declare_dependency(link_args: [lib_omemo.full_path()], include_directories: include_directories('.', 'src'), sources: [vapi_omemo_internal])

test_sources = [
    'tests/signal/common.vala',
    'tests/signal/testcase.vala',

    'tests/signal/curve25519.vala',
    'tests/signal/hkdf.vala',
    'tests/signal/session_builder.vala',
]
test_vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]

exe_omemo_test = executable('omemo-test', test_sources, c_args: c_args, vala_args: test_vala_args, dependencies: dependencies + dep_omemo_internal, build_rpath: '$ORIGIN', install: false)
test('Tests for omemo', exe_omemo_test)
