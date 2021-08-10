include(PkgConfigWithFallback)
find_pkg_config_with_fallback(WebRTCAudioProcessing
    PKG_CONFIG_NAME webrtc-audio-processing
    LIB_NAMES webrtc_audio_processing
    INCLUDE_NAMES webrtc/modules/audio_processing/include/audio_processing.h
    INCLUDE_DIR_SUFFIXES webrtc-audio-processing webrtc_audio_processing
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WebRTCAudioProcessing
    REQUIRED_VARS WebRTCAudioProcessing_LIBRARY
    VERSION_VAR WebRTCAudioProcessing_VERSION)
