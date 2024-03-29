dependencies = [
  dep_dino,
  dep_gee,
  dep_glib,
  dep_gmodule,
  dep_gtk4,
  dep_libadwaita,
  dep_qlite,
  dep_xmpp_vala,
]

sources = files(
  'src/plugin.vala',
  'src/register_plugin.vala',
)

sources += gnome.compile_resources(
  'resources', 
  'data/gresource.xml',
  source_dir: 'data',
)

c_args = []
vala_args = []
if dep_libadwaita.version() == 'unknown' or dep_libadwaita.version().version_compare('>=1.2')
    vala_args += ['-D', 'Adw_1_2']
endif
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.6')
    vala_args += ['-D', 'GTK_4_6']
endif
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.8')
    vala_args += ['-D', 'GTK_4_8']
endif

link_args = []
if host_machine.system() == 'windows'
  link_args += ['-Wl,--export-all-symbols']
endif

libwin32_fonts = shared_library('win32-fonts', sources: sources, name_prefix:'', c_args: c_args, vala_args:vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir')/'dino/plugins', link_args: link_args)
dep_win32_fonts = declare_dependency(link_with: libwin32_fonts, include_directories: include_directories('.'))
