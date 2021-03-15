#include <iostream>
#include <string>
#include <string_view>

#include "winrt-toast-notifier-private.h"
#include "winrt-toast-notification-private.h"
#include "converter.hpp"

#define WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFIER_GET_PRIVATE(obj) \
  ((winrtWindowsUINotificationsToastNotifierPrivate*) winrt_windows_ui_notifications_toast_notifier_get_instance_private ((winrtWindowsUINotificationsToastNotifier*) (obj)))

typedef struct
{
  winrt::Windows::UI::Notifications::ToastNotifier data;
} _winrtWindowsUINotificationsToastNotifierPrivate;

typedef struct
{
  _winrtWindowsUINotificationsToastNotifierPrivate* notifier;
} winrtWindowsUINotificationsToastNotifierPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (winrtWindowsUINotificationsToastNotifier, winrt_windows_ui_notifications_toast_notifier, G_TYPE_OBJECT)

static void winrt_windows_ui_notifications_toast_notifier_finalize(GObject* self)
{
  winrtWindowsUINotificationsToastNotifierPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFIER_GET_PRIVATE (self);

  delete priv->notifier;

  G_OBJECT_CLASS(winrt_windows_ui_notifications_toast_notifier_parent_class)->dispose(self);
}

static void winrt_windows_ui_notifications_toast_notifier_class_init (winrtWindowsUINotificationsToastNotifierClass* klass)
{
  GObjectClass* gobject_class = G_OBJECT_CLASS(klass);

  gobject_class->finalize = winrt_windows_ui_notifications_toast_notifier_finalize;
}

static void winrt_windows_ui_notifications_toast_notifier_init (winrtWindowsUINotificationsToastNotifier *self)
{
}

/*< private >
 * winrt_windows_ui_notifications_toast_notifier_get_internal:
 * @self: a #winrtWindowsUINotificationsToastNotifier
 *
 * Retrieves the `winrt::Windows::UI::Notifications::ToastNotifier` object used by @self.
 *
 * Returns: (transfer none): a pointer to the internal toast notification instance
 */
winrt::Windows::UI::Notifications::ToastNotifier* winrt_windows_ui_notifications_toast_notifier_get_internal(winrtWindowsUINotificationsToastNotifier *self)
{
  winrtWindowsUINotificationsToastNotifierPrivate *priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFIER_GET_PRIVATE (self);

  return &priv->notifier->data;
}

/*< private >
 * winrt_windows_ui_notifications_toast_notifier_set_internal:
 * @self: a #winrtWindowsUINotificationsToastNotifier
 * @notification: a `winrt::Windows::UI::Notifications::ToastNotifier` instance
 *
 * Sets the internal database instance wrapped by @self, clearing
 * any existing instance if needed.
 */
void winrt_windows_ui_notifications_toast_notifier_set_internal(winrtWindowsUINotificationsToastNotifier* self, winrt::Windows::UI::Notifications::ToastNotifier notifier)
{
  winrtWindowsUINotificationsToastNotifierPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFIER_GET_PRIVATE(self);

  delete priv->notifier;

  priv->notifier = new _winrtWindowsUINotificationsToastNotifierPrivate { notifier };
}

/**
 * winrt_windows_ui_notifications_toast_notifier_new:
 * @doc: the document to be shown
 * 
 * Creates a new toast notifier instance with its aumid set
 *
 * Returns: (transfer full): the newly created #winrtWindowsUINotificationsToastNotifier instance
 */
winrtWindowsUINotificationsToastNotifier* winrt_windows_ui_notifications_toast_notifier_new(const gchar* aumid)
{
  g_return_val_if_fail (aumid != NULL, NULL);

  auto ret = static_cast<winrtWindowsUINotificationsToastNotifier*>(g_object_new (WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER, NULL));
  auto notifier = winrt::Windows::UI::Notifications::ToastNotificationManager::CreateToastNotifier(sview_to_wstr(aumid));
  winrt_windows_ui_notifications_toast_notifier_set_internal(ret, notifier);
  return ret;
}

void winrt_windows_ui_notifications_toast_notifier_Show(winrtWindowsUINotificationsToastNotifier* self, winrtWindowsUINotificationsToastNotification* toast_notification)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER (self));
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (toast_notification));

  winrt_windows_ui_notifications_toast_notifier_get_internal(self)->Show(*winrt_windows_ui_notifications_toast_notification_get_internal(toast_notification));
}

void winrt_windows_ui_notifications_toast_notifier_Hide(winrtWindowsUINotificationsToastNotifier* self, winrtWindowsUINotificationsToastNotification* toast_notification)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFIER (self));
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (toast_notification));

  winrt_windows_ui_notifications_toast_notifier_get_internal(self)->Hide(*winrt_windows_ui_notifications_toast_notification_get_internal(toast_notification));
}