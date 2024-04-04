dependencies = [
    dep_dino,
    dep_gdk_pixbuf,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_libcanberra,
    dep_qlite,
    dep_xmpp_vala,
]
sources = files(
    'src/plugin.vala',
    'src/register_plugin.vala',
)
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
lib_notification_sound = shared_library('notification-sound', sources, name_prefix: '', vala_args: vala_args, dependencies: dependencies, kwargs: install_options)
dep_notification_sound = declare_dependency(link_with: lib_notification_sound, include_directories: include_directories('.'))
