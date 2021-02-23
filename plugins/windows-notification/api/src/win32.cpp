#include <windows.h>
#include <shlobj.h>

#include "win32.hpp"
#include "converter.hpp"

std::optional<std::wstring> GetCurrentModulePath()
{
    std::wstring exePath(MAX_PATH, 0);
    auto charWritten = GetModuleFileName(nullptr, exePath.data(), exePath.size());
    if (charWritten > 0)
    {
        exePath.resize(charWritten);
        return exePath;
    }
    return std::nullopt;
}

std::optional<std::wstring> GetShortcutPath()
{
    std::wstring shortcutPath(MAX_PATH, 0);
    auto charWritten = GetEnvironmentVariable(L"APPDATA", shortcutPath.data(), shortcutPath.size());
    if (charWritten > 0)
    {
        shortcutPath.resize(charWritten);
        return shortcutPath;
    }
    return std::nullopt;
}

bool SetAppModelIDInternal(const std::wstring& aumid)
{
    return SUCCEEDED(SetCurrentProcessExplicitAppUserModelID(aumid.c_str()));
}

extern "C"
{
    // Not available in mingw headers, but linking works.
    NTSTATUS NTAPI RtlGetVersion(PRTL_OSVERSIONINFOW);

    gboolean SupportsModernNotifications()
    {
        RTL_OSVERSIONINFOW rovi = { 0 };
        rovi.dwOSVersionInfoSize = sizeof(rovi);
        if (S_OK == RtlGetVersion(&rovi))
        {
            return rovi.dwMajorVersion > 6;
        }
        return FALSE;
    }

    gboolean SetAppModelID(const gchar* aumid)
    {
        auto result = sview_to_wstr(aumid);
        if (result.empty())
        {
            return FALSE;
        }
        return SetAppModelIDInternal(result);
    }
}

