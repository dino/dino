if(DINO_PLUGIN_ENABLED_http-files)
  add_subdirectory(http-files)
endif(DINO_PLUGIN_ENABLED_http-files)

if(DINO_PLUGIN_ENABLED_openpgp)
  add_subdirectory(gpgme-vala)
  add_subdirectory(openpgp)
endif(DINO_PLUGIN_ENABLED_openpgp)

if(DINO_PLUGIN_ENABLED_omemo)
  add_subdirectory(crypto-vala)
  add_subdirectory(omemo)
  add_subdirectory(signal-protocol)
endif(DINO_PLUGIN_ENABLED_omemo)

if(DINO_PLUGIN_ENABLED_notification-sound)
  add_subdirectory(notification-sound)
endif(DINO_PLUGIN_ENABLED_notification-sound)
