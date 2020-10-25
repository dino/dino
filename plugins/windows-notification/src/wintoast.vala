namespace Dino.Plugins.WindowsNotification {
    public class WinToast {
        [CCode (has_target = true)]
        public delegate void NotificationCallback(int conv_id);

        [CCode (cname = "dinoWinToastLibInit", cheader_filename = "DinoWinToastLib.h")]
        private static extern int DinoWinToastLibInit();

        [CCode (cname = "dinoWinToastLibShowMessage", cheader_filename = "DinoWinToastLib.h")]
        private static extern int DinoWinToastLibShowMessage(char* sender, char* message, char* image_path, int conv_id, NotificationCallback callback);

        public bool valid { get; private set; }

        public WinToast() {
            valid = DinoWinToastLibInit() == 0;
        }

        public bool show_message(string sender, string message, string? image_path, int conv_id, NotificationCallback callback) {
            if (valid) {
                return DinoWinToastLibShowMessage(sender, message, image_path, conv_id, callback) == 0;
            }
            return false;
        }
    }
}