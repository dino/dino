#include <windows.h>
#include <shlobj.h>

#include "win32.hpp"
#include "converter.hpp"
#include "ginvoke.hpp"

win32_error::win32_error() noexcept
    : win32_error{::GetLastError()}
{}

constexpr auto noncharacter = L'\uFFFF';

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

std::wstring GetEnv(const wchar_t *const variable_name)
{
    const auto bufsize = ::GetEnvironmentVariableW(variable_name, nullptr, 0);
    if (not bufsize)
        throw win32_error{};
    std::wstring buf(bufsize, noncharacter);
    const auto res =
        ::GetEnvironmentVariableW(variable_name, buf.data(), bufsize);
    if (const auto e = ::GetLastError())
        throw win32_error{e};
    if (not res or res >= bufsize) // not entirely sure this isn't just paranoia
        throw std::runtime_error{"GetEnvironmentVariableW misbehaved"};
    buf.resize(res);
    return buf;
}

static bool ImplSetProcessAumid(const std::string_view aumid)
{
    const auto waumid = sview_to_wstr(aumid);
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

    gboolean SetProcessAumid(const gchar *const aumid) noexcept
    {
        return g_try_invoke(ImplSetProcessAumid, aumid);
    }
}
