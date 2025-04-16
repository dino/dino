#ifndef __WINRT_ENUMS_H__
#define __WINRT_ENUMS_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON \
  (winrtWindowsUINotificationsToastDismissalReason_get_type())

/**
 * winrt_Windows_UI_Notifications_Toast_Dismissal_Reason:
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_Activated: Notification was activated, clicked or through
 * a button
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_ApplicationHidden: Application was hidden
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_TimedOut: Notification timed out
 *
 * Reasons for a notification dismissal
 *
 */
typedef enum {
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_Activated,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_ApplicationHidden,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_TimedOut,
} winrtWindowsUINotificationsToastDismissalReason;

GType winrt_windows_ui_notifications_toast_dismissal_reason_get_type();

#define WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE \
  (winrt_windows_ui_notifications_toast_template_type_get_type())

/**
 * winrtWindowsUINotificationsToastTemplateType:
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText01
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText02
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText03
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText04
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText01
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText02
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText03
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText04
 *
 * Basic templates for a toast notification.
 *
 */
typedef enum {
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText01,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText02,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText03,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText04,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText01,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText02,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText03,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText04,
} winrtWindowsUINotificationsToastTemplateType;

GType winrt_windows_ui_notifications_toast_template_type_get_type();

G_END_DECLS

#endif /* __WINRT_ENUMS_H__ */
