include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GstApp
    PKG_CONFIG_NAME gstreamer-app-1.0
    LIB_NAMES gstapp
    LIB_DIR_HINTS gstreamer-1.0
    INCLUDE_NAMES gst/app/app.h
    INCLUDE_DIR_SUFFIXES gstreamer-1.0 gstreamer-1.0/include gstreamer-app-1.0 gstreamer-app-1.0/include
    DEPENDS Gst
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GstApp
    REQUIRED_VARS GstApp_LIBRARY
    VERSION_VAR GstApp_VERSION)
