include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Srtp2
    PKG_CONFIG_NAME libsrtp2
    LIB_NAMES srtp2
    INCLUDE_NAMES srtp2/srtp.h
    INCLUDE_DIR_SUFFIXES srtp2 srtp2/include
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Srtp2
    REQUIRED_VARS Srtp2_LIBRARY
    VERSION_VAR Srtp2_VERSION)