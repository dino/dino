#include <iostream>
#include <string>
#include <string_view>
#include <vector>
#include <tuple>
#include <memory>

#include "winrt-toast-notification-private.h"
#include "winrt-event-token-private.h"
#include "converter.hpp"

template<typename Cont, typename Pred>
inline void erase_if(Cont &c, Pred p)
{
  c.erase(std::remove_if(c.begin(), c.end(), std::move(p)), c.end());
}

#define WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(obj) \
  ((winrtWindowsUINotificationsToastNotificationPrivate*) winrt_windows_ui_notifications_toast_notification_get_instance_private ((winrtWindowsUINotificationsToastNotification*) (obj)))

template<class T>
struct Callback {
private:
  winrtEventToken* token;

public:
  T callback;
  void* context;
  void(*free)(void*);
  

  Callback(T callback, void* context, void(*free)(void*))
    : token   {}
    , callback{callback}
    , context {context}
    , free    {free}
  {}

  ~Callback()
  {
    if (this->callback && this->context && this->free)
    {
      this->free(this->context);
    }

    if (this->token) {
      g_object_unref(this->token);
    }

    this->callback = nullptr;
    this->context = nullptr;
    this->free = nullptr;
    this->token = nullptr;
  }

  void SetToken(winrtEventToken* token) {
    this->token = token;
    g_object_ref(this->token);
  }

  winrtEventToken* GetToken() {
    return this->token;
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

  std::vector<std::shared_ptr<Callback<NotificationCallbackActivated>>> activated{};
  std::vector<std::shared_ptr<Callback<NotificationCallbackFailed>>> failed{};
  std::vector<std::shared_ptr<Callback<NotificationCallbackDismissed>>> dismissed{};
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
    auto token = item->GetToken();
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Activated(*winrt_event_token_get_internal(token));
    }
  }

  for (const auto& item : priv->notification->failed)
  {
    auto token = item->GetToken();
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Failed(*winrt_event_token_get_internal(token));
    }
  }

  for (const auto& item : priv->notification->dismissed)
  {
    auto token = item->GetToken();
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Dismissed(*winrt_event_token_get_internal(token));
    }
  }

  delete priv->notification;

  G_OBJECT_CLASS(winrt_windows_ui_notifications_toast_notification_parent_class)->dispose(self);
}

static void winrt_windows_ui_notifications_toast_notification_class_init (winrtWindowsUINotificationsToastNotificationClass* klass)
{
  GObjectClass* gobject_class = G_OBJECT_CLASS(klass);

  gobject_class->finalize = winrt_windows_ui_notifications_toast_notification_finalize;
}

static void winrt_windows_ui_notifications_toast_notification_init (winrtWindowsUINotificationsToastNotification */*self*/)
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

void winrt_windows_ui_notifications_toast_notification_SetTag(winrtWindowsUINotificationsToastNotification* self, const char* value)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->Tag(sview_to_wstr(value));
}

/**
 * winrt_windows_ui_notifications_toast_notification_GetTag:
 * @manager: a #winrtWindowsUINotificationsToastNotification
 *
 * Returns the value of the tag
 * 
 * Returns: (transfer full): the value
 */
char* winrt_windows_ui_notifications_toast_notification_GetTag(winrtWindowsUINotificationsToastNotification* self)
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), nullptr);

  return wsview_to_char(winrt_windows_ui_notifications_toast_notification_get_internal(self)->Tag());
}

void winrt_windows_ui_notifications_toast_notification_SetGroup(winrtWindowsUINotificationsToastNotification* self, const char* value)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrt_windows_ui_notifications_toast_notification_get_internal(self)->Group(sview_to_wstr(value));
}

/**
 * winrt_windows_ui_notifications_toast_notification_GetGroup:
 * @manager: a #winrtWindowsUINotificationsToastNotification
 *
 * Returns the value of the group
 * 
 * Returns: (transfer full): the value
 */
