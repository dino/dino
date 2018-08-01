include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Canberra
    PKG_CONFIG_NAME libcanberra
    LIB_NAMES canberra
    INCLUDE_NAMES canberra.h
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Canberra
    REQUIRED_VARS Canberra_LIBRARY)
