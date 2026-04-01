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
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
lib_notification_sound = shared_library('notification-sound', sources, name_prefix: '', vala_args: vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir') / get_option('plugindir'), install_rpath: default_install_rpath)
dep_notification_sound = declare_dependency(link_with: lib_notification_sound, include_directories: include_directories('.'))
summary('Sound for chat notifications (notification-sound)', dep_notification_sound, section: 'Plugins')