#ifndef __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_PRIVATE_H__
#define __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_PRIVATE_H__

#include <glib.h>
#include "winrt-headers.h"

#include "winrt-toast-notification.h"

winrt::Windows::UI::Notifications::ToastNotification* winrt_windows_ui_notifications_toast_notification_get_internal(winrtWindowsUINotificationsToastNotification* self);
void winrt_windows_ui_notifications_toast_notification_set_internal(winrtWindowsUINotificationsToastNotification *self, winrt::Windows::UI::Notifications::ToastNotification notification);

#endif /* __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_PRIVATE_H__ */
