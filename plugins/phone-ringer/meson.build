dependencies = [
    dep_dino,
    dep_libcanberra,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gdk_pixbuf,
    dep_qlite,
    dep_xmpp_vala,
    dep_gtk4,
]

sources = files(
    'src/plugin.vala',
    'src/register_plugin.vala',
)

lib_phone_ringer = shared_library('phone-ringer', sources, name_prefix: '', dependencies: dependencies, kwargs: install_options)
dep_phone_ringer = declare_dependency(link_with: lib_phone_ringer, include_directories: include_directories('.'))
