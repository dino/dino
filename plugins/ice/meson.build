if crypto_backend == 'openssl'
    if get_option('plugin-ice').enabled()
        error('plugin-ice does not work with openssl backend yet')
    else
        subdir_done()
    endif
endif
dependencies = [
    dep_crypto_vala,
    dep_dino,
    dep_gdk_pixbuf,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gnutls_or_openssl,
    dep_nice,
    dep_qlite,
    dep_xmpp_vala,
]
sources = files(
    'src/dtls_srtp.vala',
    'src/module.vala',
    'src/plugin.vala',
    'src/transport_parameters.vala',
    'src/util.vala',
    'src/register_plugin.vala',
)
c_args = [
    '-DG_LOG_DOMAIN="ice"',
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
lib_ice = shared_library('ice', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_ice = declare_dependency(link_with: lib_ice, include_directories: include_directories('.'))
