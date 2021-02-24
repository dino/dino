#include <iostream>
#include <string>
#include <string_view>
#include <vector>
#include <list>
#include <tuple>
#include <memory>

#include "winrt-toast-notification-private.h"
#include "winrt-event-token-private.h"
#include "converter.hpp"

#define WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(obj) \
  ((winrtWindowsUINotificationsToastNotificationPrivate*) winrt_windows_ui_notifications_toast_notification_get_instance_private ((winrtWindowsUINotificationsToastNotification*) (obj)))

template<class T>
struct Callback {
  T callback;
  void* context;
  void(*free)(void*);
  winrtEventToken* token;

  Callback(T callback, void* context, void(*free)(void*), winrtEventToken* token)
  {
    this->callback = callback;
    this->free = free;
    this->context = context;
    this->token = token;
  }

  ~Callback()
  {
    Clear();
  }

  void Clear()
  {
    if (this->callback && this->context && this->free)
    {
      this->free(this->context);
    }

    this->callback = nullptr;
    this->context = nullptr;
    this->free = nullptr;
    this->token = nullptr;
  }

  // delete copy
  Callback(const Callback&) = delete;
  Callback& operator=(const Callback&) = delete;

  // delete move
  Callback(Callback&&) = delete;
  Callback& operator=(Callback&&) = delete;
};

struct _winrtWindowsUINotificationsToastNotificationPrivate
{ 
  winrt::Windows::UI::Notifications::ToastNotification data;

  std::list<std::shared_ptr<Callback<NotificationCallbackActivated>>> activated;
  std::list<std::shared_ptr<Callback<NotificationCallbackFailed>>> failed;
  std::list<std::shared_ptr<Callback<NotificationCallbackDismissed>>> dismissed;
};

typedef struct
{
  _winrtWindowsUINotificationsToastNotificationPrivate* notification;
} winrtWindowsUINotificationsToastNotificationPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (winrtWindowsUINotificationsToastNotification, winrt_windows_ui_notifications_toast_notification, G_TYPE_OBJECT)

static void winrt_windows_ui_notifications_toast_notification_finalize(GObject* self)
{
  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE (self);

  for (const auto& item : priv->notification->activated)
  {
    auto token = item->token;
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Activated(*winrt_event_token_get_internal(token));
    }
    g_object_unref(token);
  }

  for (const auto& item : priv->notification->failed)
  {
    auto token = item->token;
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Failed(*winrt_event_token_get_internal(token));
    }
    g_object_unref(token);
  }

  for (const auto& item : priv->notification->dismissed)
  {
    auto token = item->token;
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Dismissed(*winrt_event_token_get_internal(token));
    }
    g_object_unref(token);
  }

  delete priv->notification;

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
  g_return_val_if_fail (doc != NULL, NULL);

  auto ret = static_cast<winrtWindowsUINotificationsToastNotification*>(g_object_new (WINRT_TYPE_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION, NULL));
  winrt::Windows::Data::Xml::Dom::XmlDocument xmlDoc;
  xmlDoc.LoadXml(sview_to_wstr(doc));
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

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->Tag(sview_to_wstr(value));
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

  return wsview_to_char(winrt_windows_ui_notifications_toast_notification_get_internal(self)->Tag());
}

