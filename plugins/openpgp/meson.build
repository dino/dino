subdir('po')
dependencies = [
    dep_libadwaita,
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gpgme,
    dep_gtk4,
    dep_qlite,
    dep_xmpp_vala,
]
sources = files(
    'src/contact_details_provider.vala',
    'src/database.vala',
    'src/encryption_list_entry.vala',
    'src/encryption_preferences_entry.vala',
    'src/file_transfer/file_decryptor.vala',
    'src/file_transfer/file_encryptor.vala',
    'src/gpgme_fix.c',
    'src/gpgme_helper.vala',
    'src/manager.vala',
    'src/plugin.vala',
    'src/register_plugin.vala',
    'src/stream_flag.vala',
    'src/stream_module.vala',
    'src/util.vala',
    'vapi/gpg-error.vapi',
)
sources += gnome.compile_resources(
    'resources',
    'data/gresource.xml',
    source_dir: 'data',
)
c_args = [
    '-DG_LOG_DOMAIN="OpenPGP"',
    '-DGETTEXT_PACKAGE="dino-openpgp"',
    '-DLOCALE_INSTALL_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
if dep_libadwaita.version() == 'unknown' or dep_libadwaita.version().version_compare('>=1.4')
    vala_args += ['-D', 'Adw_1_4']
endif
lib_openpgp = shared_library('openpgp', sources, name_prefix: '', name_suffix: 'so', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, install: true, install_dir: get_option('libdir') / get_option('plugindir'), install_rpath: default_install_rpath)
dep_openpgp = declare_dependency(link_with: lib_openpgp, include_directories: include_directories('.'))
summary('End-to-end encryption using PGP (openpgp)', dep_openpgp.found(), bool_yn: true, section: 'Plugins')
