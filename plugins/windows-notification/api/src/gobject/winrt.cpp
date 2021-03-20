
#include "gobject/winrt-private.h"
#include "converter.hpp"
#include "ginvoke.hpp"

#include <windows.h>

static void ImplInitApartment()
{
    const auto res = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(res))
    {
        if (res == RPC_E_CHANGED_MODE)  // seems harmless
            g_info("attempted to change COM apartment mode of thread %" PRIu32,
                ::GetCurrentThreadId());
        else
            winrt::throw_hresult(res);
    }
}

gboolean winrt_InitApartment() noexcept
{
    return g_try_invoke0(ImplInitApartment).has_value();
}

static char* ImplGetTemplateContent(winrtWindowsUINotificationsToastTemplateType type)
{
    using namespace winrt::Windows::UI::Notifications;
    return wsview_to_char(ToastNotificationManager::GetTemplateContent(static_cast<ToastTemplateType>(type)).GetXml());
}

char* winrt_windows_ui_notifications_toast_notification_manager_GetTemplateContent(winrtWindowsUINotificationsToastTemplateType type) noexcept
{
    return g_try_invoke(ImplGetTemplateContent, type).value_or(nullptr);
}
