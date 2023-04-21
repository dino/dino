project('xmpp-vala', 'vala')

fs = import('fs')
python = import('python')

dep_gdk_pixbuf = dependency('gdk-pixbuf-2.0')
dep_gee = dependency('gee-0.8')
dep_gio = dependency('gio-2.0')
dep_glib = dependency('glib-2.0')
dep_gmodule = dependency('gmodule-2.0')
dep_gtk4 = dependency('gtk4')
dep_icu_uc = dependency('icu-uc')
dep_libadwaita = dependency('libadwaita-1')
dep_m = meson.get_compiler('c').find_library('m', required: false)
dep_sqlite3 = dependency('sqlite3', version: '>=3.24')

prog_git = find_program('git', required: false)
prog_python = python.find_installation()

subdir('qlite')
subdir('xmpp-vala')
subdir('libdino')
subdir('main')