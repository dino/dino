#include <algorithm>
#include <gst/gst.h>
#include <gst/audio/audio.h>
#include <webrtc/modules/audio_processing/include/audio_processing.h>
#include <webrtc/modules/interface/module_common_types.h>
#include <webrtc/system_wrappers/include/trace.h>

#define SAMPLE_RATE 48000
#define SAMPLE_CHANNELS 1

struct _DinoPluginsRtpVoiceProcessorNative {
    webrtc::AudioProcessing *apm;
    gint stream_delay;
};

extern "C" void *dino_plugins_rtp_adjust_to_running_time(GstBaseTransform *transform, GstBuffer *buffer) {
    GstBuffer *copy = gst_buffer_copy(buffer);
    GST_BUFFER_PTS(copy) = gst_segment_to_running_time(&transform->segment, GST_FORMAT_TIME, GST_BUFFER_PTS(buffer));
    return copy;
}

extern "C" void *dino_plugins_rtp_voice_processor_init_native(gint stream_delay) {
    _DinoPluginsRtpVoiceProcessorNative *native = new _DinoPluginsRtpVoiceProcessorNative();
    webrtc::Config config;
    config.Set<webrtc::ExtendedFilter>(new webrtc::ExtendedFilter(true));
    config.Set<webrtc::ExperimentalAgc>(new webrtc::ExperimentalAgc(true, 85));
    native->apm = webrtc::AudioProcessing::Create(config);
    native->stream_delay = stream_delay;
    return native;
}

extern "C" void dino_plugins_rtp_voice_processor_setup_native(void *native_ptr) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::AudioProcessing *apm = native->apm;
    webrtc::ProcessingConfig pconfig;
    pconfig.streams[webrtc::ProcessingConfig::kInputStream] =
            webrtc::StreamConfig(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    pconfig.streams[webrtc::ProcessingConfig::kOutputStream] =
            webrtc::StreamConfig(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    pconfig.streams[webrtc::ProcessingConfig::kReverseInputStream] =
            webrtc::StreamConfig(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    pconfig.streams[webrtc::ProcessingConfig::kReverseOutputStream] =
            webrtc::StreamConfig(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    apm->Initialize(pconfig);
    apm->high_pass_filter()->Enable(true);
    apm->echo_cancellation()->enable_drift_compensation(false);
    apm->echo_cancellation()->set_suppression_level(webrtc::EchoCancellation::kModerateSuppression);
    apm->echo_cancellation()->enable_delay_logging(true);
    apm->echo_cancellation()->Enable(true);
    apm->noise_suppression()->set_level(webrtc::NoiseSuppression::kModerate);
    apm->noise_suppression()->Enable(true);
    apm->gain_control()->set_analog_level_limits(0, 255);
    apm->gain_control()->set_mode(webrtc::GainControl::kAdaptiveAnalog);
    apm->gain_control()->set_target_level_dbfs(3);
    apm->gain_control()->set_compression_gain_db(9);
    apm->gain_control()->enable_limiter(true);
    apm->gain_control()->Enable(true);
    apm->voice_detection()->set_likelihood(webrtc::VoiceDetection::Likelihood::kLowLikelihood);
    apm->voice_detection()->Enable(true);
}

extern "C" void
dino_plugins_rtp_voice_processor_analyze_reverse_stream(void *native_ptr, GstAudioInfo *info, GstBuffer *buffer) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    webrtc::AudioProcessing *apm = native->apm;

    GstAudioBuffer audio_buffer;
    gst_audio_buffer_map(&audio_buffer, info, buffer, GST_MAP_READ);

    webrtc::AudioFrame frame;
    frame.num_channels_ = info->channels;
    frame.sample_rate_hz_ = info->rate;
    frame.samples_per_channel_ = gst_buffer_get_size(buffer) / info->bpf;
    memcpy(frame.data_, audio_buffer.planes[0], frame.samples_per_channel_ * info->bpf);

    int err = apm->AnalyzeReverseStream(&frame);
    if (err < 0) g_warning("ProcessReverseStream %i", err);

    gst_audio_buffer_unmap(&audio_buffer);
}

extern "C" void dino_plugins_rtp_voice_processor_notify_gain_level(void *native_ptr, gint gain_level) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::AudioProcessing *apm = native->apm;
    apm->gain_control()->set_stream_analog_level(gain_level);
}

extern "C" gint dino_plugins_rtp_voice_processor_get_suggested_gain_level(void *native_ptr) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::AudioProcessing *apm = native->apm;
    return apm->gain_control()->stream_analog_level();
}

extern "C" bool dino_plugins_rtp_voice_processor_get_stream_has_voice(void *native_ptr) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::AudioProcessing *apm = native->apm;
    return apm->voice_detection()->stream_has_voice();
}

extern "C" void dino_plugins_rtp_voice_processor_adjust_stream_delay(void *native_ptr) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::AudioProcessing *apm = native->apm;
    int median, std;
    float fraction_poor_delays;
    apm->echo_cancellation()->GetDelayMetrics(&median, &std, &fraction_poor_delays);
    if (fraction_poor_delays < 0) return;
    g_debug("voice_processor_native.cpp: Stream delay metrics: %i %i %f", median, std, fraction_poor_delays);
    if (fraction_poor_delays > 0.5) {
        native->stream_delay = std::max(0, native->stream_delay + std::min(-10, std::max(median, 10)));
        g_debug("Adjusted stream delay %i", native->stream_delay);
    }
}

extern "C" void
dino_plugins_rtp_voice_processor_process_stream(void *native_ptr, GstAudioInfo *info, GstBuffer *buffer) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    webrtc::AudioProcessing *apm = native->apm;

    GstAudioBuffer audio_buffer;
    gst_audio_buffer_map(&audio_buffer, info, buffer, GST_MAP_READWRITE);

    webrtc::AudioFrame frame;
    frame.num_channels_ = info->channels;
    frame.sample_rate_hz_ = info->rate;
    frame.samples_per_channel_ = info->rate / 100;
    memcpy(frame.data_, audio_buffer.planes[0], frame.samples_per_channel_ * info->bpf);

    apm->set_stream_delay_ms(native->stream_delay);
    int err = apm->ProcessStream(&frame);
    if (err >= 0) memcpy(audio_buffer.planes[0], frame.data_, frame.samples_per_channel_ * info->bpf);
    if (err < 0) g_warning("ProcessStream %i", err);

    gst_audio_buffer_unmap(&audio_buffer);
}

extern "C" void dino_plugins_rtp_voice_processor_destroy_native(void *native_ptr) {
    _DinoPluginsRtpVoiceProcessorNative *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    delete native;
}