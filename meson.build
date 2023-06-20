project('xmpp-vala', 'vala')

fs = import('fs')
gnome = import('gnome')
i18n = import('i18n')
python = import('python')

dep_gdk_pixbuf = dependency('gdk-pixbuf-2.0')
dep_gee = dependency('gee-0.8')
dep_gio = dependency('gio-2.0')
dep_glib = dependency('glib-2.0')
dep_gnutls = dependency('gnutls')
dep_gmodule = dependency('gmodule-2.0')
dep_gpgme = dependency('gpgme')
dep_gtk4 = dependency('gtk4')
dep_icu_uc = dependency('icu-uc')
dep_libadwaita = dependency('libadwaita-1')
dep_libcanberra = dependency('libcanberra')
dep_libgcrypt = dependency('libgcrypt')
dep_libqrencode = dependency('libqrencode')
dep_libsrtp2 = dependency('libsrtp2')
# libsignal-protocol-c has a history of breaking compatibility on the patch level
# we'll have to check compatibility for every new release
# distro maintainers may update this dependency after compatibility tests
dep_libsignal_protocol_c = dependency('libsignal-protocol-c', version: ['>=2.3.2', '<2.3.4'])
dep_libsoup = dependency('libsoup-3.0')
dep_nice = dependency('nice', version: '>=0.1.15')
dep_m = meson.get_compiler('c').find_library('m', required: false)
dep_sqlite3 = dependency('sqlite3', version: '>=3.24')

prog_git = find_program('git', required: false)
prog_python = python.find_installation()

subdir('qlite')
subdir('xmpp-vala')
subdir('libdino')
subdir('main')
subdir('crypto-vala')
subdir('plugins')
