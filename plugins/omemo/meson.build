subdir('po')
dependencies = [
    dep_libadwaita,
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gtk4,
    dep_libomemo_c,
    dep_m,
    dep_xmpp_vala,
]
sources = files(
)
sources += gnome.compile_resources(
    'resources',
    'data/gresource.xml',
    source_dir: 'data',
)
c_args = vala_c_args + [
    '-DG_LOG_DOMAIN="OMEMO"',
    '-DGETTEXT_PACKAGE="dino-omemo"',
    '-DLOCALE_INSTALL_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
    # This is to build internal vapi for tests
    '--header', meson.current_build_dir() / 'omemo.h',
    '--internal-vapi', meson.current_build_dir() / 'omemo-internal.vapi',
    '--internal-header', meson.current_build_dir() / 'omemo-internal.h',
]
lib_omemo = shared_library('omemo', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, install: true, install_dir: get_option('libdir') / get_option('plugindir'), install_rpath: default_install_rpath)
dep_omemo = declare_dependency(link_with: lib_omemo, include_directories: include_directories('.'))
# This is to use the internal vapi instead of the regular
vapi_omemo_internal = custom_target('omemo-internal-vapi', command: [find_program('touch'), meson.current_build_dir() / 'omemo-internal.vapi'], output: ['omemo-internal.vapi'], depends: lib_omemo)
dep_omemo_internal = declare_dependency(link_args: [lib_omemo.full_path()], include_directories: include_directories('.', 'src'), sources: [vapi_omemo_internal])

test_sources = [
    'tests/native/common.vala',
    'tests/native/testcase.vala',

    'tests/native/curve25519.vala',
    'tests/native/hkdf.vala',
    'tests/native/session_builder.vala',
]
test_vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]

exe_omemo_test = executable('omemo-test', test_sources, c_args: c_args, vala_args: test_vala_args, dependencies: dependencies + dep_omemo_internal, build_rpath: '$ORIGIN', install: false)
test('Tests for omemo', exe_omemo_test)
