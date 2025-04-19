#include <algorithm>
#include <gst/gst.h>
#include <gst/audio/audio.h>
#if defined(WEBRTC0)
#include <webrtc/modules/audio_processing/include/audio_processing.h>
#include <webrtc/modules/interface/module_common_types.h>
#include <webrtc/system_wrappers/include/trace.h>
#elif defined(WEBRTC1) || defined(WEBRTC2)
#include <modules/audio_processing/include/audio_processing.h>
#else
#error "Need to define WEBRTC0, WEBRTC1 or WEBRTC2"
#endif

#define SAMPLE_RATE 48000
#define SAMPLE_CHANNELS 1

struct _DinoPluginsRtpVoiceProcessorNative {
#if defined(WEBRTC0)
    webrtc::AudioProcessing *apm;
#elif defined(WEBRTC1) || defined(WEBRTC2)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm;
#endif
    gint stream_delay = 0;
    gint last_median = 0;
    gint last_poor_delays = 0;
};

extern "C" void *dino_plugins_rtp_adjust_to_running_time(GstBaseTransform *transform, GstBuffer *buffer) {
    GstBuffer *copy = gst_buffer_copy(buffer);
    GST_BUFFER_PTS(copy) = gst_segment_to_running_time(&transform->segment, GST_FORMAT_TIME, GST_BUFFER_PTS(buffer));
    return copy;
}

extern "C" void *dino_plugins_rtp_voice_processor_init_native(gint stream_delay) {
    auto *native = new _DinoPluginsRtpVoiceProcessorNative();
    native->stream_delay = stream_delay;
#if defined(WEBRTC0)
    webrtc::Config config;
    config.Set<webrtc::ExtendedFilter>(new webrtc::ExtendedFilter(true));
    config.Set<webrtc::ExperimentalAgc>(new webrtc::ExperimentalAgc(true, 85));
    native->apm = webrtc::AudioProcessing::Create(config);

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
#elif defined(WEBRTC1) || defined(WEBRTC2)
    webrtc::AudioProcessing::Config config;
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = webrtc::AudioProcessingBuilder().Create();
    native->apm = apm;
    config.high_pass_filter.enabled = true;
    config.echo_canceller.enabled = true;
    config.noise_suppression.level = webrtc::AudioProcessing::Config::NoiseSuppression::Level::kModerate;
    config.noise_suppression.enabled = true;
    config.gain_controller1.target_level_dbfs = 3;
    config.gain_controller1.compression_gain_db = 9;
    config.gain_controller1.enable_limiter = true;
    config.gain_controller1.enabled = true;
#ifdef WEBRTC1
    config.level_estimation.enabled = true;
    config.voice_detection.enabled = true;
#endif
    apm->ApplyConfig(config);
#endif
    return native;
}

extern "C" void
dino_plugins_rtp_voice_processor_analyze_reverse_stream(void *native_ptr, GstAudioInfo *info, GstBuffer *buffer) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    int err;

#if defined(WEBRTC0)
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    webrtc::AudioProcessing *apm = native->apm;
    GstMapInfo map;
    gst_buffer_map(buffer, &map, GST_MAP_READ);

    webrtc::AudioFrame frame;
    frame.num_channels_ = info->channels;
    frame.sample_rate_hz_ = info->rate;
    frame.samples_per_channel_ = gst_buffer_get_size(buffer) / info->bpf;
    memcpy(frame.data_, map.data, frame.samples_per_channel_ * info->bpf);

    apm->set_stream_delay_ms (native->stream_delay);
    err = apm->AnalyzeReverseStream(&frame);

    gst_buffer_unmap(buffer, &map);
#elif defined(WEBRTC1) || defined(WEBRTC2)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = native->apm;
#ifdef WEBRTC1
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS, false);
#else
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS);
#endif
    GstAudioBuffer abuf;
    if (!gst_audio_buffer_map (&abuf, info, buffer, GST_MAP_READWRITE)) {
        g_warning("voice_processor_native.cpp: analyze_reverse_stream: gst_audio_buffer_map failed");
        return;
    }

    apm->set_stream_delay_ms (native->stream_delay);
    auto * const data = (int16_t * const) abuf.planes[0];
    err = apm->ProcessReverseStream (data, config, config, data);

    gst_audio_buffer_unmap (&abuf);
#endif
    if (err < 0) g_warning("voice_processor_native.cpp: ProcessReverseStream %i", err);
}

extern "C" void dino_plugins_rtp_voice_processor_notify_gain_level(void *native_ptr, gint gain_level) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
#if defined(WEBRTC0)
    webrtc::AudioProcessing *apm = native->apm;
    apm->gain_control()->set_stream_analog_level(gain_level);
#elif defined(WEBRTC1) || defined(WEBRTC2)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = native->apm;
    apm->set_stream_analog_level(gain_level);
#endif
}

