dependencies = [
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gtk4,
    dep_libsoup,
    dep_qlite,
    dep_xmpp_vala,
]
sources = files(
    'src/file_provider.vala',
    'src/file_sender.vala',
    'src/plugin.vala',
    'src/register_plugin.vala',
)

vala_args = [
    '-D', 'SOUP_3_0',
]
lib_http_files = shared_library('http-files', sources, name_prefix: '', vala_args: vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_http_files = declare_dependency(link_with: lib_http_files, include_directories: include_directories('.'))
