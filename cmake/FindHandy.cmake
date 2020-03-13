include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Handy
        PKG_CONFIG_NAME libhandy-0.0
        LIB_NAMES libhandy-0.0
        INCLUDE_NAMES handy.h
        )

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Handy
        REQUIRED_VARS Handy_LIBRARY
        VERSION_VAR Handy_VERSION)
