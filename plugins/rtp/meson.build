dependencies = [
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gnutls,
    dep_gtk4,
    dep_gstreamer,
    dep_gstreamer_app,
    dep_gstreamer_audio,
    dep_gstreamer_rtp,
    dep_gstreamer_video,
    dep_crypto_vala,
    dep_dino,
    dep_qlite,
    dep_webrtc_audio_processing,
    dep_xmpp_vala,
]
sources = files(
    'src/codec_util.vala',
    'src/device.vala',
    'src/gst_fixes.c',
    'src/module.vala',
    'src/plugin.vala',
    'src/register_plugin.vala',
    'src/stream.vala',
    'src/video_widget.vala',
    'src/voice_processor.vala',
    'src/voice_processor_native.cpp',
)
c_args = [
    '-DGST_1_16',
    '-DGST_1_18',
    '-DGST_1_20',
    '-DWITH_VOICE_PROCESSOR',
    '-DG_LOG_DOMAIN="rtp"',
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
lib_rtp = shared_library('rtp', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_rtp = declare_dependency(link_with: lib_rtp, include_directories: include_directories('.'))
