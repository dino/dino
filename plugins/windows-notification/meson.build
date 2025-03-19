# TODO: somehow reuse main Dino po
subdir('po')
dep_shlwapi = declare_dependency(
    link_args: ['-lshlwapi']
)
dep_ntdll = declare_dependency(
    link_args: ['-lntdll']
)
dep_windowsapp = declare_dependency(
    link_args: ['-lwindowsapp']
)

dependencies = [
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gtk4,
    dep_qlite,
    dep_xmpp_vala,
    dep_shlwapi,
    dep_ntdll,
    dep_windowsapp,
]
sources = files(
    'src/windows_notifications_plugin.vala',
    'src/windows_notifications_register_plugin.vala',
    'src/toast_notification_builder.vala',
    'src/win_notification_provider.vala',
    'api/src/gobject/winrt-enums.cpp',
    'api/src/gobject/winrt-event-token.cpp',
    'api/src/gobject/winrt-toast-notification.cpp',
    'api/src/gobject/winrt-toast-notifier.cpp',
    'api/src/gobject/winrt.cpp',
    'api/src/win32.cpp',
    'api/src/converter.cpp',
    'api/src/dyn_mod.cpp',
    'api/src/ginvoke.cpp',
    'api/src/shortcutcreator.cpp',
    'vapi/win32.vapi',
    'vapi/winrt.vapi',
    'vapi/shortcutcreator.vapi',
    'vapi/enums.vapi',
    'vapi/winrt_windows_ui_notifications.vapi',
)
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
c_args = [
    '-DG_LOG_DOMAIN="windows-notification"',
    '-DGETTEXT_PACKAGE="dino-windows-notifications"',
    '-DLOCALE_INSTALL_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
]
cpp_args = [
    '-std=c++20',
    '-DWINRT_GLIB_H_INSIDE',
]
includes = include_directories(
    'api/include',
    'api/include/gobject',
)
lib_windows_notification = shared_library('windows-notification', sources, cpp_args: cpp_args, name_prefix: '', vala_args: vala_args, c_args: c_args, dependencies: dependencies, include_directories: includes, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_windows_notification = declare_dependency(link_with: lib_windows_notification, include_directories: include_directories('.'))
summary('Native notifications support for Windows', dep_windows_notification, section: 'Plugins')