void winrt_windows_ui_notifications_toast_notification_set_Group(winrtWindowsUINotificationsToastNotification* self, const char* value)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->Group(sview_to_wstr(value));
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

  return  wsview_to_char(winrt_windows_ui_notifications_toast_notification_get_internal(self)->Group());
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Activated(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackActivated callback, void* context, void(*free)(void*))
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), NULL);
  g_return_val_if_fail (callback != nullptr && context != nullptr && free != nullptr, NULL);

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto token = priv->notification->data.Activated([=](auto sender, winrt::Windows::Foundation::IInspectable inspectable)
  {
    std::wstring arguments;
    std::vector<std::tuple<std::wstring, std::wstring>> user_input;
    {
      auto args = inspectable.try_as<winrt::Windows::UI::Notifications::IToastActivatedEventArgs>();
      if (args != nullptr)
      {
        arguments = std::wstring(args.Arguments());
      }
    }

    {
      auto args = inspectable.try_as<winrt::Windows::UI::Notifications::IToastActivatedEventArgs2>();
      if (args != nullptr)
      {
        for (const auto& item : args.UserInput())
        {
          auto value = winrt::unbox_value_or<winrt::hstring>(item.Value(), winrt::hstring());
          user_input.emplace_back(std::make_tuple(std::wstring(item.Key()), std::wstring(value)));
        }
      }
    }
    
    callback(wsview_to_char(arguments), nullptr /* user_input */ , 0 /* user_input.size() */, context);
  });
  auto new_token = winrt_event_token_new_from_token(&token);
  g_object_ref(new_token);

  priv->notification->activated.push_back(std::make_shared<Callback<NotificationCallbackActivated>>(callback, context, free, new_token));
  return new_token;
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Failed(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackFailed callback, void* context, void(*free)(void*))
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), NULL);
  g_return_val_if_fail (callback != nullptr && context != nullptr && free != nullptr, NULL);

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto token = priv->notification->data.Failed([=](auto sender, auto toastFailedEventArgs)
  {
    callback(context);
  });

  auto new_token = winrt_event_token_new_from_token(&token);
  g_object_ref(new_token);

  priv->notification->failed.push_back(std::make_shared<Callback<NotificationCallbackFailed>>(callback, context, free, new_token));
  return new_token;
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Dismissed(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackDismissed callback, void* context, void(*free)(void*))
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), NULL);
  g_return_val_if_fail (callback != nullptr && context != nullptr && free != nullptr, NULL);

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto token = priv->notification->data.Dismissed([=](auto sender, winrt::Windows::UI::Notifications::ToastDismissedEventArgs dismissed)
  {
    auto reason = dismissed.Reason();
    callback(static_cast<winrtWindowsUINotificationsToastDismissalReason>(reason), context);
  });

  auto new_token = winrt_event_token_new_from_token(&token);
  g_object_ref(new_token);

  priv->notification->dismissed.push_back(std::make_shared<Callback<NotificationCallbackDismissed>>(callback, context, free, new_token));
  return new_token;
}

// TODO: refactor `Remove{Activated,Failed,Dismissed}` methods into one to deduplicate code
void winrt_windows_ui_notifications_toast_notification_RemoveActivated(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  priv->notification->activated.remove_if([&](const auto& callback) {
      if (winrt_event_token_get_value(token) == winrt_event_token_get_value(callback->token))
      { 
        if (winrt_event_token_operator_bool(callback->token))
        {
          priv->notification->data.Activated(*winrt_event_token_get_internal(callback->token));
        }
        g_object_unref(callback->token);
        return true;
      }
      return false;
    });
}

void winrt_windows_ui_notifications_toast_notification_RemoveFailed(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  priv->notification->failed.remove_if([&](const auto& callback) {
      if (winrt_event_token_get_value(token) == winrt_event_token_get_value(callback->token))
      { 
        if (winrt_event_token_operator_bool(callback->token))
        {
          priv->notification->data.Failed(*winrt_event_token_get_internal(callback->token));
        }
        g_object_unref(callback->token);
        return true;
      }
      return false;
    });
}

void winrt_windows_ui_notifications_toast_notification_RemoveDismissed(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  priv->notification->dismissed.remove_if([&](const auto& callback) {
      if (winrt_event_token_get_value(token) == winrt_event_token_get_value(callback->token))
      { 
        if (winrt_event_token_operator_bool(callback->token))
        {
          priv->notification->data.Dismissed(*winrt_event_token_get_internal(callback->token));
        }
        g_object_unref(callback->token);
        return true;
      }
      return false;
    });
}