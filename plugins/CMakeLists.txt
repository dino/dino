if(WIN32)
    add_link_options("-Wl,--export-all-symbols")
endif(WIN32)

if(DINO_PLUGIN_ENABLED_http-files)
  add_subdirectory(http-files)
endif(DINO_PLUGIN_ENABLED_http-files)

if(DINO_PLUGIN_ENABLED_ice)
  add_subdirectory(ice)
endif(DINO_PLUGIN_ENABLED_ice)

if(DINO_PLUGIN_ENABLED_rtp)
  add_subdirectory(rtp)
endif(DINO_PLUGIN_ENABLED_rtp)

if(DINO_PLUGIN_ENABLED_openpgp)
  add_subdirectory(gpgme-vala)
  add_subdirectory(openpgp)
endif(DINO_PLUGIN_ENABLED_openpgp)

if(DINO_PLUGIN_ENABLED_omemo)
  add_subdirectory(omemo)
  add_subdirectory(signal-protocol)
endif(DINO_PLUGIN_ENABLED_omemo)

if(DINO_PLUGIN_ENABLED_notification-sound)
  add_subdirectory(notification-sound)
endif(DINO_PLUGIN_ENABLED_notification-sound)

if(DINO_PLUGIN_ENABLED_win32-fonts)
  add_subdirectory(win32-fonts)
endif(DINO_PLUGIN_ENABLED_win32-fonts)
