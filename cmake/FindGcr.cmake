include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Gcr
    PKG_CONFIG_NAME gcr-3
    LIB_NAMES gcr-3
    INCLUDE_NAMES gcr-3/gcr.h
    INCLUDE_DIR_SUFFIXES gcr-3
)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gcr
    REQUIRED_VARS Gcr_LIBRARY
    VERSION_VAR Gcr_VERSION)
