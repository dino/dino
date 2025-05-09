using Gee;
using Gdk;
using Gtk;
using Xmpp;

using Dino.Entities;

namespace Dino.Ui {

    public class FileTransmissionProgress : Adw.Bin {

        public enum State {
            UNKNOWN_SOURCE,
            DOWNLOAD_NOT_STARTED,
            DOWNLOAD_NOT_STARTED_FAILED_BEFORE,
            DOWNLOADING,
            UPLOADING,
            UPLOAD_FAILED
        }

        public int64 file_size { get; set; }
        public int64 transferred_size { get; set; }
        public State state { get; set; }

        private const int LINE_WIDTH = 4;

        private Button button = new Button();

        private Adw.TimedAnimation progress_animation;

        construct {
            add_css_class("circular-osd");
            button.add_css_class("circular");
            button.margin_start = button.margin_end = button.margin_top = button.margin_bottom = LINE_WIDTH;
            this.set_child(button);

            this.button.clicked.connect(on_button_clicked);

            this.notify["transferred-size"].connect(update_progress);
            this.notify["state"].connect(on_state_changed);
            on_state_changed();

            setup_animation();
        }

        private void setup_animation() {
            progress_animation = new Adw.TimedAnimation(this, 0.0, 0.0, 250, new Adw.CallbackAnimationTarget(queue_draw)) { easing = Adw.Easing.LINEAR };
            progress_animation.done.connect(update_progress);
        }

        private void on_state_changed() {
            sensitive = state != UNKNOWN_SOURCE && state != UPLOAD_FAILED;

            switch (this.state) {
                case UNKNOWN_SOURCE:
                case DOWNLOAD_NOT_STARTED:
                    button.icon_name = "document-save-symbolic";
                    break;
                case DOWNLOADING:
                case UPLOADING:
                    button.icon_name = "small-x-symbolic";
                    break;
                case DOWNLOAD_NOT_STARTED_FAILED_BEFORE:
                case UPLOAD_FAILED:
                    button.icon_name = "dialog-warning-symbolic";
                    break;
            }
        }

        private void update_progress() {
            if (file_size == 0 || progress_animation == null) return;
            // For encrypted files, transferred size > file size. For PGP, the whole message is encrypted at once, making a better solution difficult.
            double next_value = ((double)transferred_size / (double)file_size).clamp(0, 1);
            if (progress_animation != null && progress_animation.value_to != next_value) {
                progress_animation.value_from = progress_animation.value;
                progress_animation.value_to = next_value;
                progress_animation.reset();
                progress_animation.play();
            }
        }

#if GTK_4_14
        private static extern Gsk.Path create_progress_arc(Gsk.Path circle, float percentage);
#endif

        public override void snapshot(Gtk.Snapshot snapshot) {
            base.snapshot(snapshot);

            if ((state == State.DOWNLOADING || state == State.UPLOADING) && progress_animation.value > 0.01) {

                float radius = float.max(int.min(get_width(), get_height()) / 2, 1);
                float line_width = (float) LINE_WIDTH;

                snapshot.translate({get_width() / 2, get_height() / 2});
#if GTK_4_14
                var fg_color = get_color();
                get_style_context().lookup_color("accent_color", out fg_color);
                var builder = new Gsk.PathBuilder();
                builder.add_circle({0, 0}, radius - line_width / 2);
                var circle_path = builder.to_path();
                var stroke = new Gsk.Stroke(line_width);
                stroke.set_line_cap(Gsk.LineCap.ROUND);
                var arc_path = create_progress_arc(circle_path, (float) progress_animation.value);
                snapshot.append_stroke(arc_path, stroke, fg_color);
#else
                var fg_color = get_style_context().get_color();
                get_style_context().lookup_color("accent_color", out fg_color);
                var context = snapshot.append_cairo({{-radius, -radius}, {radius*2, radius*2}});
                context.set_line_cap(Cairo.LineCap.ROUND);
                context.set_line_width(line_width);
                context.set_source_rgba(fg_color.red, fg_color.green, fg_color.blue, fg_color.alpha);
                context.arc(0, 0, radius - line_width / 2, -0.5 * Math.PI, (progress_animation.value - 0.25) * 2 * Math.PI);
                context.stroke();
#endif
            }
        }

        private void on_button_clicked() {
            switch (this.state) {
                case UNKNOWN_SOURCE:
                case UPLOAD_FAILED:
                    break;
                case DOWNLOAD_NOT_STARTED_FAILED_BEFORE:
                case DOWNLOAD_NOT_STARTED:
                    this.activate_action("file.download", null);
                    break;
                case DOWNLOADING:
                case UPLOADING:
                    this.activate_action("file.cancel", null);
                    break;
            }
        }

        public override void dispose() {
            progress_animation = null;
            base.dispose();
        }
    }
}
