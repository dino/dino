/**
 * SECTION:winrt-toast-notification-manager
 * @Title: winrtWindowsUINotificationsToastNotification
 * @short_description: A read-only database
 *
 * #winrtWindowsUINotificationsToastNotification is a class that allows read-only access to a
 * Xapian database at a given path.
 *
 * Typically, you will use #winrtWindowsUINotificationsToastNotification to open a database for
 * querying, by using the #XapianEnquire class.
 */

#include <iostream>
#include <string>

#include "winrt-toast-notification-private.h"
#include "winrt-event-token-private.h"
#include "converter.hpp"

#define WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(obj) \
  ((winrtWindowsUINotificationsToastNotificationPrivate*) winrt_windows_ui_notifications_toast_notification_get_instance_private ((winrtWindowsUINotificationsToastNotification*) (obj)))

typedef struct
{
  winrt::Windows::UI::Notifications::ToastNotification data;
} _winrtWindowsUINotificationsToastNotificationPrivate;

typedef struct
{
  Notification_Callback_Simple activated;
  void* activated_context;
  void(*activated_free)(void*);

  Notification_Callback_Simple failed;
  void* failed_context;
  void(*failed_free)(void*);

  // Notification_Callback_ActivatedWithActionIndex callback;
  // void* context;
  // void(*free)(void*);

  // Notification_Callback_Dismissed callback;
  // void* context;
  // void(*free)(void*);

  _winrtWindowsUINotificationsToastNotificationPrivate* notification;
} winrtWindowsUINotificationsToastNotificationPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (winrtWindowsUINotificationsToastNotification, winrt_windows_ui_notifications_toast_notification, G_TYPE_OBJECT)

static void winrt_windows_ui_notifications_toast_notification_finalize(GObject* self)
{
  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE (self);

  delete priv->notification;

  // TODO: save token to remove the notification
  if (priv->activated && priv->activated_context && priv->activated_free)
  {
    priv->activated_free(priv->activated_context);
  }

  if (priv->failed && priv->failed_context && priv->failed_free)
  {
    priv->failed_free(priv->failed_context);
  }

  G_OBJECT_CLASS(winrt_windows_ui_notifications_toast_notification_parent_class)->dispose(self);
}

static void winrt_windows_ui_notifications_toast_notification_class_init (winrtWindowsUINotificationsToastNotificationClass* klass)
{
  GObjectClass* gobject_class = G_OBJECT_CLASS(klass);

  gobject_class->finalize = winrt_windows_ui_notifications_toast_notification_finalize;
}

static void winrt_windows_ui_notifications_toast_notification_init (winrtWindowsUINotificationsToastNotification *self)
{
}

/*< private >
 * winrt_windows_ui_notifications_toast_notification_get_internal:
 * @self: a #winrtWindowsUINotificationsToastNotification
 *
 * Retrieves the `winrt::Windows::UI::Notifications::ToastNotification` object used by @self.
 *
 * Returns: (transfer none): a pointer to the internal toast notification instance
 */
winrt::Windows::UI::Notifications::ToastNotification* winrt_windows_ui_notifications_toast_notification_get_internal(winrtWindowsUINotificationsToastNotification *self)
{
  winrtWindowsUINotificationsToastNotificationPrivate *priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE (self);

  return &priv->notification->data;
}

/*< private >
 * winrt_windows_ui_notifications_toast_notification_set_internal:
 * @self: a #winrtWindowsUINotificationsToastNotification
 * @notification: a `winrt::Windows::UI::Notifications::ToastNotification` instance
 *
 * Sets the internal database instance wrapped by @self, clearing
 * any existing instance if needed.
 */
void winrt_windows_ui_notifications_toast_notification_set_internal(winrtWindowsUINotificationsToastNotification* self, winrt::Windows::UI::Notifications::ToastNotification notification)
{
  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  delete priv->notification;

  priv->notification = new _winrtWindowsUINotificationsToastNotificationPrivate { notification };
}

