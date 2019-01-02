include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Qrencode
    PKG_CONFIG_NAME libqrencode
    LIB_NAMES qrencode
    INCLUDE_NAMES qrencode.h
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Qrencode
    REQUIRED_VARS Qrencode_LIBRARY
    VERSION_VAR Qrencode_VERSION)
