#ifndef __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER_PRIVATE_H__
#define __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER_PRIVATE_H__

#include <glib.h>
#include "winrt-headers.h"

#include "winrt-toast-notifier.h"

winrt::Windows::UI::Notifications::ToastNotifier* winrt_windows_ui_notifications_toast_notifier_get_internal(winrtWindowsUINotificationsToastNotifier* self);
void winrt_windows_ui_notifications_toast_notifier_set_internal(winrtWindowsUINotificationsToastNotifier *self, winrt::Windows::UI::Notifications::ToastNotifier notification);

#endif /* __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER_PRIVATE_H__ */
