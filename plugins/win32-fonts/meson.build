dependencies = [
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gtk4,
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
lib_win32_fonts = shared_library('win32-fonts', sources, name_prefix: '', vala_args: vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_win32_fonts = declare_dependency(link_with: lib_win32_fonts, include_directories: include_directories('.'))
summary('Increase font size slightly on Windows', dep_win32_fonts, section: 'Plugins')