#include <stdio.h>
#include <libloaderapi.h>

#include "wintoast.h"

static HMODULE library_handle = NULL;
static PidginWinToastLibInitType library_init = NULL;
static PidginWinToastLibShowMessageType library_show_message = NULL;

int load_library() {
    library_handle = LoadLibrary("PidginWinToastLib.dll");
    if (!library_handle) {
        return FALSE;
    }
    
    FARPROC function = GetProcAddress(library_handle, "pidginWinToastLibInit");
    if (!function) {
        return FALSE;
    }
    library_init = (PidginWinToastLibInitType)function;

    function = GetProcAddress(library_handle, "pidginWinToastLibShowMessage");
    if (!function) {
        return FALSE;
    }
    library_show_message = (PidginWinToastLibShowMessageType)function;
    return TRUE;
}

int init_library(ClickCallbackType notification_click_callback) {
    if (!library_init) {
        return FALSE;
    }
    library_init(notification_click_callback);
    return TRUE;
}

void uninit_library() {
    if (library_handle) {
        FreeLibrary(library_handle);
    }
}

int show_message(const char * sender, const char * message, const char * imagePath, const char * protocolName, void *conv) {
    if (library_show_message) {
        return library_show_message(sender, message, imagePath, protocolName, conv);
    }

    return -1;
}