#include <gst/video/video.h>

GstVideoInfo *gst_video_frame_get_video_info(GstVideoFrame *frame) {
    return &frame->info;
}

void *gst_video_frame_get_data(GstVideoFrame *frame, size_t* length) {
    *length = frame->info.height * frame->info.stride[0];
    return frame->data[0];
}