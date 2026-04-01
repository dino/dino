dependencies = [
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_libcanberra,
    dep_qlite,
    dep_xmpp_vala,
    dep_gio,
]
sources = files(
    'src/plugin.vala',
    'src/register_plugin.vala',
)
lib_phone_ringer = shared_library('phone-ringer', sources, name_prefix: '', dependencies: dependencies, install: true, install_dir: get_option('libdir') / get_option('plugindir'), install_rpath: default_install_rpath)
dep_phone_ringer = declare_dependency(link_with: lib_phone_ringer, include_directories: include_directories('.'))
summary('Sound for call notifications (phone-ringer)', dep_phone_ringer, section: 'Plugins')
