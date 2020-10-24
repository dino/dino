#ifndef WINTOAST
#define WINTOAST 1

typedef void(*ClickCallbackType)(void*);
typedef int(*PidginWinToastLibInitType)(ClickCallbackType);
typedef int(*PidginWinToastLibShowMessageType)(const char*, const char*, const char*, const char*, void*);

int load_library();
int init_library(ClickCallbackType click_callback);
void uninit_library();
int show_message(const char * sender, const char * message, const char * imagePath, const char * protocolName, void *conv);

#endif