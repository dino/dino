include(PkgConfigWithFallback)

find_pkg_config_with_fallback(WebRTCAudioProcessing
    PKG_CONFIG_NAME webrtc-audio-processing-1
    LIB_NAMES webrtc_audio_processing-1
    INCLUDE_NAMES modules/audio_processing/include/audio_processing.h
    INCLUDE_DIR_SUFFIXES webrtc-audio-processing-1 webrtc_audio_processing-1
)
if(WebRTCAudioProcessing_FOUND AND NOT WebRTCAudioProcessing_VERSION)
    set(WebRTCAudioProcessing_VERSION "1.0")
endif()

if(NOT WebRTCAudioProcessing_FOUND)
    find_pkg_config_with_fallback(WebRTCAudioProcessing
        PKG_CONFIG_NAME webrtc-audio-processing
        LIB_NAMES webrtc_audio_processing
        INCLUDE_NAMES webrtc/modules/audio_processing/include/audio_processing.h
        INCLUDE_DIR_SUFFIXES webrtc-audio-processing webrtc_audio_processing
    )
    if(WebRTCAudioProcessing_FOUND AND NOT WebRTCAudioProcessing_VERSION)
        set(WebRTCAudioProcessing_VERSION "0.2")
    endif()
endif(NOT WebRTCAudioProcessing_FOUND)

if(NOT WebRTCAudioProcessing_FOUND)
    find_pkg_config_with_fallback(WebRTCAudioProcessing
            PKG_CONFIG_NAME webrtc-audio-processing-2
            LIB_NAMES webrtc_audio_processing-2
            INCLUDE_NAMES modules/audio_processing/include/audio_processing.h
            INCLUDE_DIR_SUFFIXES webrtc-audio-processing-2 webrtc_audio_processing-2
    )
    if(WebRTCAudioProcessing_FOUND AND NOT WebRTCAudioProcessing_VERSION)
        set(WebRTCAudioProcessing_VERSION "2.0")
    endif()
endif(NOT WebRTCAudioProcessing_FOUND)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WebRTCAudioProcessing
    REQUIRED_VARS WebRTCAudioProcessing_LIBRARY
    VERSION_VAR WebRTCAudioProcessing_VERSION)
