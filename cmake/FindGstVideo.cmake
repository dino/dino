include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GstVideo
    PKG_CONFIG_NAME gstreamer-video-1.0
    LIB_NAMES gstvideo
    LIB_DIR_HINTS gstreamer-1.0
    INCLUDE_NAMES gst/video/video.h
    INCLUDE_DIR_SUFFIXES gstreamer-1.0 gstreamer-1.0/include gstreamer-video-1.0 gstreamer-video-1.0/include
    DEPENDS Gst
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GstVideo
    REQUIRED_VARS GstVideo_LIBRARY
    VERSION_VAR GstVideo_VERSION)
