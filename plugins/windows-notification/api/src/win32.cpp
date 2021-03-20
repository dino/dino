#include <windows.h>
#include <shlobj.h>

#include "win32.hpp"
#include "converter.hpp"
#include "ginvoke.hpp"

win32_error::win32_error() noexcept
    : win32_error{::GetLastError()}
{}

constexpr auto noncharacter = L'\uFFFF';

template<DWORD InitialGuess, typename Oracle>
static std::wstring GetStringOfGuessableLength(const Oracle &take_a_guess)
{
    constexpr auto grow = [](const std::size_t s) { return s + s/2; };
    static_assert(
        grow(InitialGuess) != InitialGuess, "imminent infinite loop");

    std::wstring buf(InitialGuess, noncharacter);
    auto maybe_len = take_a_guess(buf.data(), static_cast<DWORD>(buf.size()));

    if (not maybe_len) do
    {
        constexpr auto dw_max = std::size_t{std::numeric_limits<DWORD>::max()};
        if (buf.size() == dw_max)
            throw std::runtime_error{"wat, string too long for DWORD?"};
        buf.resize(std::min(grow(buf.size()), dw_max));
        maybe_len = take_a_guess(buf.data(), static_cast<DWORD>(buf.size()));
    }
    while (not maybe_len);

    buf.resize(*maybe_len);
    return buf;
}

std::wstring GetExePath()
{
    const auto try_get_exe_path = [](
        const auto buf, const auto bufsize) -> std::optional<std::size_t>
    {
        constexpr HMODULE exe_module = nullptr;
        ::SetLastError(0);  // just in case
        const auto res = ::GetModuleFileNameW(exe_module, buf, bufsize);
        if (const auto e = ::GetLastError();
          e == ERROR_INSUFFICIENT_BUFFER or res == bufsize)
            return {};
        else if (not e)
            return res;
        else
            throw win32_error{e};
    };

    return GetStringOfGuessableLength<MAX_PATH+1>(try_get_exe_path);
}

std::wstring GetEnv(const wchar_t *const variable_name)
{
    const auto bufsize = ::GetEnvironmentVariableW(variable_name, nullptr, 0);
    if (not bufsize)
        throw win32_error{};
    std::wstring buf(bufsize, noncharacter);
    ::SetLastError(0);
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
    return SUCCEEDED(::SetCurrentProcessExplicitAppUserModelID(waumid.c_str()));
}

extern "C"
{
    // Not available in mingw headers, but linking works.
    NTSTATUS NTAPI RtlGetVersion(PRTL_OSVERSIONINFOW);

    gboolean IsWindows10() noexcept
    {
        RTL_OSVERSIONINFOW rovi = {};
        rovi.dwOSVersionInfoSize = sizeof(rovi);
        if (S_OK == RtlGetVersion(&rovi))
        {
            return rovi.dwMajorVersion > 6;
        }
        return FALSE;
    }

    gboolean SetProcessAumid(const gchar *const aumid) noexcept
    {
        return g_try_invoke(ImplSetProcessAumid, aumid).value_or(false);
    }
}
