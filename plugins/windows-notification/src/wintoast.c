#include <stdio.h>
#include <libloaderapi.h>

#include "wintoast.h"

void(*callback)(void*) = NULL;

HMODULE library_handle = NULL;

typedef void(*ClickCallbackType)(void*);
typedef int(*PidginWinToastLibInitType)(ClickCallbackType);
typedef int(*PidginWinToastLibShowMessageType)(const char*, const char*, const char*, const char*, void*);

PidginWinToastLibInitType library_init = NULL;
PidginWinToastLibShowMessageType library_show_message = NULL;

void init(ClickCallbackType notification_click_callback) {
    printf("Inicializando\n");

    callback = notification_click_callback;
    library_handle = LoadLibrary("PidginWinToastLib.dll");
    if (library_handle) {
        FARPROC function = GetProcAddress(library_handle, "pidginWinToastLibInit");
        if (function) {
            library_init = (PidginWinToastLibInitType)function;
        }

        function = GetProcAddress(library_handle, "pidginWinToastLibShowMessage");
        if (function) {
            library_show_message = (PidginWinToastLibShowMessageType)function;
        }
    }

    if (library_init) {
        library_init(notification_click_callback);
    }
}

void uninit() {
    if (library_handle) {
        FreeLibrary(library_handle);
    }
}

void show_message(const char * sender, const char * message, const char * imagePath, const char * protocolName, void *conv) {
    if (library_show_message) {
        library_show_message(sender, message, imagePath, protocolName, conv);
    }
}