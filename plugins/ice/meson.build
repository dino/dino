dependencies = [
    dep_crypto_vala,
    dep_dino,
    dep_gdk_pixbuf,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gnutls,
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
lib_ice = shared_library('ice', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir') / get_option('plugindir'))
dep_ice = declare_dependency(link_with: lib_ice, include_directories: include_directories('.'))
summary('Peer-to-peer communication (ice)', dep_ice, section: 'Plugins')
