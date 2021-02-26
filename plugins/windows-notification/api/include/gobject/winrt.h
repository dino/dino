#ifndef __WINRT_GLIB_2_H__
#define __WINRT_GLIB_2_H__

#if !defined(WINRT_GLIB_H_INSIDE) && !defined(WINRT_GLIB_COMPILATION)
#error "Only <winrt-glib.h> can be included directly."
#endif

#include "winrt-enums.h"

#ifdef __cplusplus
extern "C"
{
#endif

gboolean winrt_InitApartment();
char* winrt_windows_ui_notifications_toast_notification_manager_GetTemplateContent(winrtWindowsUINotificationsToastTemplateType type);

#ifdef __cplusplus
}
#endif

#endif // __WINRT_GLIB_2_H__