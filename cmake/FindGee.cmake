include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Gee
    PKG_CONFIG_NAME gee-0.8
    LIB_NAMES gee-0.8
    INCLUDE_NAMES gee.h
    INCLUDE_DIR_SUFFIXES gee-0.8 gee-0.8/include
    DEPENDS GObject
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gee
    FOUND_VAR Gee_FOUND
    REQUIRED_VARS Gee_LIBRARY
    VERSION_VAR Gee_VERSION
)