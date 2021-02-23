#include <iostream>
#include <string>
#include <string_view>
#include <vector>
#include <tuple>

#include "winrt-toast-notification-private.h"
#include "winrt-event-token-private.h"
#include "converter.hpp"

#define WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(obj) \
  ((winrtWindowsUINotificationsToastNotificationPrivate*) winrt_windows_ui_notifications_toast_notification_get_instance_private ((winrtWindowsUINotificationsToastNotification*) (obj)))

typedef struct
{
  winrt::Windows::UI::Notifications::ToastNotification data;
} _winrtWindowsUINotificationsToastNotificationPrivate;

template<class T>
class Callback {
public:
  T callback;
  void* context;
  void(*free)(void*);

  Callback(T callback, void* context, void(*free)(void*))
  {
    this->callback = callback;
    this->free = free;
    this->context = context;
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

    callback = nullptr;
    context = nullptr;
    free = nullptr;
  }

  // delete copy
  Callback(const Callback&) = delete;
  Callback& operator=(const Callback&) = delete;

  // allow move
  Callback(Callback&&) = default;
  Callback& operator=(Callback&&) = default;
};

typedef struct
{
  std::unordered_map<winrtEventToken*, Callback<NotificationCallbackActivated>> activated;

  std::unordered_map<winrtEventToken*, Callback<NotificationCallbackSimple>> failed;

  // Notification_Callback_Dismissed callback;
  // void* context;
  // void(*free)(void*);

  _winrtWindowsUINotificationsToastNotificationPrivate* notification;
} winrtWindowsUINotificationsToastNotificationPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (winrtWindowsUINotificationsToastNotification, winrt_windows_ui_notifications_toast_notification, G_TYPE_OBJECT)

static void winrt_windows_ui_notifications_toast_notification_finalize(GObject* self)
{
  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE (self);

  for (const auto& item : priv->activated)
  {
    auto token = std::get<0>(item);
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Activated(*winrt_event_token_get_internal(token));
    }
    g_object_unref(token);
  }
  priv->activated.clear();

  for (const auto& item : priv->failed)
  {
    auto token = std::get<0>(item);
    if (winrt_event_token_operator_bool(token))
    {
      priv->notification->data.Failed(*winrt_event_token_get_internal(token));
    }
    g_object_unref(token);
  }
  priv->failed.clear();

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
  g_return_val_if_fail (doc == NULL, NULL);

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

  auto token = priv->notification->data.Activated([&](auto sender, winrt::Windows::Foundation::IInspectable inspectable)
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
    
    std::cout << "Notification activated!" << std::endl;
    callback(wsview_to_char(arguments.data()), nullptr /* user_input */ , 0 /* user_input.size() */, context);
  });
  auto new_token = winrt_event_token_new_from_token(&token);
  g_object_ref(new_token);

  priv->activated.emplace(new_token, Callback<NotificationCallbackActivated>(callback, context, free));
  return new_token;
}

void winrt_windows_ui_notifications_toast_notification_RemoveActivated(winrtWindowsUINotificationsToastNotification* self, winrtEventToken* token)
{
  g_return_if_fail (WINRT_IS_WINDOWS_UI_NOTIFICATIONS_TOAST_NOTIFICATION (self));

  winrtWindowsUINotificationsToastNotificationPrivate* priv = WINRT_WINDOWS_UI_NOTIFICATION_TOAST_NOTIFICATION_GET_PRIVATE(self);

  auto item = priv->activated.find(token);
  if (item != priv->activated.end())
  {
      auto local_token = std::get<0>(*item);
      if (winrt_event_token_operator_bool(local_token))
      {
        priv->notification->data.Activated(*winrt_event_token_get_internal(local_token));
      }

      priv->activated.erase(item);
  }
}