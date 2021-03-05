#pragma once

#include <glib.h>

#ifdef __cplusplus

#include <string>
#include <array>
#include <optional>
#include <memory>

std::optional<std::wstring> GetCurrentModulePath();
std::optional<std::wstring> GetShortcutPath();

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
