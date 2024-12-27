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
            UPLOADING
        }

        public int64 file_size { get; set; }
        public int64 transferred_size { get; set; }
        public State state { get; set; }

        private CssProvider css_provider = new CssProvider();
        private Button button = new Button();

        private uint64 next_update_time = 0;
        private int64 last_progress_percent = 0;
        private uint update_progress_timeout_id = -1;

        construct {
            add_css_class("circular-loading-indicator");

            button.add_css_class("circular");
            Adw.Bin holder = new Adw.Bin();
            holder.set_child(button);
            this.set_child(holder);

            this.button.clicked.connect(on_button_clicked);

            this.notify["transferred-size"].connect(on_transferred_size_update);
            this.notify["state"].connect(on_state_changed);
            on_state_changed();
        }

        private void on_transferred_size_update() {
            if (update_progress_timeout_id == -1) {
                int64 progress_percent = transferred_size * 100 / file_size;
                if (progress_percent != last_progress_percent) {
                    uint64 time_now = get_monotonic_time() / 1000;
                    if (next_update_time > time_now) {
                        update_progress_timeout_id = Timeout.add((uint) (next_update_time - time_now), () => {
                            update_progress();
                            update_progress_timeout_id = -1;
                            return Source.REMOVE;
                        });
                    } else {
                        update_progress();
                    }
                }
            }
        }

        private void on_state_changed() {
            sensitive = state != UNKNOWN_SOURCE;

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
                    button.icon_name = "dialog-warning-symbolic";
                    break;
            }
        }

        private void update_progress() {
            this.get_style_context().remove_provider(css_provider);
            int64 progress_percent = transferred_size * 100 / file_size;

            css_provider = Util.force_css(this, @"
                .circular-loading-indicator {
                  background-image: conic-gradient(@accent_color $(progress_percent)%, transparent $(progress_percent)%);
                }
            ");

            next_update_time = get_monotonic_time() / 1000 + 500;
            last_progress_percent = progress_percent;
        }

        private void on_button_clicked() {
            switch (this.state) {
                case UNKNOWN_SOURCE:
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
            if (update_progress_timeout_id != -1) {
                Source.remove(update_progress_timeout_id);
                update_progress_timeout_id = -1;
            }
            base.dispose();
        }
    }
}
