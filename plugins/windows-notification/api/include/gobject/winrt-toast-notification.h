#ifndef __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_H__
#define __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_H__

#if !defined(WINRT_GLIB_H_INSIDE) && !defined(WINRT_GLIB_COMPILATION)
#error "Only <winrt-glib.h> can be included directly."
#endif

#include "winrt-glib-types.h"
#include "winrt-event-token.h"

G_BEGIN_DECLS

#define WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (winrt_windows_ui_notifications_toast_notification_get_type())

G_DECLARE_DERIVABLE_TYPE (winrtWindowsUINotificationsToastNotification, winrt_windows_ui_notifications_toast_notification, WINRT, WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION, GObject)

struct _winrtWindowsUINotificationsToastNotificationClass
{
  /*< private >*/
  GObjectClass parent_class;
};

#ifdef __cplusplus
extern "C"
{
#endif

typedef void(*NotificationCallbackFailed)(void* userdata);
typedef void(*NotificationCallbackActivated)(const gchar* arguments, gchar** userInput, gint count, void* userdata);
typedef void(*NotificationCallbackDismissed)(winrt_Windows_UI_Notifications_Toast_Dismissal_Reason reason, void* userdata);

winrtWindowsUINotificationsToastNotification* winrt_windows_ui_notifications_toast_notification_new(const gchar* doc);

void winrt_windows_ui_notifications_toast_notification_set_ExpiresOnReboot(winrtWindowsUINotificationsToastNotification* self, gboolean value);
gboolean winrt_windows_ui_notifications_toast_notification_get_ExpiresOnReboot(winrtWindowsUINotificationsToastNotification* self);

void winrt_windows_ui_notifications_toast_notification_set_Tag(winrtWindowsUINotificationsToastNotification* self, const gchar* value);
gchar* winrt_windows_ui_notifications_toast_notification_get_Tag(winrtWindowsUINotificationsToastNotification* self);

void winrt_windows_ui_notifications_toast_notification_set_Group(winrtWindowsUINotificationsToastNotification* self, const gchar* value);
gchar* winrt_windows_ui_notifications_toast_notification_get_Group(winrtWindowsUINotificationsToastNotification* self);

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Activated(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackActivated callback, void* context, void(*free)(void*));
void winrt_windows_ui_notifications_toast_notification_RemoveActivated(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token);

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Failed(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackFailed callback, void* context, void(*free)(void*));
void winrt_windows_ui_notifications_toast_notification_RemoveFailed(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token);

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Dismissed(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackDismissed callback, void* context, void(*free)(void*));
void winrt_windows_ui_notifications_toast_notification_RemoveDismissed(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token);

#ifdef __cplusplus
}
#endif

G_END_DECLS

#endif /* __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_H__ */
