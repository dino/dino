include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GnuTLS
    PKG_CONFIG_NAME gnutls
    LIB_NAMES gnutls
    INCLUDE_NAMES gnutls/gnutls.h
    INCLUDE_DIR_SUFFIXES gnutls gnutls/include
    DEPENDS GLib
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GnuTLS
    REQUIRED_VARS GnuTLS_LIBRARY
    VERSION_VAR GnuTLS_VERSION)