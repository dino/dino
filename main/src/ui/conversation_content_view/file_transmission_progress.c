#include <gsk/gsk.h>

GskPath *dino_ui_file_transmission_progress_create_progress_arc(GskPath *circle_path, gfloat percentage) {
    GskPathMeasure *measure = gsk_path_measure_new(circle_path);
    gfloat length = gsk_path_measure_get_length(measure);
    GskPathPoint start_point, end_point;
    g_return_val_if_fail(gsk_path_measure_get_point(measure, length * 0.75, &start_point), NULL);
    percentage += 0.75f;
    if (percentage > 1) percentage -= 1.0f;
    g_return_val_if_fail(gsk_path_measure_get_point(measure, length * percentage, &end_point), NULL);
    GskPathBuilder *builder = gsk_path_builder_new();
    gsk_path_builder_add_segment(builder, circle_path, &start_point, &end_point);
    GskPath *arc_path = gsk_path_builder_free_to_path(builder);
    gsk_path_measure_unref(measure);
    return arc_path;
}