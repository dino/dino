find_package(GLib ${GLib_GLOBAL_VERSION} REQUIRED)
find_package(WebRTCAudioProcessing 0.2)
find_packages(RTP_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GObject
    GTK4
    Gst
    GstApp
    GstAudio
    GstRtp
    GstVideo
)

set(RTP_DEFINITIONS)
set(RTP_EXTRA_OPTIONS)

if(GstRtp_VERSION VERSION_GREATER_EQUAL "1.16")
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} GST_1_16)
endif()

if(GstRtp_VERSION VERSION_GREATER_EQUAL "1.18")
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} GST_1_18)
endif()

if(GstRtp_VERSION VERSION_GREATER_EQUAL "1.20")
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} GST_1_20)
endif()

if(NOT VALA_VERSION VERSION_GREATER_EQUAL "0.56.1")
    set(RTP_EXTRA_OPTIONS ${RTP_EXTRA_OPTIONS} --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi)
endif()

set(RTP_ENABLE_VP9 "no" CACHE BOOL "Enable VP9 support")
if(RTP_ENABLE_VP9)
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} ENABLE_VP9)
endif()

set(RTP_ENABLE_H264 "no" CACHE BOOL "Enable H264 support")
if(RTP_ENABLE_H264)
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} ENABLE_H264)
endif()

set(RTP_ENABLE_VAAPI "no" CACHE BOOL "Enable VAAPI support")
if(RTP_ENABLE_VAAPI)
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} ENABLE_VAAPI)
endif()

set(RTP_ENABLE_MSDK "no" CACHE BOOL "Enable MSDK support")
if(RTP_ENABLE_MSDK)
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} ENABLE_MSDK)
endif()

if(WebRTCAudioProcessing_VERSION GREATER_EQUAL "3.0")
    message(STATUS "Ignoring WebRTCAudioProcessing, only versions 0.2+, 1.* and 2.* supported so far")
    unset(WebRTCAudioProcessing_FOUND)
endif()

if(WebRTCAudioProcessing_FOUND)
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} WITH_VOICE_PROCESSOR)
    if(WebRTCAudioProcessing_VERSION GREATER_EQUAL "2.0")
        set(RTP_VOICE_PROCESSOR_CFLAGS "-DWEBRTC2")
        set(RTP_VOICE_PROCESSOR_LIB webrtc-audio-processing-2)
    elseif(WebRTCAudioProcessing_VERSION GREATER_EQUAL "1.0")
        set(RTP_VOICE_PROCESSOR_CFLAGS "-DWEBRTC1")
        set(RTP_VOICE_PROCESSOR_LIB webrtc-audio-processing-1)
    else()
        set(RTP_VOICE_PROCESSOR_CFLAGS "-DWEBRTC0")
        set(RTP_VOICE_PROCESSOR_LIB webrtc-audio-processing)
    endif()
    set(RTP_VOICE_PROCESSOR_VALA src/voice_processor.vala)
    set(RTP_VOICE_PROCESSOR_CXX src/voice_processor_native.cpp)
else()
    message(STATUS "WebRTCAudioProcessing not found, build without voice pre-processing!")
endif()

vala_precompile(RTP_VALA_C
SOURCES
    src/codec_util.vala
    src/device.vala
    src/module.vala
    src/plugin.vala
    src/stream.vala
    src/video_widget.vala
    src/register_plugin.vala
    ${RTP_VOICE_PROCESSOR_VALA}
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/crypto-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${RTP_PACKAGES}
DEFINITIONS
    ${RTP_DEFINITIONS}
OPTIONS
    ${RTP_EXTRA_OPTIONS}
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="rtp" -I${CMAKE_CURRENT_SOURCE_DIR}/src ${RTP_VOICE_PROCESSOR_CFLAGS})
add_library(rtp SHARED ${RTP_VALA_C} ${RTP_VOICE_PROCESSOR_CXX} src/gst_fixes.c)
target_link_libraries(rtp libdino crypto-vala ${RTP_PACKAGES} gstreamer-rtp-1.0 ${RTP_VOICE_PROCESSOR_LIB})
set_target_properties(rtp PROPERTIES PREFIX "")
set_target_properties(rtp PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS rtp ${PLUGIN_INSTALL})
