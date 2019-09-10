if(PLUGIN_ENABLED_http-files)
  add_subdirectory(http-files)
endif(PLUGIN_ENABLED_http-files)

if(PLUGIN_ENABLED_openpgp)
  add_subdirectory(gpgme-vala)
  add_subdirectory(openpgp)
endif(PLUGIN_ENABLED_openpgp)

if(PLUGIN_ENABLED_omemo)
  add_subdirectory(crypto-vala)
  add_subdirectory(omemo)
  add_subdirectory(signal-protocol)
endif(PLUGIN_ENABLED_omemo)

if(PLUGIN_ENABLED_notification-sound)
  add_subdirectory(notification-sound)
endif(PLUGIN_ENABLED_notification-sound)
