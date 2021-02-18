#pragma once

#include <glib.h>

#ifdef __cplusplus

#include <string>
#include <array>
#include <optional>
#include <memory>

std::optional<std::wstring> GetCurrentModulePath();
std::optional<std::wstring> GetShortcutPath();

#endif

#ifdef __cplusplus
extern "C"
{
#endif
    gboolean SupportsModernNotifications();
    gboolean SetAppModelID(const gchar* aumid);
#ifdef __cplusplus
}
#endif
