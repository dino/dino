#ifndef WINTOAST
#define WINTOAST 1

void init(void(*notification_click_callback)(void *conv));
void uninit();
void show_message(const char * sender, const char * message, const char * imagePath, const char * protocolName, void *conv);

#endif