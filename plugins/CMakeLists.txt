if(NOT WITHOUT_OPENPGP)
  add_subdirectory(gpgme-vala)
  add_subdirectory(openpgp)
endif(NOT WITHOUT_OPENPGP)

if(NOT WITHOUT_OMEMO)
  add_subdirectory(omemo)
  add_subdirectory(signal-protocol)
endif(NOT WITHOUT_OMEMO)
