install_options = {'install': true, 'install_dir': get_option('libdir') / get_option('plugindir')}

subdir('http-files')
subdir('ice')
subdir('notification-sound')
subdir('omemo')
subdir('openpgp')
subdir('rtp')
if host_machine.system() == 'windows'
    subdir('win32-fonts')
    subdir('windows-notification')
endif
