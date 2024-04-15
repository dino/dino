# This is a package creation module using CPack.
# Currently only DEB package generation is supported.

set(CPACK_PACKAGE_NAME dino-plus)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
    "modern XMPP/Jabber client software, based on Dino.
Dino+ is a fork of Dino, a modern XMPP/Jabber client
written in Vala using GTK+, which includes a few
relatively minor but important quality-of-life features.")

set(CPACK_VERBATIM_VARIABLES YES)
set(CPACK_PACKAGE_FILE_NAME ${CPACK_PACKAGE_NAME})
set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
set(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_SOURCE_DIR}/_packages")
set(CPACK_PACKAGE_VERSION ${VERSION_FULL})
set(CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/mxlgv/dino")
set(CPACK_PACKAGE_CONTACT "maxlogaev@proton.me")
set(CPACK_COMPONENTS_GROUPING ALL_COMPONENTS_IN_ONE)
set(CPACK_STRIP_FILES TRUE)

# For DEB only
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Maxim Logaev <${CPACK_PACKAGE_CONTACT}>")
set(CPACK_DEB_COMPONENT_INSTALL YES)
set(CPACK_DEBIAN_PACKAGE_SECTION "net")
set(CPACK_DEBIAN_PACKAGE_CONFLICTS "dino-im, dino-im-common")
set(CPACK_DEBIAN_PACKAGE_RECOMMENDS "ca-certificates, dbus, fonts-noto-color-emoji, network-manager")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY ">=")

install(FILES ${CMAKE_SOURCE_DIR}/LICENSE_SHORT DESTINATION ${SHARE_INSTALL_PREFIX}/doc/${CPACK_PACKAGE_NAME} RENAME copyright)
install(FILES ${CMAKE_SOURCE_DIR}/README.md DESTINATION ${SHARE_INSTALL_PREFIX}/doc/${CPACK_PACKAGE_NAME})

include(CPack)
