include(PkgConfigWithFallbackOnConfigScript)
find_pkg_config_with_fallback_on_config_script(GCrypt
    PKG_CONFIG_NAME libgcrypt
    LIB_NAMES libgcrypt
    INCLUDE_NAMES gcrypt.h
    CONFIG_SCRIPT_NAME libgcrypt
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GCrypt
    REQUIRED_VARS GCrypt_LIBRARY
    VERSION_VAR GCrypt_VERSION)
