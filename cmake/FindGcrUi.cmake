include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GcrUi
    PKG_CONFIG_NAME gcr-ui-3
    LIB_NAMES gcr-ui-3
    INCLUDE_NAMES gcr-ui-3/ui/gcr-ui.h
    INCLUDE_DIR_SUFFIXES gcr-ui-3
)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GcrUi
    REQUIRED_VARS GcrUi_LIBRARY
    VERSION_VAR GcrUi_VERSION)
