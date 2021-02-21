#ifndef __WINRT_ENUMS_H__
#define __WINRT_ENUMS_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define WINRT_TYPE_DISMISSED_REASON (winrt_dismissed_reason_get_type ())

/**
 * WinrtDismissedReason:
 * @WINRT_DISMISSED_REASON_ACTIVATED: Notification was activated, clicked or through
 * a button
 * @WINRT_DISMISSED_REASON_APPLICATION_HIDDEN: Application was hidden
 * @WINRT_DISMISSED_REASON_TIMED_OUT: Notification timed out
 *
 * Reasons for a notification dismissal
 *
 */
typedef enum {
  WINRT_DISMISSED_REASON_ACTIVATED,
  WINRT_DISMISSED_REASON_APPLICATION_HIDDEN,
  WINRT_DISMISSED_REASON_TIMED_OUT,
} WinrtDismissedReason;

GType winrt_dismissed_reason_get_type (void);

G_END_DECLS

#endif /* __WINRT_ENUMS_H__ */
