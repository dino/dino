dependencies = [
  dep_dino,
  dep_gee,
  dep_glib,
  dep_gmodule,
  dep_gtk4,
  dep_qlite,
  dep_xmpp_vala,
]

sources = files(
  'src/windows_notifications_plugin.vala',
  'src/windows_notifications_register_plugin.vala',
  'src/toast_notification_builder.vala',
  'src/win_notification_provider.vala',
  'vapi/win32.vapi',
  'vapi/winrt.vapi',
  'vapi/shortcutcreator.vapi',
  'vapi/enums.vapi',
  'vapi/winrt_windows_ui_notifications.vapi',
)

inc = include_directories(
    'api/include',
    'api/include/gobject',
    'yolort/include',
)

sources += files(
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
)

c_args = [
    '-DG_LOG_DOMAIN="windows-notification"',
    '-D_POSIX_C_SOURCE=1',
    '-DGETTEXT_PACKAGE="dino"',
]

cpp_args = [
    '-DWINRT_GLIB_H_INSIDE=1',
    '-std=c++17',
    '-iquote', meson.current_source_dir() / 'yolort/include/winrt/yolort_impl',
]

vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]

link_args = [
  '-lshlwapi', '-lntdll'
]

if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.6')
    vala_args += ['-D', 'GTK_4_6']
endif
if dep_gtk4.version() == 'unknown' or dep_gtk4.version().version_compare('>=4.8')
    vala_args += ['-D', 'GTK_4_8']
endif

if host_machine.system() == 'windows'
  link_args += ['-Wl,--export-all-symbols']
endif

libwindows_notification = shared_library('windows-notification', sources: sources, include_directories: inc, name_prefix:'', c_args: c_args, vala_args:vala_args, dependencies: dependencies, install: true, install_dir: get_option('libdir')/'dino/plugins', link_args: link_args, cpp_args: cpp_args)
dep_windows_notification = declare_dependency(link_with: libwindows_notification, include_directories: include_directories('.'))
