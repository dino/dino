[CCode (cheader_filename = "DinoWinToastTemplate.h")]
namespace DinoWinToast {
    [CCode (cname = "dino_wintoasttemplate_duration", cprefix = "")]
    public enum Duration {
        System,
        Short,
        Long
    }
    
    [CCode (cname = "dino_wintoasttemplate_audiooption", cprefix = "")]
    public enum AudioOption {
        Default,
        Silent,
        Loop
    }
    
    [CCode (cname = "dino_wintoasttemplate_textfield", cprefix = "")]
    public enum TextField {
        FirstLine,
        SecondLine,
        ThirdLine
    }
    
    [CCode (cname = "dino_wintoasttemplate_wintoasttemplatetype", cprefix = "")]
    public enum TemplateType {
        ImageAndText01,
        ImageAndText02,
        ImageAndText03,
        ImageAndText04,
        Text01,
        Text02,
        Text03,
        Text04,
        WinToastTemplateTypeCount
    }
    
    [CCode (cname="dino_wintoasttemplate", free_function = "dino_wintoasttemplate_destroy")]
    [Compact]
    public class DinoWinToastTemplate {
        [CCode (cname = "dino_wintoasttemplate_new")]
        public DinoWinToastTemplate(TemplateType type = TemplateType.ImageAndText02);

        [CCode (cname = "dino_wintoasttemplate_setTextField")]
        public void setTextField(char* txt, TextField pos);

        [CCode (cname = "dino_wintoasttemplate_setImagePath")]
        public void setImagePath(char* imgPath);
        
        [CCode (cname = "dino_wintoasttemplate_setAttributionText")]
        public void setAttributionText(char* attributionText);
        
        [CCode (cname = "dino_wintoasttemplate_addAction")]
        public void addAction(char* label);
        
        [CCode (cname = "dino_wintoasttemplate_setAudioOption")]
        public void setAudioOption(AudioOption option);
        
        [CCode (cname = "dino_wintoasttemplate_setDuration")]
        public void setDuration(Duration duration);
        
        [CCode (cname = "dino_wintoasttemplate_setExpiration")]
        public void setExpiration(int64 millisecondsFromNow);
    }
}