char* winrt_windows_ui_notifications_toast_notification_GetGroup(winrtWindowsUINotificationsToastNotification* self)
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), nullptr);

  return  wsview_to_char(winrt_windows_ui_notifications_toast_notification_get_internal(self)->Group());
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Activated(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackActivated callback, void* context, void(*free)(void*))
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), NULL);
  g_return_val_if_fail (callback != nullptr && context != nullptr && free != nullptr, NULL);

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto callback_data = std::make_shared<Callback<NotificationCallbackActivated>>(callback, context, free);
  auto token = priv->notification->data.Activated([=](auto /*sender*/, winrt::Windows::Foundation::IInspectable inspectable)
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
    
    auto args = wsview_to_char(arguments);
    callback_data->callback(args, nullptr /* user_input */ , 0 /* user_input.size() */, callback_data->context);
    g_free(args);
  });
  callback_data->SetToken(winrt_event_token_new_from_token(&token));

  priv->notification->activated.push_back(callback_data);
  return callback_data->GetToken();
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Failed(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackFailed callback, void* context, void(*free)(void*))
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), NULL);
  g_return_val_if_fail (callback != nullptr && context != nullptr && free != nullptr, NULL);

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto callback_data = std::make_shared<Callback<NotificationCallbackFailed>>(callback, context, free);
  auto token = priv->notification->data.Failed([=](auto /*sender*/, auto /*toastFailedEventArgs*/)
  {
    callback_data->callback(callback_data->context);
  });

  callback_data->SetToken(winrt_event_token_new_from_token(&token));

  priv->notification->failed.push_back(callback_data);
  return callback_data->GetToken();
}

winrtEventToken* winrt_windows_ui_notifications_toast_notification_Dismissed(winrtWindowsUINotificationsToastNotification* self, NotificationCallbackDismissed callback, void* context, void(*free)(void*))
{
  g_return_val_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self), NULL);
  g_return_val_if_fail (callback != nullptr && context != nullptr && free != nullptr, NULL);

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto callback_data = std::make_shared<Callback<NotificationCallbackDismissed>>(callback, context, free);
  auto token = priv->notification->data.Dismissed([=](auto /*sender*/, winrt::Windows::UI::Notifications::ToastDismissedEventArgs dismissed)
  {
    auto reason = dismissed.Reason();
    callback_data->callback(static_cast<winrtWindowsUINotificationsToastDismissalReason>(reason), callback_data->context);
  });

  callback_data->SetToken(winrt_event_token_new_from_token(&token));

  priv->notification->dismissed.push_back(callback_data);
  return callback_data->GetToken();
}

// TODO: refactor `Remove{Activated,Failed,Dismissed}` methods into one to deduplicate code
void winrt_windows_ui_notifications_toast_notification_RemoveActivated(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  erase_if(priv->notification->activated, [&](const auto& callback) {
      if (winrt_event_token_get_value(token) == winrt_event_token_get_value(callback->GetToken()))
      { 
        if (winrt_event_token_operator_bool(callback->GetToken()))
        {
          priv->notification->data.Activated(*winrt_event_token_get_internal(callback->GetToken()));
        }
        return true;
      }
      return false;
    });
}

void winrt_windows_ui_notifications_toast_notification_RemoveFailed(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  erase_if(priv->notification->failed, [&](const auto& callback) {
      if (winrt_event_token_get_value(token) == winrt_event_token_get_value(callback->GetToken()))
      { 
        if (winrt_event_token_operator_bool(callback->GetToken()))
        {
          priv->notification->data.Failed(*winrt_event_token_get_internal(callback->GetToken()));
        }
        return true;
      }
      return false;
    });
}

void winrt_windows_ui_notifications_toast_notification_RemoveDismissed(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  erase_if(priv->notification->dismissed, [&](const auto& callback) {
      if (winrt_event_token_get_value(token) == winrt_event_token_get_value(callback->GetToken()))
      { 
        if (winrt_event_token_operator_bool(callback->GetToken()))
        {
          priv->notification->data.Dismissed(*winrt_event_token_get_internal(callback->GetToken()));
        }
        return true;
      }
      return false;
    });
}
