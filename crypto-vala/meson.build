dependencies = [
    dep_gio,
    dep_glib,
    dep_libgcrypt_or_openssl,
    dep_libsrtp2,
]
sources = files(
    'src/cipher.vala',
    'src/cipher_converter.vala',
    'src/error.vala',
    'src/random.vala',
    'src/srtp.vala',
)
c_args = [
    '-DG_LOG_DOMAIN="crypto-vala"',
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
if crypto_backend == 'openssl'
    vala_args += ['--pkg', 'openssl'] # Work around https://github.com/mesonbuild/meson/issues/2103.
elif crypto_backend == 'gnutls'
    vala_args += ['-D', 'GCRYPT']
endif
lib_crypto_vala = library('crypto-vala', sources, c_args: c_args, vala_args: vala_args, dependencies: dependencies, version: '0.0', install: true, install_dir: [true, true, true])
dep_crypto_vala = declare_dependency(link_with: lib_crypto_vala, include_directories: include_directories('.'))

install_data('crypto-vala.deps', install_dir: get_option('datadir') / 'vala/vapi') # TODO: workaround for https://github.com/mesonbuild/meson/issues/9756
