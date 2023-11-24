project(
    'Dino',
    'c', 'cpp', 'vala',
    license: 'GPL-3.0',
    meson_version: '>=1.3.0',
    version: run_command(
        find_program('python3', required: true), # Can't use import('python').find_installation() here
        meson.current_source_dir() / 'build-aux' / 'version.py',
        meson.current_source_dir() / 'VERSION',
        '--git-repo', meson.current_source_dir(),
        '--git', find_program('git', required: false),
        check: true
    ).stdout().strip()
)

gnome = import('gnome')
i18n = import('i18n')
cc = meson.get_compiler('c')

# Trigger recomnfiguration on version change
version_stamp = configure_file(
    command: [
        # Keep in sync with above
        find_program('python3', required: true),
        meson.current_source_dir() / 'build-aux' / 'version.py',
        meson.current_source_dir() / 'VERSION',
        '--git-repo', meson.current_source_dir(),
        '--git', find_program('git', required: false),
        # Trigger depfile generation
        '--depfile', '@DEPFILE@'
    ],
    input: 'build-aux' / 'version.py',
    output: 'version.stamp',
    depfile: 'version.d'
)

# Reduce build time noise
vala_c_args = cc.get_supported_arguments([
    '-Wno-address',
    '-Wno-deprecated-declarations',
    '-Wno-discarded-qualifiers',
    '-Wno-duplicate-decl-specifier',
    '-Wno-unused-but-set-variable',
    '-Wno-unused-function',
    '-Wno-unused-label',
    '-Wno-unused-value',
    '-Wno-unused-variable',
])

plugin_crypto = get_option('plugin-ice')
foreach plugin : ['plugin-ice', 'plugin-omemo', 'plugin-rtp']
    if get_option(plugin).enabled() and not plugin_crypto.enabled()
        plugin_crypto = get_option(plugin)
    elif get_option(plugin).allowed() and not plugin_crypto.allowed()
        plugin_crypto = get_option(plugin)
    endif
endforeach

if get_option('crypto-backend') == 'auto'
    # Prefer libgcrypt/gnutls over openssl because glib-networking is usually
    # built with gnutls anyway.
    dep_libgcrypt = dependency('libgcrypt', required: false)
    dep_gnutls = dependency('gnutls', required: false)
    if dep_libgcrypt.found() and dep_gnutls.found()
        crypto_backend = 'gnutls'
    else
        dep_openssl = dependency('openssl', disabler: true, required: plugin_crypto)
        crypto_backend = 'openssl'
    endif
elif get_option('crypto-backend') == 'openssl'
    dep_openssl = dependency('openssl', disabler: true, required: plugin_crypto)
    crypto_backend = 'openssl'
elif get_option('crypto-backend') == 'gnutls'
    dep_libgcrypt = dependency('libgcrypt', disabler: true, required: plugin_crypto)
    dep_gnutls = dependency('gnutls', disabler: true, required: get_option('plugin-ice'))
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
dep_libadwaita = dependency('libadwaita-1', version: '>=1.5')
dep_libcanberra = dependency('libcanberra', disabler: true, required: get_option('plugin-notification-sound'))
dep_libqrencode = dependency('libqrencode', disabler: true, required: get_option('plugin-omemo'))
dep_libsrtp2 = dependency('libsrtp2', disabler: true, required: plugin_crypto)
dep_libomemo_c = dependency('libomemo-c', disabler: true, required: get_option('plugin-omemo'))
dep_libsoup = dependency('libsoup-3.0')
dep_nice = dependency('nice', version: '>=0.1.15', disabler: true, required: get_option('plugin-ice'))
dep_m = meson.get_compiler('c').find_library('m', required: false)
dep_sqlite3 = dependency('sqlite3', version: '>=3.24')

dep_webrtc_audio_processing = dependency('webrtc-audio-processing-1', required: false)
if not dep_webrtc_audio_processing.found()
    dep_webrtc_audio_processing = dependency('webrtc-audio-processing', version: ['>=0.2'], required: false)
endif
if not dep_webrtc_audio_processing.found()
    dep_webrtc_audio_processing = dependency('webrtc-audio-processing-2', required: false)
endif
if not dep_webrtc_audio_processing.found()
    dep_webrtc_audio_processing = disabler()
endif

default_install_rpath = ''
if get_option('set-install-rpath')
    default_install_rpath = get_option('prefix') / get_option('libdir')
endif

subdir('qlite')
subdir('xmpp-vala')
subdir('libdino')
subdir('main')
subdir('crypto-vala')
subdir('plugins')
