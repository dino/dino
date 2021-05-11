include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GstRtp
    PKG_CONFIG_NAME gstreamer-rtp-1.0
    LIB_NAMES gstrtp
    LIB_DIR_HINTS gstreamer-1.0
    INCLUDE_NAMES gst/rtp/rtp.h
    INCLUDE_DIR_SUFFIXES gstreamer-1.0 gstreamer-1.0/include gstreamer-rtp-1.0 gstreamer-rtp-1.0/include
    DEPENDS Gst
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GstRtp
    REQUIRED_VARS GstRtp_LIBRARY
    VERSION_VAR GstRtp_VERSION)