/**
 * winrt_windows_ui_notifications_toast_notification_new:
 * @doc: the document to be shown
 * 
 * Creates a new toast notification with a document already set.
 *
 * Returns: (transfer full): the newly created #winrtWindowsUINotificationsToastNotification instance
 */
winrtWindowsUINotificationsToastNotification* winrt_windows_ui_notifications_toast_notification_new(const char* doc)
{
  g_return_val_if_fail (doc == NULL, NULL);

  auto ret = static_cast<winrtWindowsUINotificationsToastNotification*>(g_object_new (WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION, NULL));
  winrt::Windows::Data::Xml::Dom::XmlDocument xmlDoc;
  xmlDoc.LoadXml(char_to_wstr(doc));
  winrt_windows_ui_notifications_toast_notification_set_internal(ret, winrt::Windows::UI::Notifications::ToastNotification{ xmlDoc });
  return ret;
}

void winrt_windows_ui_notifications_toast_notification_set_ExpiresOnReboot(winrtWindowsUINotificationsToastNotification* self, gboolean value)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->ExpiresOnReboot(value);
}

gboolean winrt_windows_ui_notifications_toast_notification_get_ExpiresOnReboot(winrtWindowsUINotificationsToastNotification* self)
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), FALSE);

  return winrt_windows_ui_notifications_toast_notification_get_internal(self)->ExpiresOnReboot();
}

void winrt_windows_ui_notifications_toast_notification_set_Tag(winrtWindowsUINotificationsToastNotification* self, const char* value)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->Tag(char_to_wstr(value));
}

/**
 * winrt_windows_ui_notifications_toast_notification_get_Tag:
 * @manager: a #winrtWindowsUINotificationsToastNotification
 *
 * Returns the value of the tag
 * 
 * Returns: (transfer full): the value
 */
char* winrt_windows_ui_notifications_toast_notification_get_Tag(winrtWindowsUINotificationsToastNotification* self)
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), FALSE);

  return  wstr_to_char(std::wstring(winrt_windows_ui_notifications_toast_notification_get_internal(self)->Tag()));
}

void winrt_windows_ui_notifications_toast_notification_set_Group(winrtWindowsUINotificationsToastNotification* self, const char* value)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->Group(char_to_wstr(value));
}

/**
 * winrt_windows_ui_notifications_toast_notification_get_Group:
 * @manager: a #winrtWindowsUINotificationsToastNotification
 *
 * Returns the value of the group
 * 
 * Returns: (transfer full): the value
 */
char* winrt_windows_ui_notifications_toast_notification_get_Group(winrtWindowsUINotificationsToastNotification* self)
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), FALSE);

  return  wstr_to_char(std::wstring(winrt_windows_ui_notifications_toast_notification_get_internal(self)->Group()));
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Activated(winrtWindowsUINotificationsToastNotification* self, Notification_Callback_Simple callback, void* context, void(*free)(void*))
{
  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self); 

  if (priv->activated && priv->activated_context && priv->activated_free)
  {
    // TODO: should also save token to unregister it
    priv->activated_free(priv->activated_context);
  }

  priv->activated = callback;
  priv->activated_context = context;
  priv->activated_free = free;

  auto token = priv->notification->data.Activated([&](auto sender, winrt::Windows::Foundation::IInspectable inspectable)
  {
    std::cout << "Notification activated!" << std::endl;
    priv->activated(priv->activated_context);
  });
  return winrt_event_token_new_from_token(&token);
  return nullptr;
}

void winrt_windows_ui_notifications_toast_notification_RemoveActivatedAction(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  if (winrt_event_token_operator_bool(token))
  {
    priv->notification->data.Activated(*winrt_event_token_get_internal(token));
  }

  if (priv->activated && priv->activated_context && priv->activated_free)
  {
    priv->activated_free(priv->activated_context);
    priv->activated = nullptr;
    priv->activated_context = nullptr;
    priv->activated_free = nullptr;
  }
}