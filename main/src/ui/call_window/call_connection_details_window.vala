using Gtk;

namespace Dino.Ui {

    public class CallConnectionDetailsWindow : Gtk.Window {

        public Grid grid = new Grid() { column_spacing=5, margin=10, halign=Align.CENTER, valign=Align.CENTER, visible=true };

        public Label audio_rtp_ready = new Label("?") { xalign=0, visible=true };
        public Label audio_rtcp_ready = new Label("?") { xalign=0, visible=true };
        public Label audio_sent_bps = new Label("?") { xalign=0, visible=true };
        public Label audio_recv_bps = new Label("?") { xalign=0, visible=true };
        public Label audio_codec = new Label("?") { xalign=0, visible=true };

        public Label video_rtp_ready = new Label("") { xalign=0, visible=true };
        public Label video_rtcp_ready = new Label("") { xalign=0, visible=true };
        public Label video_sent_bps = new Label("") { xalign=0, visible=true };
        public Label video_recv_bps = new Label("") { xalign=0, visible=true };
        public Label video_codec = new Label("") { xalign=0, visible=true };

        private int row_at = 0;
        private bool video_added = false;
        private PeerInfo? prev_peer_info = null;

        public CallConnectionDetailsWindow() {
                grid.attach(new Label("<b>Audio</b>") { use_markup=true, xalign=0, visible=true }, 0, row_at++, 1, 1);
                put_row("RTP");
                grid.attach(audio_rtp_ready, 1, row_at++, 1, 1);
                put_row("RTCP");
                grid.attach(audio_rtcp_ready, 1, row_at++, 1, 1);
                put_row("Sent bp/s");
                grid.attach(audio_sent_bps, 1, row_at++, 1, 1);
                put_row("Received bp/s");
                grid.attach(audio_recv_bps, 1, row_at++, 1, 1);
                put_row("Codec");
                grid.attach(audio_codec, 1, row_at++, 1, 1);

                this.child = grid;
        }

        private void put_row(string label) {
            grid.attach(new Label(label) { xalign=0, visible=true }, 0, row_at, 1, 1);
        }

        public void update_content(PeerInfo peer_info) {
                audio_rtp_ready.label = peer_info.audio_rtp_ready.to_string();
                audio_rtcp_ready.label = peer_info.audio_rtcp_ready.to_string();
                audio_codec.label = peer_info.audio_codec + " " + peer_info.audio_clockrate.to_string();

                video_rtp_ready.label = peer_info.video_rtp_ready.to_string();
                video_rtcp_ready.label = peer_info.video_rtcp_ready.to_string();
                video_codec.label = peer_info.video_codec;

                if (peer_info.video_content_exists) add_video_widgets();

                if (prev_peer_info != null) {
                        audio_sent_bps.label = (peer_info.audio_bytes_sent - prev_peer_info.audio_bytes_sent).to_string();
                        audio_recv_bps.label = (peer_info.audio_bytes_received - prev_peer_info.audio_bytes_received).to_string();
                        video_sent_bps.label = (peer_info.video_bytes_sent - prev_peer_info.video_bytes_sent).to_string();
                        video_recv_bps.label = (peer_info.video_bytes_received - prev_peer_info.video_bytes_received).to_string();
                }
                prev_peer_info = peer_info;
        }

        private void add_video_widgets() {
                if (video_added) return;

                grid.attach(new Label("<b>Video</b>") { use_markup=true, xalign=0, visible=true }, 0, row_at++, 1, 1);
                put_row("RTP");
                grid.attach(video_rtp_ready, 1, row_at++, 1, 1);
                put_row("RTCP");
                grid.attach(video_rtcp_ready, 1, row_at++, 1, 1);
                put_row("Sent bp/s");
                grid.attach(video_sent_bps, 1, row_at++, 1, 1);
                put_row("Received bp/s");
                grid.attach(video_recv_bps, 1, row_at++, 1, 1);
                put_row("Codec");
                grid.attach(video_codec, 1, row_at++, 1, 1);

                video_added = true;
        }
    }
}

