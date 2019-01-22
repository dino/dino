include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GSasl
    PKG_CONFIG_NAME libgsasl
    LIB_NAMES gsasl
    INCLUDE_NAMES gsasl.h
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GSasl
    REQUIRED_VARS GSasl_LIBRARY
    VERSION_VAR GSasl_VERSION)