extern "C" gint dino_plugins_rtp_voice_processor_get_suggested_gain_level(void *native_ptr) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    int level = 0;
#if defined(WEBRTC0)
    webrtc::AudioProcessing *apm = native->apm;
    level = apm->gain_control()->stream_analog_level();
#elif defined(WEBRTC1) || defined(WEBRTC2)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = native->apm;
    level = apm->recommended_stream_analog_level();
#endif
    return level;
}

extern "C" bool dino_plugins_rtp_voice_processor_get_stream_has_voice(void *native_ptr) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    bool has_voice = false;
#if defined(WEBRTC0)
    webrtc::AudioProcessing *apm = native->apm;
    has_voice = apm->voice_detection()->stream_has_voice();
#elif defined(WEBRTC1)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = native->apm;
    webrtc::AudioProcessingStats stats = apm->GetStatistics ();
    has_voice = stats.voice_detected.value_or(false);
#endif
    return has_voice;
}

extern "C" void dino_plugins_rtp_voice_processor_set_stream_delay(void *native_ptr, gint stream_delay) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    native->stream_delay = stream_delay;
}

extern "C" void dino_plugins_rtp_voice_processor_adjust_stream_delay(void *native_ptr) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    int median, std, poor_delays;
    float fraction_poor_delays;
#if defined(WEBRTC0)
    webrtc::AudioProcessing *apm = native->apm;
    apm->echo_cancellation()->GetDelayMetrics(&median, &std, &fraction_poor_delays);
    poor_delays = (int)(fraction_poor_delays * 100.0);
#elif defined(WEBRTC1) || defined(WEBRTC2)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = native->apm;
    webrtc::AudioProcessingStats stats = apm->GetStatistics();
    median = stats.delay_median_ms.value_or(-1);
    std = stats.delay_standard_deviation_ms.value_or(-1);
    fraction_poor_delays = (float) stats.divergent_filter_fraction.value_or(-1.0);
    poor_delays = (int) (fraction_poor_delays * 100.0);
#endif
    if (fraction_poor_delays < 0 || (native->last_median == median && native->last_poor_delays == poor_delays)) return;
    g_debug("voice_processor_native.cpp: Stream delay metrics: median=%i std=%i poor_delays=%i%%", median, std, poor_delays);
    native->last_median = median;
    native->last_poor_delays = poor_delays;
#if defined(WEBRTC0)
    if (poor_delays > 90) {
        native->stream_delay = std::min(std::max(0, native->stream_delay + std::min(48, std::max(median, -48))), 384);
        g_debug("voice_processor_native.cpp: set stream_delay=%i", native->stream_delay);
    }
#endif
}

extern "C" void
dino_plugins_rtp_voice_processor_process_stream(void *native_ptr, GstAudioInfo *info, GstBuffer *buffer) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
    int err;

#if defined(WEBRTC0)
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS, false);
    webrtc::AudioProcessing *apm = native->apm;
    GstMapInfo map;
    gst_buffer_map(buffer, &map, GST_MAP_READWRITE);

    webrtc::AudioFrame frame;
    frame.num_channels_ = info->channels;
    frame.sample_rate_hz_ = info->rate;
    frame.samples_per_channel_ = info->rate / 100;
    memcpy(frame.data_, map.data, frame.samples_per_channel_ * info->bpf);

    apm->set_stream_delay_ms(native->stream_delay);
    err = apm->ProcessStream(&frame);
    if (err >= 0) memcpy(map.data, frame.data_, frame.samples_per_channel_ * info->bpf);

    gst_buffer_unmap(buffer, &map);
#elif defined(WEBRTC1) || defined(WEBRTC2)
    rtc::scoped_refptr<webrtc::AudioProcessing> apm = native->apm;
#ifdef WEBRTC1
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS, false);
#else
    webrtc::StreamConfig config(SAMPLE_RATE, SAMPLE_CHANNELS);
#endif
    GstAudioBuffer abuf;
    if (!gst_audio_buffer_map (&abuf, info, buffer, GST_MAP_READWRITE)) {
        g_warning("voice_processor_native.cpp: process_stream: gst_audio_buffer_map failed");
        return;
    }

    auto * const data = (int16_t * const) abuf.planes[0];
    err = apm->ProcessStream (data, config, config, data);

    gst_audio_buffer_unmap (&abuf);
#endif
    if (err < 0) g_warning("voice_processor_native.cpp: ProcessStream %i", err);
}

extern "C" void dino_plugins_rtp_voice_processor_destroy_native(void *native_ptr) {
    auto *native = (_DinoPluginsRtpVoiceProcessorNative *) native_ptr;
#if defined(WEBRTC0)
    delete native->apm;
    native->apm = NULL;
#elif defined(WEBRTC1) || defined(WEBRTC2)
    native->apm = nullptr;
#endif
    delete native;
}