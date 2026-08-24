#ifndef __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER_H__
#define __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER_H__

#if !defined(WINRT_GLIB_H_INSIDE) && !defined(WINRT_GLIB_COMPILATION)
#error "Only <winrt-glib.h> can be included directly."
#endif

#include "winrt-glib-types.h"
#include "winrt-toast-notification.h"

G_BEGIN_DECLS

#define WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER (winrt_windows_ui_notifications_toast_notifier_get_type())

G_DECLARE_DERIVABLE_TYPE (winrtWindowsUINotificationsToastNotifier, winrt_windows_ui_notifications_toast_notifier, WINRT, WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER, GObject)

struct _winrtWindowsUINotificationsToastNotifierClass
{
  /*< private >*/
  GObjectClass parent_class;
};

#ifdef __cplusplus
extern "C"
{
#endif

winrtWindowsUINotificationsToastNotifier* winrt_windows_ui_notifications_toast_notifier_new(const gchar* aumid);

void winrt_windows_ui_notifications_toast_notifier_Show(winrtWindowsUINotificationsToastNotifier* self, winrtWindowsUINotificationsToastNotification* toast_notification);
void winrt_windows_ui_notifications_toast_notifier_Hide(winrtWindowsUINotificationsToastNotifier* self, winrtWindowsUINotificationsToastNotification* toast_notification);

#ifdef __cplusplus
}
#endif

G_END_DECLS

#endif /* __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER_H__ */
