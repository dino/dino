#ifndef __WINRT_ENUMS_H__
#define __WINRT_ENUMS_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define WINRT_TYPE_DISMISSED_REASON (winrt_windows_ui_notifications_toast_dismissal_reason_get_type ())

/**
 * WinrtDismissedReason:
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_ACTIVATED: Notification was activated, clicked or through
 * a button
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_APPLICATION_HIDDEN: Application was hidden
 * @WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_TIMED_OUT: Notification timed out
 *
 * Reasons for a notification dismissal
 *
 */
typedef enum {
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_ACTIVATED,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_APPLICATION_HIDDEN,
  WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_TIMED_OUT,
} winrt_Windows_UI_Notifications_Toast_Dismissal_Reason;

GType winrt_windows_ui_notifications_toast_dismissal_reason_get_type (void);

G_END_DECLS

#endif /* __WINRT_ENUMS_H__ */
