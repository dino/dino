find_package(GstRtp REQUIRED)
find_package(WebRTCAudioProcessing 0.2)
find_packages(RTP_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GnuTLS
    GObject
    GTK3
    Gst
    GstApp
    GstAudio
)

if(Gst_VERSION VERSION_GREATER "1.16")
    set(RTP_DEFINITIONS GST_1_16)
endif()

if(WebRTCAudioProcessing_VERSION GREATER "0.4")
    message(STATUS "Ignoring WebRTCAudioProcessing, only versions < 0.4 supported so far")
    unset(WebRTCAudioProcessing_FOUND)
endif()

if(WebRTCAudioProcessing_FOUND)
    set(RTP_DEFINITIONS ${RTP_DEFINITIONS} WITH_VOICE_PROCESSOR)
    set(RTP_VOICE_PROCESSOR_VALA src/voice_processor.vala)
    set(RTP_VOICE_PROCESSOR_CXX src/voice_processor_native.cpp)
    set(RTP_VOICE_PROCESSOR_LIB webrtc-audio-processing)
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
    ${CMAKE_CURRENT_SOURCE_DIR}/vapi/gstreamer-rtp-1.0.vapi
PACKAGES
    ${RTP_PACKAGES}
DEFINITIONS
    ${RTP_DEFINITIONS}
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="rtp" -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_library(rtp SHARED ${RTP_VALA_C} ${RTP_VOICE_PROCESSOR_CXX})
target_link_libraries(rtp libdino crypto-vala ${RTP_PACKAGES} gstreamer-rtp-1.0 ${RTP_VOICE_PROCESSOR_LIB})
set_target_properties(rtp PROPERTIES PREFIX "")
set_target_properties(rtp PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS rtp ${PLUGIN_INSTALL})
