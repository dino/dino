# version_vala
dot_git = meson.current_source_dir() / '../.git'
version_file = meson.current_source_dir() / '../VERSION'
command = [prog_python, files('version.py'), version_file, '@OUTPUT@', '--git-repo', meson.current_source_dir()]
if prog_git.found()
    command += ['--git', prog_git]
endif
depend_files = []
if fs.exists(dot_git)
    depend_files += [dot_git]
endif
if fs.exists(version_file)
    depend_files += [version_file]
endif
version_vala = custom_target('libdino_version_vala', command: command, output: 'version.vala', depend_files: depend_files)

# libdino
dependencies = [
    dep_gdk_pixbuf,
    dep_gee,
    dep_gio,
    dep_glib,
    dep_gmodule,
    dep_qlite,
    dep_xmpp_vala
]
sources = files(
    'src/application.vala',
    'src/dbus/login1.vala',
    'src/dbus/notifications.vala',
    'src/dbus/upower.vala',
    'src/entity/account.vala',
    'src/entity/call.vala',
    'src/entity/conversation.vala',
    'src/entity/encryption.vala',
    'src/entity/file_transfer.vala',
    'src/entity/message.vala',
    'src/entity/settings.vala',
    'src/plugin/interfaces.vala',
    'src/plugin/loader.vala',
    'src/plugin/registry.vala',
    'src/service/avatar_manager.vala',
    'src/service/blocking_manager.vala',
    'src/service/call_store.vala',
    'src/service/call_state.vala',
    'src/service/call_peer_state.vala',
    'src/service/calls.vala',
    'src/service/chat_interaction.vala',
    'src/service/connection_manager.vala',
    'src/service/content_item_store.vala',
    'src/service/conversation_manager.vala',
    'src/service/counterpart_interaction_manager.vala',
    'src/service/database.vala',
    'src/service/entity_capabilities_storage.vala',
    'src/service/entity_info.vala',
    'src/service/fallback_body.vala',
    'src/service/file_manager.vala',
    'src/service/file_transfer_storage.vala',
    'src/service/history_sync.vala',
    'src/service/jingle_file_transfers.vala',
    'src/service/message_correction.vala',
    'src/service/message_processor.vala',
    'src/service/message_storage.vala',
    'src/service/module_manager.vala',
    'src/service/muc_manager.vala',
    'src/service/notification_events.vala',
    'src/service/presence_manager.vala',
    'src/service/replies.vala',
    'src/service/reactions.vala',
    'src/service/registration.vala',
    'src/service/roster_manager.vala',
    'src/service/search_processor.vala',
    'src/service/stream_interactor.vala',
    'src/service/util.vala',
    'src/util/display_name.vala',
    'src/util/util.vala',
    'src/util/weak_map.vala',
)
sources += [version_vala]
c_args = [
    '-DDINO_SYSTEM_LIBDIR_NAME="@0@"'.format(get_option('prefix') / get_option('libdir')),
    '-DDINO_SYSTEM_PLUGIN_DIR="@0@"'.format(get_option('prefix') / get_option('plugindir')),
    '-DG_LOG_DOMAIN="libdino"',
]
lib_dino = library('dino', sources, c_args: c_args, include_directories: include_directories('src'), dependencies: dependencies)
dep_dino = declare_dependency(link_with: lib_dino, include_directories: include_directories('.', 'src'))
