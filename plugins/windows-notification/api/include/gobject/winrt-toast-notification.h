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

typedef void(*Notification_Callback_Simple)(void* userdata);
typedef void(*Notification_Callback_ActivatedWithActionIndex)(int action_id, void* userdata);
//typedef void(*Notification_Callback_Dismissed)(Dismissed_Reason reason, void* userdata);

winrtWindowsUINotificationsToastNotification* winrt_windows_ui_notifications_toast_notification_new(const char* doc);

void winrt_windows_ui_notifications_toast_notification_set_ExpiresOnReboot(winrtWindowsUINotificationsToastNotification* self, gboolean value);
gboolean winrt_windows_ui_notifications_toast_notification_get_ExpiresOnReboot(winrtWindowsUINotificationsToastNotification* self);

void winrt_windows_ui_notifications_toast_notification_set_Tag(winrtWindowsUINotificationsToastNotification* self, const char* value);
char* winrt_windows_ui_notifications_toast_notification_get_Tag(winrtWindowsUINotificationsToastNotification* self);

void winrt_windows_ui_notifications_toast_notification_set_Group(winrtWindowsUINotificationsToastNotification* self, const char* value);
char* winrt_windows_ui_notifications_toast_notification_get_Group(winrtWindowsUINotificationsToastNotification* self);

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Activated(winrtWindowsUINotificationsToastNotification* self, Notification_Callback_Simple callback, void* context, void(*free)(void*));
void winrt_windows_ui_notifications_toast_notification_RemoveActivatedAction(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token);

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Failed(winrtWindowsUINotificationsToastNotification* self, Notification_Callback_Simple callback, void* context, void(*free)(void*));
//winrtEventToken* winrt_windows_ui_notifications_toast_notification_Dismissed(winrtWindowsUINotificationsToastNotification* self, Notification_Callback_Dismissed callback, void* context, void(*free)(void*));

#ifdef __cplusplus
}
#endif

G_END_DECLS

#endif /* __WINRT_GLIB_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION_H__ */
