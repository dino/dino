#include "winrt-enums.h"

#define WINRT_GLIB_DEFINE_ENUM_VALUE(value,nick) \
  { value, #value, nick },

#define WINRT_GLIB_DEFINE_ENUM_TYPE(TypeName,type_name,values) \
GType \
type_name ## _get_type (void) \
{ \
  static volatile gsize g_define_id__volatile = 0; \
  if (g_once_init_enter (&g_define_id__volatile)) \
    { \
      static const GEnumValue v[] = { \
        values \
        { 0, NULL, NULL }, \
      }; \
      GType g_define_id = g_enum_register_static (g_intern_static_string (#TypeName), v); \
      g_once_init_leave (&g_define_id__volatile, g_define_id); \
    } \
  return g_define_id__volatile; \
}

WINRT_GLIB_DEFINE_ENUM_TYPE (winrtWindowsUINotificationsToastDismissalReason, winrt_windows_ui_notifications_toast_dismissal_reason,
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_Activated, "activated")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_ApplicationHidden, "application-hidden")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_DISMISSAL_REASON_TimedOut, "timed-out"))

WINRT_GLIB_DEFINE_ENUM_TYPE (winrtWindowsUINotificationsToastTemplateType, winrt_windows_ui_notifications_toast_template_type,
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText01, "toast-image-and-text01")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText02, "toast-image-and-text02")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText03, "toast-image-and-text03")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastImageAndText04, "toast-image-and-text04")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText01, "toast-text01")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText02, "toast-text02")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText03, "toast-text03")
  WINRT_GLIB_DEFINE_ENUM_VALUE (WINRT_WINDOWS_UI_NOTIFICATIONS_TOAST_TEMPLATE_TYPE_ToastText04, "toast-text04"))
