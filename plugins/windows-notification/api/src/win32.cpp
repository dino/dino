#include <windows.h>
#include <shlobj.h>

#include "win32.hpp"
#include "converter.hpp"
#include "ginvoke.hpp"

win32_error::win32_error() noexcept
    : win32_error{::GetLastError()}
{}

std::wstring GetExePath()
{
    std::wstring exePath(MAX_PATH, 0);
    auto charWritten = GetModuleFileName(nullptr, exePath.data(), exePath.size());
    if (charWritten > 0)
    {
        exePath.resize(charWritten);
        return exePath;
    }
    throw win32_error{};
}

std::wstring GetShortcutPath()
{
    std::wstring shortcutPath(MAX_PATH, 0);
    auto charWritten = GetEnvironmentVariable(L"APPDATA", shortcutPath.data(), shortcutPath.size());
    if (charWritten > 0)
    {
        shortcutPath.resize(charWritten);
        return shortcutPath;
    }
    throw win32_error{};
}

bool ImplSetProcessAumid(const char *const aumid)
{
    auto waumid = sview_to_wstr(aumid);
    if (waumid.empty())
    {
        return false;
    }
    return SUCCEEDED(SetCurrentProcessExplicitAppUserModelID(waumid.c_str()));
}

extern "C"
{
    // Not available in mingw headers, but linking works.
    NTSTATUS NTAPI RtlGetVersion(PRTL_OSVERSIONINFOW);

    gboolean IsWindows10() noexcept
    {
        RTL_OSVERSIONINFOW rovi = { 0 };
        rovi.dwOSVersionInfoSize = sizeof(rovi);
        if (S_OK == RtlGetVersion(&rovi))
        {
            return rovi.dwMajorVersion > 6;
        }
        return FALSE;
    }

    gboolean SetProcessAumid(const gchar* aumid) noexcept
    {
        return g_try_invoke(ImplSetProcessAumid, aumid);
    }
}
