[CCode (cheader_filename = "DinoWinToastLib.h")]
namespace DinoWinToast {

    [CCode (cname = "dinoWinToastLibNotificationCallback", has_target = true)]
    public delegate void NotificationCallback(int conv_id);

    [CCode (cname = "dinoWinToastLibInit")]
    public int Init();
    
    [CCode (cname = "dinoWinToastLibShowMessage")]
    public int ShowMessage(DinoWinToastTemplate templ, int conv_id, NotificationCallback callback);
}

