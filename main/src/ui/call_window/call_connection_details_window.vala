using Gtk;

namespace Dino.Ui {

    public class CallConnectionDetailsWindow : Gtk.Window {

        public Box box = new Box(Orientation.VERTICAL, 15) { halign=Align.CENTER, valign=Align.CENTER };

        private bool video_added = false;
        private CallContentDetails audio_details = new CallContentDetails("Audio");
        private CallContentDetails video_details = new CallContentDetails("Video");

        public CallConnectionDetailsWindow() {
            box.append(audio_details);
            box.append(video_details);
            set_child(box);
        }

        public void update_content(PeerInfo peer_info) {
            if (peer_info.audio != null) {
                audio_details.update_content(peer_info.audio);
            }
            if (peer_info.video != null) {
                add_video_widgets();
                video_details.update_content(peer_info.video);
            }
        }

        private void add_video_widgets() {
            if (video_added) return;

            video_details.visible = true;
            video_added = true;
        }
    }

    public class CallContentDetails : Gtk.Grid {

        public Label rtp_title = new Label("RTP") { xalign=0 };
        public Label rtcp_title = new Label("RTCP") { xalign=0 };
        public Label target_recv_title = new Label("Target receive bitrate") { xalign=0 };
        public Label target_send_title = new Label("Target send bitrate") { xalign=0 };

        public Label rtp_ready = new Label("?") { xalign=0 };
        public Label rtcp_ready = new Label("?") { xalign=0 };
        public Label sent_bps = new Label("?") { use_markup=true, xalign=0 };
        public Label recv_bps = new Label("?") { use_markup=true, xalign=0 };
        public Label codec = new Label("?") { xalign=0 };
        public Label target_receive_bitrate = new Label("n/a") { use_markup=true, xalign=0 };
        public Label target_send_bitrate = new Label("n/a") { use_markup=true, xalign=0 };

        private PeerContentInfo? prev_info = null;
        private int row_at = 0;

        public CallContentDetails(string headline) {
            attach(new Label("<b>%s</b>".printf(headline)) { use_markup=true, xalign=0 }, 0, row_at++, 1, 1);
            attach(rtp_title, 0, row_at, 1, 1);
            attach(rtp_ready, 1, row_at++, 1, 1);
            attach(rtcp_title, 0, row_at, 1, 1);
            attach(rtcp_ready, 1, row_at++, 1, 1);
            put_row("Sent");
            attach(sent_bps, 1, row_at++, 1, 1);
            put_row("Received");
            attach(recv_bps, 1, row_at++, 1, 1);
            put_row("Codec");
            attach(codec, 1, row_at++, 1, 1);
            attach(target_recv_title, 0, row_at, 1, 1);
            attach(target_receive_bitrate, 1, row_at++, 1, 1);
            attach(target_send_title, 0, row_at, 1, 1);
            attach(target_send_bitrate, 1, row_at++, 1, 1);

            this.column_spacing = 5;
        }

        public void update_content(PeerContentInfo info) {
            if (!info.rtp_ready) {
                rtp_ready.visible = rtcp_ready.visible = true;
                rtp_title.visible = rtcp_title.visible = true;
                rtp_ready.label = info.rtp_ready.to_string();
                rtcp_ready.label = info.rtcp_ready.to_string();
            } else {
                rtp_ready.visible = rtcp_ready.visible = false;
                rtp_title.visible = rtcp_title.visible = false;
            }
            if (info.target_send_bytes != -1) {
                target_receive_bitrate.visible = target_send_bitrate.visible = true;
                target_recv_title.visible = target_send_title.visible = true;
                target_receive_bitrate.label = "<span font_family='monospace'>%u</span> kbps".printf(info.target_receive_bytes);
                target_send_bitrate.label = "<span font_family='monospace'>%u</span> kbps".printf(info.target_send_bytes);
            } else {
                target_receive_bitrate.visible = target_send_bitrate.visible = false;
                target_recv_title.visible = target_send_title.visible = false;
            }

            codec.label = info.codec + " " + info.clockrate.to_string();

            if (prev_info != null) {
                ulong audio_sent_kbps = (info.bytes_sent - prev_info.bytes_sent) * 8 / 1000;
                sent_bps.label = "<span font_family='monospace'>%lu</span> kbps".printf(audio_sent_kbps);
                ulong audio_recv_kbps = (info.bytes_received - prev_info.bytes_received) * 8 / 1000;
                recv_bps.label = "<span font_family='monospace'>%lu</span> kbps".printf(audio_recv_kbps);
            }
            prev_info = info;
        }

        private void put_row(string label) {
            attach(new Label(label) { xalign=0 }, 0, row_at, 1, 1);
        }
    }
}

