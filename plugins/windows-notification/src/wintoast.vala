using DinoWinToast;

namespace Dino.Plugins.WindowsNotification {
    public class WinToast {
        public bool valid { get; private set; }

        public WinToast() {
            valid = Init() == 0;
        }

        public bool show_message(string sender, string message, string? image_path, int conv_id, NotificationCallback callback) {
            if (valid) {
                DinoWinToastTemplate template;
                if (image_path != null) {
                    template = new DinoWinToastTemplate(TemplateType.ImageAndText02);
                    template.setImagePath(image_path);
                } else {
                    template = new DinoWinToastTemplate(TemplateType.Text02);
                }
                
                template.setTextField(sender, TextField.FirstLine);
                template.setTextField(message, TextField.SecondLine);
                return DinoWinToast.ShowMessage(template, conv_id, callback) == 0;
            }
            return false;
        }
    }
}