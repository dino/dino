if(PLUGIN_ENABLED_openpgp)
  add_subdirectory(gpgme-vala)
  add_subdirectory(openpgp)
endif(PLUGIN_ENABLED_openpgp)

if(PLUGIN_ENABLED_omemo)
  add_subdirectory(omemo)
  add_subdirectory(signal-protocol)
endif(PLUGIN_ENABLED_omemo)
