project('xmpp-vala', 'c', 'cpp', 'vala')

fs = import('fs')
gnome = import('gnome')
i18n = import('i18n')
python = import('python')

# plugin_crypto is enabled if any of the crypto plugins is enabled, auto if
# none of them are explicitly enabled but at least one is set to auto, or
# disabled if all of them are disabled.
#
# On Windows, it's always required because we need it for glib-networking.
if host_machine.system() == 'windows'
    plugin_crypto = true
else
    plugin_crypto = get_option('plugin-ice')
    foreach plugin : ['plugin-ice', 'plugin-omemo', 'plugin-rtp']
        if get_option(plugin).enabled() and not plugin_crypto.enabled()
            plugin_crypto = get_option(plugin)
        elif get_option(plugin).allowed() and not plugin_crypto.allowed()
            plugin_crypto = get_option(plugin)
        endif
    endforeach
endif

if get_option('crypto-backend') == 'auto'
    # Prefer libgcrypt/gnutls over openssl because glib-networking is usually
    # built with gnutls anyway.
    dep_libgcrypt = dependency('libgcrypt', required: false)
    dep_gnutls = dependency('gnutls', required: false)
    if dep_libgcrypt.found() and dep_libgcrypt.found()
        dep_libgcrypt_or_openssl = dep_libgcrypt
        dep_gnutls_or_openssl = dep_gnutls
        crypto_backend = 'gnutls'
    else
        dep_openssl = dependency('openssl', disabler: true, required: plugin_crypto)
        dep_libgcrypt_or_openssl = dep_openssl
        dep_gnutls_or_openssl = dep_openssl
        crypto_backend = 'openssl'
    endif
elif get_option('crypto-backend') == 'openssl'
    dep_openssl = dependency('openssl', disabler: true, required: plugin_crypto)
    dep_libgcrypt_or_openssl = dep_openssl
    dep_gnutls_or_openssl = dep_openssl
    crypto_backend = 'openssl'
elif get_option('crypto-backend') == 'gnutls'
    dep_libgcrypt = dependency('libgcrypt', disabler: true, required: plugin_crypto)
    dep_gnutls = dependency('gnutls', disabler: true, required: get_option('plugin-ice'))
    dep_libgcrypt_or_openssl = dep_libgcrypt
    dep_gnutls_or_openssl = dep_gnutls
    crypto_backend = 'gnutls'
endif

dep_gdk_pixbuf = dependency('gdk-pixbuf-2.0')
dep_gee = dependency('gee-0.8')
dep_gio = dependency('gio-2.0')
dep_glib = dependency('glib-2.0')
dep_gmodule = dependency('gmodule-2.0')
dep_gpgme = dependency('gpgme', disabler: true, required: get_option('plugin-openpgp'))
dep_gstreamer = dependency('gstreamer-1.0', disabler: true, required: get_option('plugin-rtp'))
dep_gstreamer_app = dependency('gstreamer-app-1.0', disabler: true, required: get_option('plugin-rtp'))
dep_gstreamer_audio = dependency('gstreamer-audio-1.0', disabler: true, required: get_option('plugin-rtp'))
dep_gstreamer_rtp = dependency('gstreamer-rtp-1.0', disabler: true, required: get_option('plugin-rtp'))
dep_gstreamer_video = dependency('gstreamer-video-1.0', disabler: true, required: get_option('plugin-rtp'))
dep_gtk4 = dependency('gtk4')
dep_icu_uc = dependency('icu-uc')
dep_libadwaita = dependency('libadwaita-1', version: '>=1.2')
dep_libcanberra = dependency('libcanberra', disabler: true, required: get_option('plugin-notification-sound'))
dep_libqrencode = dependency('libqrencode', disabler: true, required: get_option('plugin-omemo'))
dep_libsrtp2 = dependency('libsrtp2', disabler: true, required: plugin_crypto)
# libsignal-protocol-c has a history of breaking compatibility on the patch level
# we'll have to check compatibility for every new release
# distro maintainers may update this dependency after compatibility tests
dep_libsignal_protocol_c = dependency('libsignal-protocol-c', version: ['>=2.3.2', '<2.3.4'], disabler: true, required: get_option('plugin-omemo'))
dep_libsoup = dependency('libsoup-3.0', disabler: true, required: get_option('plugin-http-files'))
dep_nice = dependency('nice', version: '>=0.1.15', disabler: true, required: get_option('plugin-ice'))
dep_m = meson.get_compiler('c').find_library('m', required: false)
dep_sqlite3 = dependency('sqlite3', version: '>=3.24')
dep_webrtc_audio_processing = dependency('webrtc-audio-processing', version: ['>=0.2', '<0.4'], required: get_option('plugin-rtp-webrtc-audio-processing'))

prog_git = find_program('git', required: false)
prog_python = python.find_installation()

subdir('qlite')
subdir('xmpp-vala')
subdir('libdino')
subdir('main')
subdir('crypto-vala')
subdir('plugins')
