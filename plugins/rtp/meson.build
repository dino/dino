dependencies = [
    dep_crypto_vala,
    dep_dino,
    dep_gee,
    dep_glib,
    dep_gmodule,
    dep_gstreamer,
    dep_gstreamer_app,
    dep_gstreamer_audio,
    dep_gstreamer_rtp,
    dep_gstreamer_video,
    dep_gtk4,
    dep_m,
    dep_qlite,
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
)
c_args = [
    '-DG_LOG_DOMAIN="rtp"',
]
vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
]
if dep_webrtcdsp.found()
    dependencies += [dep_webrtcdsp]
    vala_args += ['-D', 'WITH_VOICE_PROCESSOR']
endif
if dep_gstreamer_rtp.version() == 'unknown' or dep_gstreamer_rtp.version().version_compare('>=1.16')
    vala_args += ['-D', 'GST_1_16']
endif
if dep_gstreamer_rtp.version() == 'unknown' or dep_gstreamer_rtp.version().version_compare('>=1.18')
    vala_args += ['-D', 'GST_1_18']
endif
if dep_gstreamer_rtp.version() == 'unknown' or dep_gstreamer_rtp.version().version_compare('>=1.20')
    vala_args += ['-D', 'GST_1_20']
endif
if get_option('plugin-rtp-h264').allowed()
    vala_args += ['-D', 'ENABLE_H264']
endif
if get_option('plugin-rtp-msdk').allowed()
    vala_args += ['-D', 'ENABLE_MSDK']
endif
if get_option('plugin-rtp-vaapi').allowed()
    vala_args += ['-D', 'ENABLE_VAAPI']
endif
if get_option('plugin-rtp-vp9').allowed()
    vala_args += ['-D', 'ENABLE_VP9']
endif
lib_rtp = shared_library('rtp', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, kwargs: install_options)
dep_rtp = declare_dependency(link_with: lib_rtp, include_directories: include_directories('.'))
