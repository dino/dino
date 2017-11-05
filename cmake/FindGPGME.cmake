include(PkgConfigWithFallbackOnConfigScript)
find_pkg_config_with_fallback_on_config_script(GPGME
    PKG_CONFIG_NAME gpgme
    CONFIG_SCRIPT_NAME gpgme
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GPGME
    REQUIRED_VARS GPGME_LIBRARY
    VERSION_VAR GPGME_VERSION)
