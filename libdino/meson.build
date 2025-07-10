# version_vala
dot_git = meson.current_source_dir() / '../.git'
version_file = meson.current_source_dir() / '../VERSION'
command = [prog_python, files('version.py'), version_file, '--git-repo', meson.current_source_dir()]
if prog_git.found()
    command += ['--git', prog_git]
endif
version_vala = vcs_tag(command: command, input: 'src/version.vala.in', output: 'version.vala', replace_string: '%VERSION%')

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
    'src/service/contact_model.vala',
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
    'src/service/message_retraction.vala',
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
    'src/service/sfs_metadata.vala',
    'src/service/stateless_file_sharing.vala',
    'src/service/stream_interactor.vala',
    'src/service/util.vala',
    'src/util/display_name.vala',
    'src/util/limit_input_stream.vala',
    'src/util/send_message.vala',
    'src/util/util.vala',
    'src/util/weak_map.vala',
    'src/util/weak_timeout.vala',
)
sources += [version_vala]
c_args = [
    '-DDINO_SYSTEM_LIBDIR_NAME="@0@"'.format(get_option('prefix') / get_option('libdir')),
    '-DDINO_SYSTEM_PLUGIN_DIR="@0@"'.format(get_option('prefix') / get_option('libdir') / get_option('plugindir')),
    '-DG_LOG_DOMAIN="libdino"',
]
vala_args = []
if meson.get_compiler('vala').version().version_compare('=0.56.11')
    vala_args += ['-D', 'VALA_0_56_11']
endif
lib_dino = library('libdino', sources, c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, name_prefix: '', version: '0.0', install: true, install_dir: [true, true, true], install_rpath: default_install_rpath)
dep_dino = declare_dependency(link_with: lib_dino, include_directories: include_directories('.', 'src'))

install_data('dino.deps', install_dir: get_option('datadir') / 'vala/vapi', install_tag: 'devel') # TODO: workaround for https://github.com/mesonbuild/meson/issues/9756
install_headers('src/dino_i18n.h')
