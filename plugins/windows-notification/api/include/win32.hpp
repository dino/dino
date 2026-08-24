#pragma once

#include <glib.h>

#ifdef __cplusplus
#include <string>
#include <cstdint>
#include <exception>
#include <iterator>

#include "make_array.hpp"
#include "hexify.hpp"

struct win32_error : std::exception
{
    std::uint32_t code;
    explicit win32_error() noexcept;  // initializes with GetLastError()
    explicit win32_error(const std::uint32_t code) noexcept
        : code{code}
    {}
    const char *what() const noexcept override
    {
        // NOTE: thread-unsafe
        // TODO: decimal representation seems to be more usual for win32 errors
        msg = make_array("win32 error 0x01234567\0");
        hexify32(code, std::end(msg)-1);
        return std::data(msg);
    }
private:
    mutable std::array<char,22+1> msg;
};

std::wstring GetExePath();
std::wstring GetEnv(const wchar_t *variable_name);

#define EXTERN    extern "C"
#define NOEXCEPT  noexcept
#else
#define EXTERN
#define NOEXCEPT
#endif

EXTERN gboolean IsWindows10() NOEXCEPT;
EXTERN gboolean SetProcessAumid(const gchar* aumid) NOEXCEPT;

#undef EXTERN
#undef NOEXCEPT
