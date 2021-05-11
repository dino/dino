include(PkgConfigWithFallback)
find_pkg_config_with_fallback(Gst
    PKG_CONFIG_NAME gstreamer-1.0
    LIB_NAMES gstreamer-1.0
    INCLUDE_NAMES gst/gst.h
    INCLUDE_DIR_SUFFIXES gstreamer-1.0 gstreamer-1.0/include
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Gst
    REQUIRED_VARS Gst_LIBRARY
    VERSION_VAR Gst_VERSION)
