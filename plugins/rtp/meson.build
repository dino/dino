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
vala_args = []
if dep_webrtc_audio_processing.found() and get_option('plugin-rtp-webrtc-audio-processing').allowed()
    voice_dependencies = [
        dep_gstreamer_audio,
        dep_webrtc_audio_processing,
    ]
    voice_sources = files(
        'src/voice_processor_native.cpp',
    )
    voice_c_args = c_args
    if dep_webrtc_audio_processing.version().version_compare('>=2.0')
        voice_c_args += ['-DWEBRTC2']
    elif dep_webrtc_audio_processing.version().version_compare('>=1.0')
        voice_c_args += ['-DWEBRTC1']
    else
        voice_c_args += ['-DWEBRTC0']
    endif
    lib_rtp_voice_processor = static_library('rtp-voice-processor', voice_sources, c_args: voice_c_args, cpp_args: voice_c_args, dependencies: voice_dependencies, install: false)
    dep_rtp_voice_processor = declare_dependency(link_with: lib_rtp_voice_processor)
    vala_args += ['-D', 'WITH_VOICE_PROCESSOR']
    dependencies += [dep_rtp_voice_processor]
    sources += files(
        'src/voice_processor.vala',
    )
elif get_option('plugin-rtp-webrtc-audio-processing').enabled()
    error('No compatible webrtc-audio-processing found, but plugin-rtp-webrtc-audio-processing option set.')
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
if meson.get_compiler('vala').version().version_compare('<0.56.1')
    vala_args += ['--vapidir', meson.current_source_dir() / 'vapi']
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

lib_rtp = shared_library('rtp', sources, name_prefix: '', c_args: c_args, vala_args: vala_args, include_directories: include_directories('src'), dependencies: dependencies, install: true, install_dir: get_option('libdir') / 'dino/plugins')
dep_rtp = declare_dependency(link_with: lib_rtp, include_directories: include_directories('.'))
summary('Voice/video calls (rtp)', dep_rtp, section: 'Plugins')

if dep_rtp.found()
    summary('H264 codec', get_option('plugin-rtp-h264').allowed(), section: 'RTP configuration')
    summary('VP9 codec', get_option('plugin-rtp-vp9').allowed(), section: 'RTP configuration')
    summary('Intel MediaSDK', get_option('plugin-rtp-msdk').allowed(), section: 'RTP configuration')
    summary('Video Acceleration API', get_option('plugin-rtp-vaapi').allowed(), section: 'RTP configuration')
    summary('Voice preprocessing', dep_webrtc_audio_processing.found(), section: 'RTP configuration')
endif
