include(PkgConfigWithFallback)
find_pkg_config_with_fallback(ICU
    PKG_CONFIG_NAME icu-uc
    LIB_NAMES icuuc icudata
    INCLUDE_NAMES unicode/umachine.h
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ICU
    REQUIRED_VARS ICU_LIBRARY
    VERSION_VAR ICU_VERSION)
