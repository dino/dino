namespace Dino.Plugins.WindowsNotification {
    public class WinToast {
        [CCode (has_target = false)]
        private delegate void FunctionPointer();
        
        [CCode (has_target = true)]
        public delegate void NotificationCallback(int conv_id);

        [CCode (has_target = false)]
        private delegate int DinoWinToastLibInitType();

        [CCode (has_target = false)]
        private delegate int DinoWinToastLibShowMessageType(char* sender, char* message, char* image_path, int conv_id, void* class_obj, NotificationCallback callback);

        [CCode (cname = "LoadLibrary", cheader_filename = "libloaderapi.h")]
        private static extern void* load_library(char* lib_name);

        [CCode (cname = "FreeLibrary", cheader_filename = "libloaderapi.h")]
        private static extern int free_library(void* handle);

        [CCode (cname = "GetProcAddress", cheader_filename = "libloaderapi.h")]
        private static extern FunctionPointer get_proc_address(void* lib_handle, char* func_name);

        private void* library_handle = null;
        private DinoWinToastLibInitType library_init = null;
        private DinoWinToastLibShowMessageType library_show_message = null;

        public bool valid { get; private set; }

        public WinToast() {
            valid = load();
            if (valid) {
                valid = library_init() == 0;
            }
        }

        ~WinToast() {
            if (library_handle != null) {
                free_library(library_handle);
            }
        }

        public bool show_message(string sender, string message, string? image_path, int conv_id, void* class_obj, NotificationCallback callback) {
            if (valid && library_show_message != null) {
                return library_show_message(sender, message, image_path, conv_id, class_obj, callback) == 0;
            }
            return false;
        }

        private bool load() {
            library_handle = load_library("DinoWinToastLib.dll");
            if (library_handle == null) {
                return false;
            }
            
            FunctionPointer function = get_proc_address(library_handle, "dinoWinToastLibInit");
            if (function == null) {
                return false;
            }
            library_init = (DinoWinToastLibInitType)function;
        
            function = get_proc_address(library_handle, "dinoWinToastLibShowMessage");
            if (function == null) {
                return false;
            }
            library_show_message = (DinoWinToastLibShowMessageType)function;
            return true;
        }
    }
}