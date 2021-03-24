find_packages(RTP_PACKAGES REQUIRED
    Gee
    GLib
    GModule
    GnuTLS
    GObject
    GTK3
    Gst
    GstApp
)

vala_precompile(RTP_VALA_C
SOURCES
    src/codec_util.vala
    src/device.vala
    src/module.vala
    src/plugin.vala
    src/stream.vala
    src/video_widget.vala
    src/register_plugin.vala
CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/exports/crypto.vapi
    ${CMAKE_BINARY_DIR}/exports/xmpp-vala.vapi
    ${CMAKE_BINARY_DIR}/exports/dino.vapi
    ${CMAKE_BINARY_DIR}/exports/qlite.vapi
PACKAGES
    ${RTP_PACKAGES}
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_definitions(${VALA_CFLAGS} -DG_LOG_DOMAIN="rtp" -I${CMAKE_CURRENT_SOURCE_DIR}/src)
add_library(rtp SHARED ${RTP_VALA_C})
target_link_libraries(rtp libdino crypto-vala ${RTP_PACKAGES})
set_target_properties(rtp PROPERTIES PREFIX "")
set_target_properties(rtp PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/plugins/)

install(TARGETS rtp ${PLUGIN_INSTALL})
