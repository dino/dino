include(PkgConfigWithFallback)
find_pkg_config_with_fallback(GstAudio
    PKG_CONFIG_NAME gstreamer-audio-1.0
    LIB_NAMES gstaudio
    LIB_DIR_HINTS gstreamer-1.0
    INCLUDE_NAMES gst/audio/audio.h
    INCLUDE_DIR_SUFFIXES gstreamer-1.0 gstreamer-1.0/include gstreamer-audio-1.0 gstreamer-audio-1.0/include
    DEPENDS Gst
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GstAudio
    REQUIRED_VARS GstAudio_LIBRARY
    VERSION_VAR GstAudio_VERSION)
