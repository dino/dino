include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Nice
    PKG_CONFIG_NAME nice
    LIB_NAMES nice
    INCLUDE_NAMES nice.h
    INCLUDE_DIR_SUFFIXES nice nice/include
    DEPENDS GIO
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Nice
    REQUIRED_VARS Nice_LIBRARY
    VERSION_VAR Nice_VERSION)
