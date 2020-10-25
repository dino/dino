namespace Dino.Plugins.WindowsNotification {
    public class WinToast {
        [CCode (has_target = false)]
        private delegate void FunctionPointer();
        
        [CCode (has_target = false)]
        public delegate void NotificationCallback(void* conv);

        [CCode (has_target = false)]
        private delegate int PidginWinToastLibInitType(NotificationCallback callback);

        [CCode (has_target = false)]
        private delegate int PidginWinToastLibShowMessageType(char* sender, char* message, char* image_path, char* protocolName, void *conv);

        [CCode (cname = "LoadLibrary", cheader_filename = "libloaderapi.h")]
        private static extern void* load_library(char* lib_name);

        [CCode (cname = "FreeLibrary", cheader_filename = "libloaderapi.h")]
        private static extern int free_library(void* handle);

        [CCode (cname = "GetProcAddress", cheader_filename = "libloaderapi.h")]
        private static extern FunctionPointer get_proc_address(void* lib_handle, char* func_name);

        private void* library_handle = null;
        private PidginWinToastLibInitType library_init = null;
        private PidginWinToastLibShowMessageType library_show_message = null;

        public bool valid { get; private set; }

        public WinToast(NotificationCallback callback) {
            valid = load();
            if (valid) {
                valid = library_init(callback) == 0;
            }
        }

        ~WinToast() {
            if (library_handle != null) {
                free_library(library_handle);
            }
        }

        public bool show_message(string sender, string message, string image_path, void *conv) {
            if (valid && library_show_message != null) {
                return library_show_message(sender, message, image_path, null, conv) == 0;
            }
            return false;
        }

        private bool load() {
            library_handle = load_library("PidginWinToastLib.dll");
            if (library_handle == null) {
                return false;
            }
            
            FunctionPointer function = get_proc_address(library_handle, "pidginWinToastLibInit");
            if (function == null) {
                return false;
            }
            library_init = (PidginWinToastLibInitType)function;
        
            function = get_proc_address(library_handle, "pidginWinToastLibShowMessage");
            if (function == null) {
                return false;
            }
            library_show_message = (PidginWinToastLibShowMessageType)function;
            return true;
        }
    }
}